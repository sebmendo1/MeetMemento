//
//  Entry.swift
//  MeetMemento
//
//  Model representing a journal entry with title, text, and timestamps.
//

import Foundation

/// Represents a journal entry with title, text, and timestamps.
public struct Entry: Identifiable, Codable, Equatable, Hashable {
    public let id: UUID
    public var userId: UUID? // Maps to user_id in Supabase (nil for local-only entries)
    public var title: String
    public var text: String
    public var createdAt: Date
    public var updatedAt: Date
    
    /// Codable keys for snake_case (Supabase) <-> camelCase (Swift) mapping
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case title
        case text
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    /// Custom decoder to handle missing columns gracefully
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Required fields
        id = try container.decode(UUID.self, forKey: .id)
        userId = try container.decodeIfPresent(UUID.self, forKey: .userId)
        title = try container.decode(String.self, forKey: .title)
        text = try container.decode(String.self, forKey: .text)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
    }
    
    /// Creates a new entry with default values.
    public init(
        id: UUID = UUID(),
        userId: UUID? = nil,
        title: String = "",
        text: String,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.title = title
        self.text = text
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    /// Short excerpt of the entry text for display in cards.
    public var excerpt: String {
        let maxLength = 120
        if text.count > maxLength {
            return String(text.prefix(maxLength)) + "..."
        }
        return text
    }
    
    /// Display title, or "Untitled" if empty.
    public var displayTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? "Untitled"
            : title
    }
}

// MARK: - Sample Data

extension Entry {
    static let sampleEntries: [Entry] = [
        Entry(
            title: "Morning Reflection",
            text: "Started the day with a 5km run. Feeling grateful for the clear weather and my health. Need to remember to drink more water throughout the day.",
            createdAt: Date().addingTimeInterval(-86400), // 1 day ago
            updatedAt: Date().addingTimeInterval(-86400)
        ),
        Entry(
            title: "Project Planning",
            text: "Working on the MeetMemento journal feature. The UI is coming together nicely. Need to focus on database integration next week.",
            createdAt: Date().addingTimeInterval(-3600), // 1 hour ago
            updatedAt: Date().addingTimeInterval(-3600)
        ),
        Entry(
            title: "What was the most challenging part of your day?",
            text: "Today's biggest challenge was managing my time between work and personal projects. I found myself getting distracted easily and not focusing on one task at a time.",
            createdAt: Date().addingTimeInterval(-300), // 5 minutes ago
            updatedAt: Date().addingTimeInterval(-300)
        )
    ]
}
