//
//  EntryExportService.swift
//  MeetMemento
//
//  Service for exporting journal entries to JSON format
//  Handles creation, storage, and retrieval of entry exports
//

import Foundation

public class EntryExportService {
    public static let shared = EntryExportService()

    private let fileManager = FileManager.default
    private let fileName = "entries_export.json"

    // JSON encoder with pretty printing and date formatting
    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()

    // JSON decoder with date formatting
    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    private init() {}

    // MARK: - Public Methods

    /// Creates an export from an array of entries
    /// - Parameter entries: The entries to export
    /// - Returns: A complete EntriesExport with metadata and groupings
    public func createExport(from entries: [Entry]) -> EntriesExport {
        // Sort entries by creation date (newest first)
        let sortedEntries = entries.sorted { $0.createdAt > $1.createdAt }

        // Find the most recently updated entry
        let lastUpdated = sortedEntries.max(by: { $0.updatedAt < $1.updatedAt })?.updatedAt

        // Create metadata
        let metadata = ExportMetadata(
            totalEntries: sortedEntries.count,
            lastUpdated: lastUpdated,
            exportedAt: Date(),
            version: "1.0"
        )

        // Create month groups
        let monthGroups = createMonthGroups(from: sortedEntries)

        // Create export
        return EntriesExport(
            metadata: metadata,
            monthGroups: monthGroups,
            allEntries: sortedEntries
        )
    }

    /// Saves an export to the Documents directory
    /// - Parameter export: The export to save
    /// - Returns: The URL where the file was saved
    /// - Throws: FileManager or encoding errors
    public func saveToFile(_ export: EntriesExport) async throws -> URL {
        let jsonData = try getJSONData(from: export)
        let fileURL = try getFileURL()

        try jsonData.write(to: fileURL, options: [.atomic])
        return fileURL
    }

    /// Loads an export from the Documents directory
    /// - Returns: The loaded export, or nil if file doesn't exist
    /// - Throws: FileManager or decoding errors
    public func loadFromFile() async throws -> EntriesExport? {
        let fileURL = try getFileURL()

        // Check if file exists
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return nil
        }

        let jsonData = try Data(contentsOf: fileURL)
        return try decoder.decode(EntriesExport.self, from: jsonData)
    }

    /// Converts an export to JSON Data
    /// - Parameter export: The export to convert
    /// - Returns: JSON data
    /// - Throws: Encoding errors
    public func getJSONData(from export: EntriesExport) throws -> Data {
        return try encoder.encode(export)
    }

    /// Converts an export to a JSON String
    /// - Parameter export: The export to convert
    /// - Returns: JSON string
    /// - Throws: Encoding errors
    public func getJSONString(from export: EntriesExport) throws -> String {
        let data = try getJSONData(from: export)
        guard let jsonString = String(data: data, encoding: .utf8) else {
            throw ExportError.stringConversionFailed
        }
        return jsonString
    }

    /// Deletes the export file if it exists
    /// - Throws: FileManager errors
    public func deleteExportFile() async throws {
        let fileURL = try getFileURL()
        if fileManager.fileExists(atPath: fileURL.path) {
            try fileManager.removeItem(at: fileURL)
        }
    }

    // MARK: - Private Helpers

    /// Creates month groups from sorted entries (newest first)
    private func createMonthGroups(from sortedEntries: [Entry]) -> [MonthGroupExport] {
        let calendar = Calendar.current

        // Group entries by month
        let grouped = Dictionary(grouping: sortedEntries) { entry -> Date in
            let components = calendar.dateComponents([.year, .month], from: entry.createdAt)
            return calendar.date(from: components) ?? entry.createdAt
        }

        // Convert to MonthGroupExport and sort by month (newest first)
        let monthGroups = grouped.map { (monthStart, entries) -> MonthGroupExport in
            let monthLabel = formatMonthLabel(monthStart)
            return MonthGroupExport(
                monthLabel: monthLabel,
                monthStart: monthStart,
                entryCount: entries.count,
                entries: entries.sorted { $0.createdAt > $1.createdAt }
            )
        }
        .sorted { $0.monthStart > $1.monthStart }

        return monthGroups
    }

    /// Formats a date into a month label (e.g., "January 2024")
    private func formatMonthLabel(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }

    /// Gets the URL for the export file in Documents directory
    private func getFileURL() throws -> URL {
        guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            throw ExportError.documentsDirectoryNotFound
        }
        return documentsURL.appendingPathComponent(fileName)
    }
}

// MARK: - Export Errors

public enum ExportError: LocalizedError {
    case documentsDirectoryNotFound
    case stringConversionFailed

    public var errorDescription: String? {
        switch self {
        case .documentsDirectoryNotFound:
            return "Could not access Documents directory"
        case .stringConversionFailed:
            return "Failed to convert JSON data to string"
        }
    }
}
