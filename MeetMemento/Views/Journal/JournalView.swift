//
//  JournalView.swift
//  MeetMemento
//
//  Shows journal entries as vertically stacked cards with delete functionality.
//

import SwiftUI

public struct JournalView: View {
    @State private var topSelection: JournalTopTab = .yourEntries
    @StateObject private var entryViewModel = EntryViewModel()
    @State private var selectedEntry: Entry?
    @State private var showDeleteConfirmation: Bool = false
    @State private var entryToDelete: Entry?
    
    @Environment(\.theme) private var theme
    @Environment(\.typography) private var type
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 0) {
            // Top navigation with tabs
            TopNav(variant: .tabs, selection: $topSelection)
                .useTheme()
                .useTypography()
                .padding(.top, 12)
            
            // Content area
            if entryViewModel.entries.isEmpty {
                emptyState
            } else {
                entriesList
            }
        }
        .background(theme.background.ignoresSafeArea())
        .sheet(item: $selectedEntry) { entry in
            JournalPageView(entry: entry, entryViewModel: entryViewModel)
                .useTheme()
                .useTypography()
        }
        .confirmationDialog(
            "Delete this entry?",
            isPresented: $showDeleteConfirmation,
            presenting: entryToDelete
        ) { entry in
            Button("Delete", role: .destructive) {
                entryViewModel.deleteEntry(id: entry.id)
            }
            Button("Cancel", role: .cancel) { }
        } message: { entry in
            Text("This action cannot be undone.")
        }
    }
    
    // MARK: - Subviews
    
    private var emptyState: some View {
        VStack(spacing: 12) {
            Spacer()
            
            Image(systemName: "book.closed.fill")
                .font(.system(size: 36))
                .foregroundStyle(theme.mutedForeground)
            
            Text("No journal entries yet")
                .font(type.h3)
                .fontWeight(.semibold)
                .foregroundStyle(theme.foreground)
            
            Text("Start writing your first entry to see it here.")
                .font(type.body)
                .foregroundStyle(theme.mutedForeground)
            
            Spacer()
        }
        .multilineTextAlignment(.center)
        .padding(.horizontal, 24)
    }
    
    private var entriesList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(filteredEntries) { entry in
                    JournalCard(
                        title: entry.displayTitle,
                        excerpt: entry.excerpt,
                        date: entry.createdAt,
                        onTap: {
                            selectedEntry = entry
                        },
                        onMoreTapped: {
                            entryToDelete = entry
                            showDeleteConfirmation = true
                        }
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }
    
    private var filteredEntries: [Entry] {
        // TODO: Filter by topSelection (Your Entries vs Follow-ups)
        // For now, return all entries
        entryViewModel.entries
    }
}

// MARK: - Previews

#Preview("Journal • Empty") {
    struct PreviewWrapper: View {
        var body: some View {
            JournalView()
                .onAppear {
                    // Empty state
                }
        }
    }
    return PreviewWrapper()
        .useTheme()
        .useTypography()
}

#Preview("Journal • With Entries") {
    JournalView()
        .useTheme()
        .useTypography()
}
