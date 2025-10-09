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
    
    private let supabaseService = SupabaseService.shared
   private var hasLoadedOnce = false
   private var isLoadingInProgress = false // Prevent concurrent load operations
    
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
           print("🔄 Entries already loaded or loading in progress")
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
            print("🔄 Load already in progress, skipping duplicate request")
            return
        }
        
        isLoadingInProgress = true
        isLoading = true
        errorMessage = nil
        
        print("🔄 Starting to load entries from Supabase...")
        
        do {
            // Check authentication first
            let currentUser = try await SupabaseService.shared.getCurrentUser()
            print("✅ User authenticated: \(currentUser?.email ?? "Unknown")")
            
            entries = try await supabaseService.fetchEntries()
            print("✅ Loaded \(entries.count) entries from Supabase")
        } catch {
            // Handle different types of errors appropriately
            let errorDescription = error.localizedDescription.lowercased()
            print("❌ Detailed error: \(error)")
            print("❌ Error type: \(type(of: error))")
            
            // Check for cancellation errors (both string matching and type checking)
            if errorDescription.contains("cancelled") || error is CancellationError {
                // Cancelled errors are usually from duplicate requests - don't show to user
                print("🔄 Load cancelled (likely duplicate request): \(error)")
                errorMessage = nil // Clear any previous error message
            } else if errorDescription.contains("timeout") {
                // Timeout errors - show user-friendly message
                errorMessage = "Request timed out. Please check your connection and try again."
                print("⏰ Load timeout: \(error)")
            } else if errorDescription.contains("unauthorized") || errorDescription.contains("401") {
                // Authentication errors
                errorMessage = "Authentication required. Please sign in again."
                print("🔐 Auth error: \(error)")
            } else if errorDescription.contains("not found") || errorDescription.contains("404") {
                // Table not found or user has no entries
                print("📭 No entries found or table doesn't exist: \(error)")
                entries = [] // Clear entries for fresh start
                errorMessage = nil // Don't show error for empty state
            } else {
                // Other errors - show the actual error
                errorMessage = "Failed to load entries: \(error.localizedDescription)"
                print("❌ Load error: \(error)")
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
            text: text,
            isFollowUp: false
        )
        
        // Add to UI immediately (optimistic update)
        entries.insert(optimisticEntry, at: 0)
        print("✅ Optimistically created entry: \(optimisticEntry.id)")
        
        // Save to Supabase in background
        Task {
            errorMessage = nil
            
            do {
                let savedEntry = try await supabaseService.createEntry(title: title, text: text)
                
                // Replace optimistic entry with real one from server
                if let index = entries.firstIndex(where: { $0.id == optimisticEntry.id }) {
                    entries[index] = savedEntry
                }
                
                print("✅ Saved entry to Supabase: \(savedEntry.id)")
                print("   Title: \(title.isEmpty ? "(Untitled)" : title)")
                print("   Text: \(text.prefix(50))...")
            } catch {
                // Remove optimistic entry on failure
                entries.removeAll(where: { $0.id == optimisticEntry.id })
                errorMessage = "Failed to create entry: \(error.localizedDescription)"
                print("❌ Create error: \(error)")
            }
        }
    }
    
    /// Creates a new follow-up entry and saves it to Supabase with optimistic UI.
    func createFollowUpEntry(title: String, text: String) {
        // Create optimistic entry for instant UI feedback
        let optimisticEntry = Entry(
            title: title.isEmpty ? "Untitled" : title,
            text: text,
            isFollowUp: true
        )
        
        // Add to UI immediately (optimistic update)
        entries.insert(optimisticEntry, at: 0)
        print("✅ Optimistically created follow-up entry: \(optimisticEntry.id)")
        
        // Save to Supabase in background
        Task {
            errorMessage = nil
            
            do {
                let savedEntry = try await supabaseService.createEntry(title: title, text: text)
                
                // Replace optimistic entry with real one from server, preserving follow-up flag
                if let index = entries.firstIndex(where: { $0.id == optimisticEntry.id }) {
                    var followUpEntry = savedEntry
                    followUpEntry.isFollowUp = true
                    entries[index] = followUpEntry
                }
                
                print("✅ Saved follow-up entry to Supabase: \(savedEntry.id)")
                print("   Title: \(title.isEmpty ? "(Untitled)" : title)")
                print("   Text: \(text.prefix(50))...")
            } catch {
                // Remove optimistic entry on failure
                entries.removeAll(where: { $0.id == optimisticEntry.id })
                errorMessage = "Failed to create entry: \(error.localizedDescription)"
                print("❌ Create follow-up error: \(error)")
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
                
                print("✅ Updated entry: \(result.id)")
            } catch {
                errorMessage = "Failed to update entry: \(error.localizedDescription)"
                print("❌ Update error: \(error)")
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
                
                print("🗑️ Deleted entry: \(id)")
            } catch {
                errorMessage = "Failed to delete entry: \(error.localizedDescription)"
                print("❌ Delete error: \(error)")
            }
        }
    }
    
    // MARK: - Mock Data (for testing/previews only)
    
    /// Loads mock entries for testing and previews (doesn't affect Supabase).
    func loadMockEntries() {
        entries = Entry.sampleEntries
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
