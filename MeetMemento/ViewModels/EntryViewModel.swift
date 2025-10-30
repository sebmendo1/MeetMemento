//
//  EntryViewModel.swift
//  MeetMemento
//
//  Manages journal entries and provides CRUD operations.
//

import Foundation
import SwiftUI

/// Manages journal entries and provides CRUD operations with Supabase integration.
@MainActor
class EntryViewModel: ObservableObject {
    @Published var entries: [Entry] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    // JSON Export
    @Published var latestExport: EntriesExport?
    @Published var lastExportDate: Date?

    private let supabaseService = SupabaseService.shared
    private let exportService = EntryExportService.shared

   private var hasLoadedOnce = false
   private var isLoadingInProgress = false // Prevent concurrent load operations
   private var exportSequence = 0 // Sequence number to prevent race conditions in export regeneration
    
    // MARK: - Month Grouping
    
    /// Groups entries by month for display
    var entriesByMonth: [MonthGroup] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: entries) { entry in
            calendar.dateInterval(of: .month, for: entry.createdAt)?.start ?? entry.createdAt
        }
        
        return grouped.map { (monthStart, entries) in
            MonthGroup(monthStart: monthStart, entries: entries.sorted { $0.createdAt > $1.createdAt })
        }.sorted { $0.monthStart > $1.monthStart } // Most recent first
    }
   
   init() {
       // Don't load on init - prevents UI freeze
   }
   
   /// Loads entries once when view appears
   func loadEntriesIfNeeded() async {
       guard !hasLoadedOnce && !isLoadingInProgress else {
           #if DEBUG
           print("🔄 Entries already loaded or loading in progress")
           #endif
           return
       }
       hasLoadedOnce = true
       await loadEntries()
   }
   
   /// Force refresh entries (for pull-to-refresh)
   func refreshEntries() async {
       // Reset the hasLoadedOnce flag to allow refresh
       hasLoadedOnce = false
       await loadEntries()
   }
    
    // MARK: - Load Entries
    
    /// Loads all entries from Supabase for the current user.
    func loadEntries() async {
        // Prevent concurrent load operations
        guard !isLoadingInProgress else {
            #if DEBUG
            print("🔄 Load already in progress, skipping duplicate request")
            #endif
            return
        }

        isLoadingInProgress = true
        isLoading = true
        errorMessage = nil

        #if DEBUG
        print("🔄 Starting to load entries from Supabase...")
        #endif

        do {
            // Check authentication first with timeout to prevent hanging (5s - OAuth token exchange can be slow)
            let currentUser = try await withTimeout(seconds: 5) {
                try await SupabaseService.shared.getCurrentUser()
            }
            #if DEBUG
            print("✅ User authenticated: \(currentUser?.email ?? "Unknown")")
            #endif

            // Fetch entries with timeout (10s for network operation - accommodates slow connections)
            entries = try await withTimeout(seconds: 10) {
                try await self.supabaseService.fetchEntries()
            }
            #if DEBUG
            print("✅ Loaded \(entries.count) entries from Supabase")
            #endif

            // Regenerate export after loading entries
            scheduleExportRegeneration()
        } catch {
            // Handle different types of errors appropriately
            let errorDescription = error.localizedDescription.lowercased()
            #if DEBUG
            print("❌ Detailed error: \(error)")
            print("❌ Error type: \(type(of: error))")
            #endif

            // Check for cancellation errors (both string matching and type checking)
            if errorDescription.contains("cancelled") || error is CancellationError {
                // Cancelled errors are usually from duplicate requests - don't show to user
                #if DEBUG
                print("🔄 Load cancelled (likely duplicate request): \(error)")
                #endif
                errorMessage = nil // Clear any previous error message
            } else if errorDescription.contains("timeout") {
                // Timeout errors - show user-friendly message
                errorMessage = "Request timed out. Please check your connection and try again."
                #if DEBUG
                print("⏰ Load timeout: \(error)")
                #endif
            } else if errorDescription.contains("unauthorized") || errorDescription.contains("401") {
                // Authentication errors
                errorMessage = "Authentication required. Please sign in again."
                #if DEBUG
                print("🔐 Auth error: \(error)")
                #endif
            } else if errorDescription.contains("not found") || errorDescription.contains("404") {
                // Table not found or user has no entries
                #if DEBUG
                print("📭 No entries found or table doesn't exist: \(error)")
                #endif
                entries = [] // Clear entries for fresh start
                errorMessage = nil // Don't show error for empty state
            } else {
                // Other errors - show the actual error
                errorMessage = "Failed to load entries: \(error.localizedDescription)"
                #if DEBUG
                print("❌ Load error: \(error)")
                #endif
            }
            // Keep existing local entries on error (graceful degradation)
        }
        
        isLoading = false
        isLoadingInProgress = false
    }
    
    // MARK: - Create Entry
    
    /// Creates a new entry and saves it to Supabase with optimistic UI.
    func createEntry(title: String, text: String) {
        // Create optimistic entry for instant UI feedback
        let optimisticEntry = Entry(
            title: title.isEmpty ? "Untitled" : title,
            text: text
        )
        
        // Add to UI immediately (optimistic update)
        entries.insert(optimisticEntry, at: 0)
        #if DEBUG
        print("✅ Optimistically created entry: \(optimisticEntry.id)")
        #endif

        // Save to Supabase in background
        Task {
            errorMessage = nil

            do {
                let savedEntry = try await supabaseService.createEntry(title: title, text: text)

                // Replace optimistic entry with real one from server
                if let index = entries.firstIndex(where: { $0.id == optimisticEntry.id }) {
                    entries[index] = savedEntry
                }

                #if DEBUG
                print("✅ Saved entry to Supabase: \(savedEntry.id)")
                print("   Title: \(title.isEmpty ? "(Untitled)" : title)")
                print("   Text: \(text.prefix(50))...")
                #endif

                // Regenerate export after creation
                scheduleExportRegeneration()
            } catch {
                // Remove optimistic entry on failure
                entries.removeAll(where: { $0.id == optimisticEntry.id })
                errorMessage = "Failed to create entry: \(error.localizedDescription)"
                #if DEBUG
                print("❌ Create error: \(error)")
                #endif
            }
        }
    }

    // MARK: - Update Entry
    
    /// Updates an existing entry in Supabase.
    func updateEntry(_ updatedEntry: Entry) {
        Task {
            errorMessage = nil

            do {
                let result = try await supabaseService.updateEntry(updatedEntry)

                // Update local array
                if let index = entries.firstIndex(where: { $0.id == result.id }) {
                    entries[index] = result
                }

                #if DEBUG
                print("✅ Updated entry: \(result.id)")
                #endif

                // Regenerate export after update
                scheduleExportRegeneration()
            } catch {
                errorMessage = "Failed to update entry: \(error.localizedDescription)"
                #if DEBUG
                print("❌ Update error: \(error)")
                #endif
            }
        }
    }
    
    // MARK: - Delete Entry
    
    /// Deletes an entry from Supabase.
    func deleteEntry(id: UUID) {
        Task {
            errorMessage = nil

            do {
                try await supabaseService.deleteEntry(id: id)

                // Remove from local array
                entries.removeAll(where: { $0.id == id })

                #if DEBUG
                print("🗑️ Deleted entry: \(id)")
                #endif

                // Regenerate export after deletion
                scheduleExportRegeneration()
            } catch {
                errorMessage = "Failed to delete entry: \(error.localizedDescription)"
                #if DEBUG
                print("❌ Delete error: \(error)")
                #endif
            }
        }
    }

    // MARK: - JSON Export

    /// Schedules export regeneration with debouncing to prevent race conditions
    /// Uses sequence number to prevent cancelled tasks from interfering with new ones
    private func scheduleExportRegeneration() {
        exportSequence += 1
        let currentSequence = exportSequence

        Task {
            // Debounce: wait 500ms before regenerating
            try? await Task.sleep(nanoseconds: 500_000_000)

            // Only proceed if this is still the latest requested export
            guard currentSequence == exportSequence else {
                #if DEBUG
                print("⏭️ Skipping stale export regeneration (sequence \(currentSequence) vs \(exportSequence))")
                #endif
                return
            }

            await regenerateExport()
        }
    }

    /// Regenerates the JSON export from current entries
    /// - Saves to file and updates in-memory cache
    /// - Runs in background without blocking UI
    func regenerateExport() async {
        do {
            // Create export from current entries
            let export = exportService.createExport(from: entries)

            // Save to file (background operation)
            let fileURL = try await exportService.saveToFile(export)

            // Update published properties on main actor
            await MainActor.run {
                self.latestExport = export
                self.lastExportDate = Date()
            }

            #if DEBUG
            print("📦 Export regenerated: \(entries.count) entries")
            print("   Saved to: \(fileURL.lastPathComponent)")
            #endif
        } catch {
            #if DEBUG
            print("⚠️ Failed to regenerate export: \(error.localizedDescription)")
            #endif
            // Don't show error to user - export is background operation
        }
    }

    /// Returns the current export as JSON string for edge functions
    /// - Returns: JSON string of all entries, or nil if no entries
    func getExportJSON() async throws -> String? {
        // Use cached export if available and recent
        if let cached = latestExport,
           let lastExport = lastExportDate,
           Date().timeIntervalSince(lastExport) < 60 { // Cache valid for 60 seconds
            return try exportService.getJSONString(from: cached)
        }

        // Otherwise regenerate
        let export = exportService.createExport(from: entries)

        // Update cache
        await MainActor.run {
            self.latestExport = export
            self.lastExportDate = Date()
        }

        return try exportService.getJSONString(from: export)
    }

    // MARK: - Mock Data (for testing/previews only)

    /// Loads mock entries for testing and previews (doesn't affect Supabase).
    func loadMockEntries() {
        entries = Entry.sampleEntries
    }

    // MARK: - Timeout Helper

    private func withTimeout<T>(
        seconds: TimeInterval,
        operation: @escaping () async throws -> T
    ) async throws -> T {
        try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask {
                try await operation()
            }

            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                throw TimeoutError()
            }

            guard let result = try await group.next() else {
                throw TimeoutError()
            }
            group.cancelAll()
            return result
        }
    }

    private struct TimeoutError: Error {
        var localizedDescription: String {
            "Operation timed out"
        }
    }
}

// MARK: - Month Group Model

/// Represents a group of entries from the same month
struct MonthGroup: Identifiable {
    let id = UUID()
    let monthStart: Date
    let entries: [Entry]
    
    /// Human-readable month label (month only for current year, month + year for past years)
    var monthLabel: String {
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: Date())
        let entryYear = calendar.component(.year, from: monthStart)
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM" // Full month name (e.g., "October")
        
        if entryYear == currentYear {
            return formatter.string(from: monthStart)
        } else {
            formatter.dateFormat = "MMMM yyyy" // Month and year (e.g., "October 2023")
            return formatter.string(from: monthStart)
        }
    }
    
    /// Number of entries in this month group
    var entryCount: Int {
        entries.count
    }
}
