//
//  EntriesExport.swift
//  MeetMemento
//
//  Models for exporting journal entries to JSON format
//  Used for feeding database and edge functions
//

import Foundation

// MARK: - Export Metadata

/// Metadata about the export operation
public struct ExportMetadata: Codable, Equatable {
    /// Total number of entries in the export
    public let totalEntries: Int

    /// Date of the most recently updated entry
    public let lastUpdated: Date?

    /// Timestamp when the export was generated
    public let exportedAt: Date

    /// Export format version for future compatibility
    public let version: String

    public init(
        totalEntries: Int,
        lastUpdated: Date?,
        exportedAt: Date = Date(),
        version: String = "1.0"
    ) {
        self.totalEntries = totalEntries
        self.lastUpdated = lastUpdated
        self.exportedAt = exportedAt
        self.version = version
    }

    enum CodingKeys: String, CodingKey {
        case totalEntries = "total_entries"
        case lastUpdated = "last_updated"
        case exportedAt = "exported_at"
        case version
    }
}

// MARK: - Month Group Export

/// A group of entries organized by calendar month
public struct MonthGroupExport: Codable, Equatable {
    /// Human-readable month label (e.g., "January 2024")
    public let monthLabel: String

    /// First day of the month
    public let monthStart: Date

    /// Number of entries in this month
    public let entryCount: Int

    /// All entries for this month, sorted by creation date (newest first)
    public let entries: [Entry]

    public init(
        monthLabel: String,
        monthStart: Date,
        entryCount: Int,
        entries: [Entry]
    ) {
        self.monthLabel = monthLabel
        self.monthStart = monthStart
        self.entryCount = entryCount
        self.entries = entries
    }

    enum CodingKeys: String, CodingKey {
        case monthLabel = "month_label"
        case monthStart = "month_start"
        case entryCount = "entry_count"
        case entries
    }
}

// MARK: - Entries Export

/// Complete export of all journal entries with metadata and grouping
public struct EntriesExport: Codable, Equatable {
    /// Metadata about this export
    public let metadata: ExportMetadata

    /// Entries organized by month (newest months first)
    public let monthGroups: [MonthGroupExport]

    /// All entries in a flat list (newest first) for API consumption
    public let allEntries: [Entry]

    public init(
        metadata: ExportMetadata,
        monthGroups: [MonthGroupExport],
        allEntries: [Entry]
    ) {
        self.metadata = metadata
        self.monthGroups = monthGroups
        self.allEntries = allEntries
    }

    enum CodingKeys: String, CodingKey {
        case metadata
        case monthGroups = "month_groups"
        case allEntries = "all_entries"
    }
}
