//
//  SubscriptionModels.swift
//  MeetMemento
//
//  Data models for subscription and monetization features
//

import Foundation

// MARK: - Subscription Tier

/// Represents the user's subscription tier
enum SubscriptionTier: String, Codable {
    case free = "free"
    case premium = "premium"

    var displayName: String {
        switch self {
        case .free: return "Free"
        case .premium: return "Premium"
        }
    }
}

// MARK: - Subscription Period

/// Product IDs for subscription periods
enum SubscriptionPeriod: String, CaseIterable {
    case monthly = "12345678"
    case annual = "123456789"

    var displayName: String {
        switch self {
        case .monthly: return "Monthly"
        case .annual: return "Annual"
        }
    }

    var displayPrice: String {
        switch self {
        case .monthly: return "$4.99/month"
        case .annual: return "$39.99/year"
        }
    }

    var savingsText: String? {
        switch self {
        case .monthly: return nil
        case .annual: return "Save 33%"
        }
    }

    var monthlyEquivalent: String? {
        switch self {
        case .monthly: return nil
        case .annual: return "$3.33/month"
        }
    }
}

// MARK: - Subscription Status

/// Represents the current subscription status for a user
struct SubscriptionStatus: Codable {
    /// Current subscription tier
    var tier: SubscriptionTier

    /// When the subscription expires (nil for free tier)
    var expirationDate: Date?

    /// Whether the subscription is currently active
    var isActive: Bool {
        guard tier == .premium, let expirationDate = expirationDate else {
            return tier == .premium // If premium but no expiration, treat as active
        }
        return expirationDate > Date()
    }

    /// Whether user can create more entries
    var canCreateEntries: Bool {
        // Premium users can always create entries
        // Free users are checked separately based on entry count
        return tier == .premium && isActive
    }

    /// Number of free entries remaining (only relevant for free tier)
    var freeEntriesRemaining: Int

    /// Product ID if premium (monthly or annual)
    var productId: String?

    /// Original transaction ID for subscription tracking
    var originalTransactionId: String?

    /// Transaction ID for the current subscription period
    var transactionId: String?

    init(
        tier: SubscriptionTier = .free,
        expirationDate: Date? = nil,
        freeEntriesRemaining: Int = 9,
        productId: String? = nil,
        originalTransactionId: String? = nil,
        transactionId: String? = nil
    ) {
        self.tier = tier
        self.expirationDate = expirationDate
        self.freeEntriesRemaining = freeEntriesRemaining
        self.productId = productId
        self.originalTransactionId = originalTransactionId
        self.transactionId = transactionId
    }

    /// Returns a free tier status with specified entries remaining
    static func free(entriesRemaining: Int) -> SubscriptionStatus {
        SubscriptionStatus(
            tier: .free,
            expirationDate: nil,
            freeEntriesRemaining: entriesRemaining
        )
    }

    /// Returns an active premium status
    static func premium(
        expiresAt: Date,
        productId: String,
        originalTransactionId: String,
        transactionId: String
    ) -> SubscriptionStatus {
        SubscriptionStatus(
            tier: .premium,
            expirationDate: expiresAt,
            freeEntriesRemaining: 0, // Not relevant for premium
            productId: productId,
            originalTransactionId: originalTransactionId,
            transactionId: transactionId
        )
    }
}

// MARK: - Purchase State

/// Represents the state of a purchase operation
enum PurchaseState: Equatable {
    case idle
    case purchasing
    case success
    case failed(String)
    case cancelled
    case restored

    var isProcessing: Bool {
        self == .purchasing
    }
}

// MARK: - Subscription Feature

/// Features available in premium subscription
enum SubscriptionFeature: String, CaseIterable {
    case unlimitedJournals = "unlimited_journals"
    case aiChat = "ai_chat"
    case detailedInsights = "detailed_insights"

    var title: String {
        switch self {
        case .unlimitedJournals: return "Create unlimited journals"
        case .aiChat: return "Chat with your AI journal"
        case .detailedInsights: return "Smarter and more detailed insights"
        }
    }
}
