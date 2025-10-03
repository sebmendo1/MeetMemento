//
//  EntryViewModel.swift
//  MeetMemento
//
//  Manages journal entries and provides CRUD operations.
//

import Foundation
import SwiftUI

/// Manages journal entries and provides CRUD operations.
@MainActor
class EntryViewModel: ObservableObject {
    @Published var entries: [Entry] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    init() {
        // Start with empty state - no mock entries
        // Users will create their own entries
    }
    
    // MARK: - CRUD Operations
    
    /// Creates a new entry and adds it to the list.
    func createEntry(title: String, text: String) {
        let entry = Entry(
            title: title,
            text: text
        )
        entries.insert(entry, at: 0) // Add to beginning (newest first)
        
        // TODO: Save to Supabase
        print("✅ Created entry: \(entry.id)")
        print("   Title: \(title.isEmpty ? "(Untitled)" : title)")
        print("   Text: \(text.prefix(50))...")
    }
    
    /// Updates an existing entry.
    func updateEntry(_ updatedEntry: Entry) {
        guard let index = entries.firstIndex(where: { $0.id == updatedEntry.id }) else {
            errorMessage = "Entry not found"
            return
        }
        
        var entry = updatedEntry
        entry.updatedAt = Date()
        entries[index] = entry
        
        // TODO: Update in Supabase
        print("✅ Updated entry: \(entry.id)")
    }
    
    /// Deletes an entry by ID.
    func deleteEntry(id: UUID) {
        entries.removeAll(where: { $0.id == id })
        
        // TODO: Delete from Supabase
        print("🗑️ Deleted entry: \(id)")
    }
    
    /// Loads entries from storage.
    func loadEntries() async {
        isLoading = true
        
        // TODO: Load from Supabase
        // For now, use mock data
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second delay
        
        isLoading = false
    }
    
    // MARK: - Mock Data (for testing/previews only)
    
    func loadMockEntries() {
        entries = Entry.sampleEntries
    }
}
