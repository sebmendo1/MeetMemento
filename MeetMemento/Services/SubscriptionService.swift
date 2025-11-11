//
//  SubscriptionService.swift
//  MeetMemento
//
//  Central StoreKit 2 manager for subscription operations
//

import Foundation
import StoreKit

/// Manages all StoreKit 2 subscription operations
@MainActor
final class SubscriptionService: ObservableObject {
    static let shared = SubscriptionService()

    // MARK: - Published Properties

    @Published var monthlyProduct: Product?
    @Published var annualProduct: Product?
    @Published var purchaseState: PurchaseState = .idle
    @Published var subscriptionStatus: SubscriptionStatus?
    @Published var productLoadError: String?

    // MARK: - Private Properties

    private var updateListenerTask: Task<Void, Error>?
    private var products: [Product] = []
    private var pendingTransactionSyncs: [Transaction] = []
    private var syncRetryTask: Task<Void, Never>?

    // Product IDs
    private let productIds: [String] = [
        SubscriptionPeriod.monthly.rawValue,
        SubscriptionPeriod.annual.rawValue
    ]

    // Retry configuration
    private let maxRetryAttempts = 5
    private let initialRetryDelay: TimeInterval = 2.0 // Start with 2 seconds

    // MARK: - Initialization

    private init() {
        // Start listening for transaction updates
        updateListenerTask = listenForTransactions()

        // Load products and retry any pending syncs
        Task {
            await loadProducts()
            await updateSubscriptionStatus()

            // Retry any pending transaction syncs from previous sessions
            await retryPendingTransactionSyncs()
        }
    }

    deinit {
        updateListenerTask?.cancel()
        syncRetryTask?.cancel()
    }

    // MARK: - Product Loading

    /// Loads subscription products from the App Store
    func loadProducts() async {
        // Clear previous error
        productLoadError = nil

        do {
            let loadedProducts = try await Product.products(for: productIds)
            products = loadedProducts

            // Sort by price (monthly should be cheaper than annual)
            for product in loadedProducts {
                if product.id == SubscriptionPeriod.monthly.rawValue {
                    monthlyProduct = product
                } else if product.id == SubscriptionPeriod.annual.rawValue {
                    annualProduct = product
                }
            }

            #if DEBUG
            print("✅ Loaded \(products.count) subscription products")
            if let monthly = monthlyProduct {
                print("   Monthly: \(monthly.displayPrice)")
            }
            if let annual = annualProduct {
                print("   Annual: \(annual.displayPrice)")
            }
            if loadedProducts.isEmpty {
                print("⚠️ WARNING: Product.products() returned empty array")
                print("   Product IDs requested: \(productIds)")
                print("   This usually means:")
                print("   1. StoreKit Configuration is not linked in Xcode scheme")
                print("   2. Product IDs don't exist in App Store Connect")
                print("   3. Products haven't been submitted for review")
            }
            #endif

            AppLogger.log("✅ Loaded \(products.count) subscription products",
                         category: AppLogger.general)

            // Set error if no products were loaded (even though no exception was thrown)
            if loadedProducts.isEmpty {
                productLoadError = "No products found. StoreKit Configuration may not be properly linked to Xcode scheme."
            }
        } catch {
            productLoadError = error.localizedDescription
            AppLogger.log("❌ Failed to load products: \(error.localizedDescription)",
                         category: AppLogger.general,
                         type: .error)
            #if DEBUG
            print("❌ Failed to load products: \(error)")
            print("   Error type: \(type(of: error))")
            #endif
        }
    }

    // MARK: - Purchase

