//
//  ThemeAnalysis.swift
//  MeetMemento
//
//  Models for onboarding theme analysis feature
//

import Foundation

/// Represents a mental health theme identified during onboarding
public struct IdentifiedTheme: Codable, Identifiable, Hashable {
    public let id: UUID
    public let name: String
    public let title: String
    public let summary: String
    public let keywords: [String]
    public let emoji: String
    public let category: String

    // Custom coding keys (id not included because it's generated client-side)
    enum CodingKeys: String, CodingKey {
        case name, title, summary, keywords, emoji, category
    }

    /// Decode theme from API response (generates UUID client-side)
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = UUID()  // Generate client-side since not returned by API
        self.name = try container.decode(String.self, forKey: .name)
        self.title = try container.decode(String.self, forKey: .title)
        self.summary = try container.decode(String.self, forKey: .summary)
        self.keywords = try container.decode([String].self, forKey: .keywords)
        self.emoji = try container.decode(String.self, forKey: .emoji)
        self.category = try container.decode(String.self, forKey: .category)
    }

    /// Encode theme (exclude id from JSON)
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(title, forKey: .title)
        try container.encode(summary, forKey: .summary)
        try container.encode(keywords, forKey: .keywords)
        try container.encode(emoji, forKey: .emoji)
        try container.encode(category, forKey: .category)
    }

    /// Manual initializer for testing
    public init(
        id: UUID = UUID(),
        name: String,
        title: String,
        summary: String,
        keywords: [String],
        emoji: String,
        category: String
    ) {
        self.id = id
        self.name = name
        self.title = title
        self.summary = summary
        self.keywords = keywords
        self.emoji = emoji
        self.category = category
    }
}

/// Response from theme analysis edge function
/// Matches camelCase format from TypeScript edge function (consistent with generate-follow-up)
public struct ThemeAnalysisResponse: Codable {
    public let themes: [IdentifiedTheme]?  // Made optional for debugging
    public let recommendedCount: Int?       // Made optional for debugging
    public let analyzedAt: String?          // Made optional for debugging
    public let themeCount: Int?             // Made optional for debugging
}

/// Request body for theme analysis
public struct ThemeAnalysisRequest: Codable {
    public let selfReflectionText: String

    public init(selfReflectionText: String) {
        self.selfReflectionText = selfReflectionText
    }
}

/// Errors that can occur during theme analysis
public enum ThemeAnalysisError: LocalizedError {
    case invalidLength
    case insufficientContent
    case rateLimited(retryAfter: String)
    case invalidResponse
    case networkError(Error)
    case serverError

    public var errorDescription: String? {
        switch self {
        case .invalidLength:
            return "Your reflection must be between 20 and 2000 characters"
        case .insufficientContent:
            return "Please write a more detailed reflection"
        case .rateLimited(let retryAfter):
            return "Analysis already completed. Try again in \(retryAfter)"
        case .invalidResponse:
            return "Received invalid response from server"
        case .networkError:
            return "Network connection failed. Please try again"
        case .serverError:
            return "Server error. Please try again later"
        }
    }
}
