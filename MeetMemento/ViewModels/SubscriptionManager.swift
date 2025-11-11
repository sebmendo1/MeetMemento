//
//  SubscriptionManager.swift
//  MeetMemento
//
//  Business logic for subscription features and paywall triggering
//

import Foundation
import SwiftUI

/// Manages subscription business logic and paywall triggering
@MainActor
final class SubscriptionManager: ObservableObject {
    // MARK: - Published Properties

    @Published var subscriptionStatus: SubscriptionStatus = .free(entriesRemaining: 9)
    @Published var freeEntriesRemaining: Int = 9
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var isCheckingPermission: Bool = false

    // MARK: - Private Properties

    private let subscriptionService = SubscriptionService.shared
    private let supabaseService = SupabaseService.shared
    private var permissionCheckTask: Task<Bool, Never>?

    // MARK: - Initialization

    init() {
        // Check subscription status on initialization
        Task {
            await checkSubscriptionStatus()
        }
    }

    // MARK: - Entry Permission

    /// Checks if user can create a new journal entry
    /// Returns true if:
    /// - User has active premium subscription, OR
    /// - User has created fewer than 10 entries
    ///
    /// This function prevents race conditions by:
    /// - Canceling any in-flight permission checks
    /// - Using a lock to prevent concurrent checks
    /// - Fast-path for premium users (no loading state)
    func canCreateEntry() async -> Bool {
        // Cancel any existing permission check
        permissionCheckTask?.cancel()

        // Fast path for premium users - no need to show loading or make backend calls
        if subscriptionStatus.tier == .premium && subscriptionStatus.isActive {
            AppLogger.log("✅ User has active subscription - can create entry (fast path)",
                         category: AppLogger.general)
            return true
        }

        // Prevent concurrent permission checks
        guard !isCheckingPermission else {
            AppLogger.log("⚠️ Permission check already in progress, blocking concurrent check",
                         category: AppLogger.general)
            return false
        }

        // Create a new task for this permission check
        permissionCheckTask = Task {
            isCheckingPermission = true
            isLoading = true
            defer {
                isCheckingPermission = false
                isLoading = false
            }

            do {
                // Double-check StoreKit for active subscription (might have changed)
                if await subscriptionService.hasActiveSubscription() {
                    AppLogger.log("✅ User has active subscription - can create entry",
                                 category: AppLogger.general)
                    return true
                }

                // If no local subscription, check backend
                // This also checks entry count and grandfathered status
                let canCreate = try await supabaseService.canCreateEntry()

                // Update free entries remaining based on count
                if !canCreate {
                    freeEntriesRemaining = 0
                } else {
                    // Get current entry count to calculate remaining
                    let count = try await supabaseService.getUserEntryCount()
                    freeEntriesRemaining = max(0, 9 - count)
                }

                AppLogger.log("📊 Can create entry: \(canCreate), free remaining: \(freeEntriesRemaining)",
                             category: AppLogger.general)

                return canCreate
            } catch {
                errorMessage = "Failed to check entry permission: \(error.localizedDescription)"
                AppLogger.log("❌ Error checking entry permission: \(error.localizedDescription)",
                             category: AppLogger.general,
                             type: .error)

                // On error, DON'T allow creation (prevent offline paywall bypass)
                // Show error to user and let them retry
                return false
            }
        }

        return await permissionCheckTask!.value
    }

    /// Updates free entries remaining count
    func updateFreeEntriesRemaining() async {
        do {
            let count = try await supabaseService.getUserEntryCount()
            freeEntriesRemaining = max(0, 9 - count)

            AppLogger.log("📊 Free entries remaining: \(freeEntriesRemaining)",
                         category: AppLogger.general)
        } catch {
            AppLogger.log("❌ Failed to update free entries: \(error.localizedDescription)",
                         category: AppLogger.general,
                         type: .error)
        }
    }

    // MARK: - Subscription Status

