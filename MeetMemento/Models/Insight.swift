//
//  Insight.swift
//  MeetMemento
//
//  Data models for AI-generated journal insights
//  These models map to the edge function response from generate-journal-insights
//

import Foundation

// ============================================================
// MARK: - Annotation Model
// ============================================================

/// A date annotation representing a significant emotional moment
/// Each annotation has a date and a summary paragraph explaining what happened
public struct InsightAnnotation: Codable, Identifiable {
    public var id: String { date }  // Use date as unique identifier
    /// Date in YYYY-MM-DD format
    /// Example: "2025-01-15"
    public let date: String

    /// 2-3 sentence paragraph explaining what happened emotionally on this date
    /// Example: "This was the presentation that kept replaying in your mind. The performance anxiety peaked here, revealing patterns of self-criticism."
    public let summary: String

    public init(date: String, summary: String) {
        self.date = date
        self.summary = summary
    }

    // Custom decoder for backward compatibility with old "mention" field
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        date = try container.decode(String.self, forKey: .date)

        // Try new "summary" field first, fall back to old "mention" field
        if let summaryValue = try? container.decode(String.self, forKey: .summary) {
            summary = summaryValue
        } else if let mentionValue = try? container.decode(String.self, forKey: .mention) {
            summary = mentionValue
        } else {
            // If neither field exists, use a default empty string to prevent crashes
            print("⚠️ Warning: InsightAnnotation missing both 'summary' and 'mention' fields for date: \(date)")
            summary = ""
        }
    }

    // Custom encoder - always encode as "summary"
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(date, forKey: .date)
        try container.encode(summary, forKey: .summary)
    }

    enum CodingKeys: String, CodingKey {
        case date
        case summary
        case mention  // Keep for backward compatibility in decoding
    }
}

// ============================================================
// MARK: - Main Insights Model
// ============================================================

/// Complete AI-generated insights for a user's journal entries
/// Returned from the generate-journal-insights edge function
struct JournalInsights: Codable {
    /// One-sentence summary of the user's emotional themes (max 140 chars)
    /// Example: "You're navigating work stress amid lingering presentation anxiety..."
    let summary: String

    /// Detailed 150-180 word paragraph describing the user's emotional landscape
    /// References specific entry titles and dates to ground observations
    let description: String

    /// Date annotations extracted from description
    /// Shows timeline of key events mentioned in the insight
    let annotations: [InsightAnnotation]

    /// Array of 4-5 identified themes with explanations and source entries
    /// Each theme includes icon, frequency, and which entries mentioned it
    let themes: [InsightTheme]

    /// Number of journal entries that were analyzed to generate these insights
    let entriesAnalyzed: Int

    /// The entry count milestone this insight represents (3, 6, 9, 12, etc.)
    /// Used to store and retrieve milestone-specific insights
    let entryCountMilestone: Int

    /// Timestamp when these insights were generated
    /// Used to show "Updated X ago" in UI
    let generatedAt: Date

    /// Whether these insights were served from cache (true) or freshly generated (false)
    /// Helps determine if we should show cache indicator in UI
    let fromCache: Bool

    /// Optional: When the cache expires and insights should be regenerated
    /// nil if not from cache
    let cacheExpiresAt: Date?

    // ============================================================
    // MARK: - Coding Keys
    // Maps Swift camelCase to JSON snake_case from edge function
    // ============================================================

    enum CodingKeys: String, CodingKey {
        case summary
        case description
        case annotations
        case themes
        case entriesAnalyzed = "entriesAnalyzed"  // Keep camelCase (edge function uses this)
        case entryCountMilestone = "entry_count_milestone"  // Database uses snake_case
        case generatedAt = "generatedAt"
        case fromCache = "fromCache"
        case cacheExpiresAt = "cacheExpiresAt"
    }

    // ============================================================
    // MARK: - Initializers
    // ============================================================