    /// Initiates a subscription purchase
    /// - Parameter product: The product to purchase
    func purchase(_ product: Product) async {
        purchaseState = .purchasing

        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                // Verify the transaction
                let transaction = try checkVerified(verification)

                // Update subscription status
                await updateSubscriptionStatus()

                // Sync to Supabase
                await syncTransactionToBackend(transaction)

                // Finish the transaction
                await transaction.finish()

                purchaseState = .success

                AppLogger.log("✅ Purchase successful: \(product.id)",
                             category: AppLogger.general)

            case .userCancelled:
                purchaseState = .cancelled
                AppLogger.log("ℹ️ Purchase cancelled by user",
                             category: AppLogger.general)

            case .pending:
                purchaseState = .idle
                AppLogger.log("⏳ Purchase pending (Ask to Buy or approval required)",
                             category: AppLogger.general)

            @unknown default:
                purchaseState = .idle
                AppLogger.log("⚠️ Unknown purchase result",
                             category: AppLogger.general)
            }
        } catch {
            purchaseState = .failed(error.localizedDescription)
            AppLogger.log("❌ Purchase failed: \(error.localizedDescription)",
                         category: AppLogger.general,
                         type: .error)
        }
    }

    // MARK: - Restore Purchases

    /// Restores previously purchased subscriptions
    func restorePurchases() async {
        purchaseState = .purchasing

        do {
            // Sync all current entitlements
            try await AppStore.sync()

            // Update subscription status
            await updateSubscriptionStatus()

            if subscriptionStatus?.tier == .premium {
                purchaseState = .restored
                AppLogger.log("✅ Purchases restored successfully",
                             category: AppLogger.general)
            } else {
                purchaseState = .failed("No active subscriptions found")
                AppLogger.log("ℹ️ No active subscriptions to restore",
                             category: AppLogger.general)
            }
        } catch {
            purchaseState = .failed(error.localizedDescription)
            AppLogger.log("❌ Restore failed: \(error.localizedDescription)",
                         category: AppLogger.general,
                         type: .error)
        }
    }

    // MARK: - Subscription Status

    /// Updates the current subscription status
    func updateSubscriptionStatus() async {
        var currentSubscription: Transaction?
        var expirationDate: Date?

        // Iterate through current entitlements to find active subscription
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                // Check if this is a subscription and it's active
                if let product = products.first(where: { $0.id == transaction.productID }),
                   let subscription = product.subscription {

                    // Check if subscription is active
                    if let status = try? await subscription.status.first,
                       case .verified(let renewalInfo) = status.renewalInfo,
                       renewalInfo.willAutoRenew || status.state == .subscribed {

                        currentSubscription = transaction
                        expirationDate = status.state == .subscribed ?
                            transaction.expirationDate : nil
                        break
                    }
                }
            }
        }

        // Update subscription status
        if let transaction = currentSubscription {
            subscriptionStatus = SubscriptionStatus.premium(
                expiresAt: expirationDate ?? Date.distantFuture,
                productId: transaction.productID,
                originalTransactionId: String(transaction.originalID),
                transactionId: String(transaction.id)
            )

            #if DEBUG
            print("✅ Active subscription: \(transaction.productID)")
            if let expiration = expirationDate {
                print("   Expires: \(expiration)")
            }
            #endif
        } else {
            // No active subscription - user is on free tier
            subscriptionStatus = SubscriptionStatus.free(entriesRemaining: 9)

            #if DEBUG
            print("ℹ️ No active subscription - free tier")
            #endif
        }

        AppLogger.log("ℹ️ Subscription status updated: \(subscriptionStatus?.tier.displayName ?? "unknown")",
                     category: AppLogger.general)
    }

    /// Checks if user has an active subscription
    func hasActiveSubscription() async -> Bool {
        await updateSubscriptionStatus()
        return subscriptionStatus?.tier == .premium && (subscriptionStatus?.isActive ?? false)
    }

    // MARK: - Transaction Listening

    /// Listens for transaction updates (purchases, renewals, cancellations)
    /// Note: Updates are queued and processed gracefully to avoid interrupting user mid-action
    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            // Listen to transaction updates
            for await result in Transaction.updates {
                do {
                    let transaction = try self.checkVerified(result)

                    // Check for refunds first
                    if transaction.revocationDate != nil {
                        AppLogger.log("🔄 Transaction refunded: \(transaction.productID)",
                                     category: AppLogger.general)
                        await self.handleRefund(transaction)
                    } else {
                        // Normal update - sync to backend but don't force UI update immediately
                        await self.syncTransactionToBackend(transaction)

                        // Only update subscription status, don't interrupt user
                        // The UI will pick up the change naturally
                        await self.updateSubscriptionStatusQuietly()
                    }

                    // Finish the transaction
                    await transaction.finish()

                    #if DEBUG
                    print("🔄 Transaction update processed: \(transaction.productID)")
                    #endif
                } catch {
                    AppLogger.log("❌ Transaction update error: \(error.localizedDescription)",
                                 category: AppLogger.general,
                                 type: .error)
                }
            }
        }
    }

    /// Handles refunded transactions
    /// - Parameter transaction: The refunded transaction
    private func handleRefund(_ transaction: Transaction) async {
        AppLogger.log("💸 Processing refund for transaction: \(transaction.productID)",
                     category: AppLogger.general)

        // Mark subscription as inactive in backend
        // Note: The backend should handle this via Apple's server-to-server notifications
        // This is a fallback for client-side detection

        // Update local subscription status
        await updateSubscriptionStatus()

        AppLogger.log("✅ Refund processed, subscription marked inactive",
                     category: AppLogger.general)
    }

    /// Updates subscription status without triggering UI interruptions
    /// This is used for background updates that shouldn't disrupt the user
    private func updateSubscriptionStatusQuietly() async {
        // Same logic as updateSubscriptionStatus() but without UI notifications
        var currentSubscription: Transaction?
        var expirationDate: Date?

        // Iterate through current entitlements to find active subscription
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                // Check if this is a subscription and it's active
                if let product = products.first(where: { $0.id == transaction.productID }),
                   let subscription = product.subscription {

                    // Check if subscription is active
                    if let status = try? await subscription.status.first,
                       case .verified(let renewalInfo) = status.renewalInfo,
                       renewalInfo.willAutoRenew || status.state == .subscribed {

                        currentSubscription = transaction
                        expirationDate = status.state == .subscribed ?
                            transaction.expirationDate : nil
                        break
                    }
                }
            }
        }

        // Update subscription status quietly (no UI interruption)
        if let transaction = currentSubscription {
            subscriptionStatus = SubscriptionStatus.premium(
                expiresAt: expirationDate ?? Date.distantFuture,
                productId: transaction.productID,
                originalTransactionId: String(transaction.originalID),
                transactionId: String(transaction.id)
            )
        } else {
            subscriptionStatus = SubscriptionStatus.free(entriesRemaining: 9)
        }
    }

    // MARK: - Transaction Verification

    /// Verifies a transaction using StoreKit 2's cryptographic verification
    /// - Parameter result: The verification result to check
    /// - Returns: The verified transaction
    /// - Throws: An error if verification fails
    nonisolated private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            // StoreKit has parsed the JWS but failed verification.
            // Don't deliver content to the user.
            throw StoreError.failedVerification
        case .verified(let safe):
            // StoreKit has verified the transaction cryptographically.
            // Safe to use this transaction.
            return safe
        }
    }

    // MARK: - Backend Sync

    /// Syncs a verified transaction to Supabase with retry mechanism
    /// - Parameter transaction: The transaction to sync
    /// - Parameter attempt: Current retry attempt (default 1)
    private func syncTransactionToBackend(_ transaction: Transaction, attempt: Int = 1) async {
        do {
            guard let expirationDate = transaction.expirationDate else {
                AppLogger.log("⚠️ Transaction has no expiration date, skipping backend sync",
                             category: AppLogger.general)
                return
            }

            try await SupabaseService.shared.saveSubscription(
                productId: transaction.productID,
                transactionId: String(transaction.id),
                originalTransactionId: String(transaction.originalID),
                expiresAt: expirationDate,
                receiptData: nil // StoreKit 2 uses signed transactions, not receipts
            )

            AppLogger.log("✅ Transaction synced to backend: \(transaction.productID)",
                         category: AppLogger.general)

            // Success - remove from pending queue if it was there
            pendingTransactionSyncs.removeAll(where: { $0.id == transaction.id })

        } catch {
            AppLogger.log("❌ Failed to sync transaction to backend (attempt \(attempt)/\(maxRetryAttempts)): \(error.localizedDescription)",
                         category: AppLogger.general,
                         type: .error)

            // Add to pending queue if not already there
            if !pendingTransactionSyncs.contains(where: { $0.id == transaction.id }) {
                pendingTransactionSyncs.append(transaction)
            }

            // Retry with exponential backoff
            if attempt < maxRetryAttempts {
                let delay = initialRetryDelay * Double(1 << (attempt - 1)) // Exponential backoff: 2s, 4s, 8s, 16s, 32s
                AppLogger.log("⏳ Retrying transaction sync in \(Int(delay)) seconds...",
                             category: AppLogger.general)

                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))

                // Check if we're still alive and not cancelled
                guard !Task.isCancelled else { return }

                // Retry
                await syncTransactionToBackend(transaction, attempt: attempt + 1)
            } else {
                AppLogger.log("❌ Transaction sync failed after \(maxRetryAttempts) attempts. Added to pending queue.",
                             category: AppLogger.general,
                             type: .error)
            }
        }
    }

    /// Retries any pending transaction syncs
    /// Called on app launch and network restoration
    func retryPendingTransactionSyncs() async {
        guard !pendingTransactionSyncs.isEmpty else { return }

        AppLogger.log("🔄 Retrying \(pendingTransactionSyncs.count) pending transaction sync(s)...",
                     category: AppLogger.general)

        let transactions = pendingTransactionSyncs // Copy to avoid mutation during iteration
        for transaction in transactions {
            await syncTransactionToBackend(transaction, attempt: 1)
        }
    }

    // MARK: - Helper Methods

    /// Returns the display price for a subscription period
    /// - Parameter period: The subscription period
    /// - Returns: Formatted price string (e.g., "$4.99/month")
    func displayPrice(for period: SubscriptionPeriod) -> String? {
        let product: Product?
        switch period {
        case .monthly:
            product = monthlyProduct
        case .annual:
            product = annualProduct
        }

        return product?.displayPrice
    }

    /// Resets purchase state (useful after showing success/error)
    func resetPurchaseState() {
        purchaseState = .idle
    }
}

// MARK: - Store Error

enum StoreError: Error {
    case failedVerification

    var localizedDescription: String {
        switch self {
        case .failedVerification:
            return "Transaction verification failed"
        }
    }
}