    /// Checks and updates the current subscription status
    /// Syncs from both StoreKit (local) and Supabase (backend)
    func checkSubscriptionStatus() async {
        isLoading = true
        errorMessage = nil

        do {
            // Check StoreKit for active subscription
            await subscriptionService.updateSubscriptionStatus()

            if let storeKitStatus = subscriptionService.subscriptionStatus,
               storeKitStatus.tier == .premium {
                // User has active subscription
                subscriptionStatus = storeKitStatus
                freeEntriesRemaining = 0 // Not relevant for premium users

                AppLogger.log("✅ Active subscription: \(storeKitStatus.productId ?? "unknown")",
                             category: AppLogger.general)
            } else {
                // No active subscription - check backend and entry count
                let entryCount = try await supabaseService.getUserEntryCount()
                freeEntriesRemaining = max(0, 9 - entryCount)

                subscriptionStatus = .free(entriesRemaining: freeEntriesRemaining)

                AppLogger.log("ℹ️ Free tier: \(entryCount) entries, \(freeEntriesRemaining) remaining",
                             category: AppLogger.general)
            }
        } catch {
            errorMessage = "Failed to check subscription status"
            AppLogger.log("❌ Error checking subscription: \(error.localizedDescription)",
                         category: AppLogger.general,
                         type: .error)

            // Default to free tier on error
            subscriptionStatus = .free(entriesRemaining: 9)
        }

        isLoading = false
    }

    /// Refresh subscription status after purchase or restore
    func refreshAfterPurchase() async {
        // Wait briefly for backend sync
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second

        await checkSubscriptionStatus()
    }

    // MARK: - Paywall Trigger Logic

    /// Determines if paywall should be shown
    /// - Parameter entryCount: Current number of entries (optional, will fetch if not provided)
    /// - Returns: True if paywall should be shown
    func shouldShowPaywall(entryCount: Int? = nil) async -> Bool {
        // Premium users never see paywall
        if subscriptionStatus.tier == .premium && subscriptionStatus.isActive {
            return false
        }

        // Get entry count if not provided
        let count: Int
        if let providedCount = entryCount {
            count = providedCount
        } else {
            do {
                count = try await supabaseService.getUserEntryCount()
            } catch {
                AppLogger.log("❌ Failed to get entry count: \(error.localizedDescription)",
                             category: AppLogger.general,
                             type: .error)
                return false // Don't show paywall on error
            }
        }

        // Show paywall if user has reached 10 entries
        return count >= 10
    }

    /// Determines if user is approaching the free limit (show soft paywall hint)
    /// - Parameter entryCount: Current number of entries
    /// - Returns: True if user has 7+ entries but less than 10
    func isApproachingLimit(entryCount: Int? = nil) async -> Bool {
        // Premium users never see hints
        if subscriptionStatus.tier == .premium && subscriptionStatus.isActive {
            return false
        }

        let count: Int
        if let providedCount = entryCount {
            count = providedCount
        } else {
            do {
                count = try await supabaseService.getUserEntryCount()
            } catch {
                return false
            }
        }

        return count >= 7 && count < 10
    }

    // MARK: - Helper Methods

    /// Returns a user-friendly subscription status message
    var statusMessage: String {
        if subscriptionStatus.tier == .premium {
            if let expirationDate = subscriptionStatus.expirationDate {
                let formatter = DateFormatter()
                formatter.dateStyle = .medium
                return "Premium • Expires \(formatter.string(from: expirationDate))"
            } else {
                return "Premium • Active"
            }
        } else {
            if freeEntriesRemaining > 0 {
                return "Free • \(freeEntriesRemaining) entries remaining"
            } else {
                return "Free • Upgrade to continue"
            }
        }
    }

    /// Returns true if user is on premium tier
    var isPremium: Bool {
        subscriptionStatus.tier == .premium && subscriptionStatus.isActive
    }

    /// Returns true if user is on free tier
    var isFree: Bool {
        !isPremium
    }

    /// Resets error message
    func clearError() {
        errorMessage = nil
    }
}