    /// Regular initializer for creating insights programmatically (e.g., sample data)
    init(
        summary: String,
        description: String,
        annotations: [InsightAnnotation],
        themes: [InsightTheme],
        entriesAnalyzed: Int,
        entryCountMilestone: Int,
        generatedAt: Date,
        fromCache: Bool,
        cacheExpiresAt: Date?
    ) {
        self.summary = summary
        self.description = description
        self.annotations = annotations
        self.themes = themes
        self.entriesAnalyzed = entriesAnalyzed
        self.entryCountMilestone = entryCountMilestone
        self.generatedAt = generatedAt
        self.fromCache = fromCache
        self.cacheExpiresAt = cacheExpiresAt
    }

    /// Custom decoder to handle API responses that don't include entryCountMilestone
    /// (Edge function doesn't know about this field - it's set in the app before database storage)
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        summary = try container.decode(String.self, forKey: .summary)
        description = try container.decode(String.self, forKey: .description)

        // annotations is optional for backward compatibility with cached insights
        // Defaults to empty array if not present
        annotations = try container.decodeIfPresent([InsightAnnotation].self, forKey: .annotations) ?? []

        themes = try container.decode([InsightTheme].self, forKey: .themes)
        entriesAnalyzed = try container.decode(Int.self, forKey: .entriesAnalyzed)

        // entryCountMilestone is optional in API responses (defaults to 0)
        // It will be set properly in the ViewModel before saving to database
        entryCountMilestone = try container.decodeIfPresent(Int.self, forKey: .entryCountMilestone) ?? 0

        generatedAt = try container.decode(Date.self, forKey: .generatedAt)
        fromCache = try container.decode(Bool.self, forKey: .fromCache)
        cacheExpiresAt = try container.decodeIfPresent(Date.self, forKey: .cacheExpiresAt)
    }

    /// Custom encoder to encode all properties including entryCountMilestone
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(summary, forKey: .summary)
        try container.encode(description, forKey: .description)
        try container.encode(annotations, forKey: .annotations)
        try container.encode(themes, forKey: .themes)
        try container.encode(entriesAnalyzed, forKey: .entriesAnalyzed)
        try container.encode(entryCountMilestone, forKey: .entryCountMilestone)
        try container.encode(generatedAt, forKey: .generatedAt)
        try container.encode(fromCache, forKey: .fromCache)
        try container.encodeIfPresent(cacheExpiresAt, forKey: .cacheExpiresAt)
    }
}

// ============================================================
// MARK: - Theme Model
// ============================================================

/// A single identified theme from journal analysis
/// Example: "Work Performance Anxiety" with icon 📊
struct InsightTheme: Codable, Identifiable {
    /// Unique identifier for SwiftUI lists (uses name as ID)
    var id: String { name }

    /// Specific 2-4 word theme name
    /// Example: "Work Performance Anxiety" (not generic "stress")
    let name: String

    /// Single emoji icon representing the theme
    /// Example: "📊" for work, "🌿" for self-care
    let icon: String

    /// One sentence (max 60 words) explaining why this theme matters
    /// Example: "You're holding yourself to high standards at work"
    let explanation: String

    /// How often this theme appeared
    /// Format: "X times this week/month" with actual numbers
    /// Example: "3 times this week"
    let frequency: String

    /// Array of journal entries that mentioned this theme
    /// Links themes back to specific entries by date and title
    let sourceEntries: [ThemeSourceEntry]

    // ============================================================
    // MARK: - Coding Keys
    // ============================================================

    enum CodingKeys: String, CodingKey {
        case name
        case icon
        case explanation
        case frequency
        case sourceEntries = "source_entries"  // Edge function uses snake_case
    }
}

// ============================================================
// MARK: - Theme Source Entry Model
// ============================================================

/// Reference to a specific journal entry that contributed to a theme
/// Used to link insights back to the user's actual writing
struct ThemeSourceEntry: Codable {
    /// Date of the entry in YYYY-MM-DD format
    /// Example: "2025-10-23"
    let date: String

    /// Exact title of the journal entry
    /// Example: "Morning Thoughts" or "Presentation Day"
    let title: String
}

// ============================================================
// MARK: - Sample Data for Previews
// ============================================================

extension JournalInsights {
    /// Sample data for SwiftUI previews and testing
    static let sample = JournalInsights(
        summary: "You're navigating work stress amid lingering presentation anxiety and rediscovering simple joys.",
        description: "Over the past week, you've been processing performance anxiety at work, particularly around presentations where you sometimes freeze despite being well-prepared. You've also been setting healthier boundaries with friends and family, recognizing that asking for support isn't weakness. On the positive side, you're reconnecting with simple pleasures like farmer's market visits and solo hikes that help quiet your mind. These entries show you're learning to balance ambition with self-compassion.",
        annotations: [
            InsightAnnotation(date: "2025-10-03", summary: "This was the presentation that kept replaying in your mind. The performance anxiety peaked here, revealing patterns of self-criticism even when others saw success."),
            InsightAnnotation(date: "2025-09-28", summary: "The farmer's market visit marked a shift toward reconnecting with simple pleasures. This moment of presence contrasted sharply with the work stress dominating other days."),
            InsightAnnotation(date: "2025-10-22", summary: "You finally vocalized your need for support to your manager. This represented a breakthrough in recognizing that asking for help isn't weakness, but wisdom.")
        ],
        themes: [
            InsightTheme(
                name: "Work Performance Anxiety",
                icon: "📊",
                explanation: "You're holding yourself to impossibly high standards and replaying mistakes, even when others see you succeeding.",
                frequency: "3 times this week",
                sourceEntries: [
                    ThemeSourceEntry(date: "2025-10-03", title: "The Presentation I Can't Stop Replaying"),
                    ThemeSourceEntry(date: "2025-10-06", title: "Sleep Struggles Return")
                ]
            ),
            InsightTheme(
                name: "Self-Care Rituals",
                icon: "🌿",
                explanation: "You're returning to movement, nature, and simple pleasures to regain balance and remind yourself that rest matters.",
                frequency: "2 times this week",
                sourceEntries: [
                    ThemeSourceEntry(date: "2025-09-28", title: "Perfect Fall Morning"),
                    ThemeSourceEntry(date: "2025-10-25", title: "Trail Therapy")
                ]
            ),
            InsightTheme(
                name: "Seeking Support",
                icon: "🤝",
                explanation: "You recognized the need for help and voiced it to your manager, learning that asking for support brings real change.",
                frequency: "2 times this month",
                sourceEntries: [
                    ThemeSourceEntry(date: "2025-10-18", title: "Hitting the Wall"),
                    ThemeSourceEntry(date: "2025-10-22", title: "I Finally Asked")
                ]
            ),
            InsightTheme(
                name: "Family Caregiving Stress",
                icon: "👩‍👧",
                explanation: "You felt frustration and tension when urging family members to address their health concerns.",
                frequency: "2 times this month",
                sourceEntries: [
                    ThemeSourceEntry(date: "2025-09-22", title: "The Mom Conversation"),
                    ThemeSourceEntry(date: "2025-10-14", title: "She Heard Me")
                ]
            )
        ],
        entriesAnalyzed: 10,
        entryCountMilestone: 9,  // Sample represents 9-entry milestone
        generatedAt: Date(),
        fromCache: false,
        cacheExpiresAt: nil
    )

    /// Sample with cached data for testing cache indicator UI
    static let sampleCached = JournalInsights(
        summary: "You're navigating work stress amid lingering presentation anxiety.",
        description: "This week has been marked by performance anxiety and boundary-setting with friends and family.",
        annotations: [
            InsightAnnotation(date: "2025-10-23", summary: "The start of the week brought familiar patterns of stress and overwhelm. This day highlighted recurring themes of work-life balance struggles.")
        ],
        themes: [
            InsightTheme(
                name: "Work Stress",
                icon: "💼",
                explanation: "You're processing heavy workload and presentation anxiety.",
                frequency: "5 times this week",
                sourceEntries: [
                    ThemeSourceEntry(date: "2025-10-23", title: "Monday Blues")
                ]
            )
        ],
        entriesAnalyzed: 8,
        entryCountMilestone: 6,  // Sample represents 6-entry milestone
        generatedAt: Date().addingTimeInterval(-7200), // 2 hours ago
        fromCache: true,
        cacheExpiresAt: Date().addingTimeInterval(518400) // Expires in 6 days
    )
}
