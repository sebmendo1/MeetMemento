//
//  JournalView.swift
//  MeetMemento
//
//  Shows journal entries as vertically stacked cards with delete functionality.
//

import SwiftUI

public struct JournalView: View {
    @State private var topSelection: JournalTopTab = .yourEntries
    @EnvironmentObject var entryViewModel: EntryViewModel
    @State private var selectedEntry: Entry?
    @State private var showDeleteConfirmation: Bool = false
    @State private var entryToDelete: Entry?
    
    let onSettingsTapped: () -> Void
    
    @Environment(\.theme) private var theme
    @Environment(\.typography) private var type
    
    public init(onSettingsTapped: @escaping () -> Void = {}) {
        self.onSettingsTapped = onSettingsTapped
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Custom header with tabs and settings button
            HStack(alignment: .center, spacing: 12) {
                // Top navigation with tabs
                TopNav(variant: .tabs, selection: $topSelection)
                    .useTheme()
                    .useTypography()
                
                Spacer()
                
                // Settings menu button (aligned with tabs)
                Button(action: onSettingsTapped) {
                    Image(systemName: "line.3.horizontal")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(theme.foreground)
                        .frame(width: 32, height: 32)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel("Settings")
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 8)
            
            // Content area - swipeable between tabs
            TabView(selection: $topSelection) {
                yourEntriesContent
                    .tag(JournalTopTab.yourEntries)
                
                followUpsContent
                    .tag(JournalTopTab.followUps)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
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
    
    // MARK: - Tab Content Views
    
    /// "Your Entries" tab - Shows all journal entries
    private var yourEntriesContent: some View {
        Group {
            if entryViewModel.entries.isEmpty {
                emptyState(
                    icon: "book.closed.fill",
                    title: "No journal entries yet",
                    message: "Start writing your first entry to see it here."
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(entryViewModel.entries) { entry in
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
        }
    }
    
    /// "Follow-ups" tab - Placeholder for future follow-up functionality
    private var followUpsContent: some View {
        emptyState(
            icon: "arrow.turn.up.right",
            title: "No follow-ups yet",
            message: "Follow-up reminders will appear here."
        )
    }
    
    // MARK: - Subviews
    
    /// Reusable empty state view
    private func emptyState(icon: String, title: String, message: String) -> some View {
        VStack(spacing: 12) {
            Spacer()
            
            Image(systemName: icon)
                .font(.system(size: 36))
                .foregroundStyle(theme.mutedForeground)
            
            Text(title)
                .font(type.h3)
                .fontWeight(.semibold)
                .foregroundStyle(theme.foreground)
            
            Text(message)
                .font(type.body)
                .foregroundStyle(theme.mutedForeground)
            
            Spacer()
        }
        .multilineTextAlignment(.center)
        .padding(.horizontal, 24)
    }
}

// MARK: - Previews

#Preview("Journal • Empty") {
    struct PreviewWrapper: View {
        @StateObject var viewModel = EntryViewModel()
        
        var body: some View {
            JournalView()
                .environmentObject(viewModel)
                .onAppear {
                    viewModel.entries = [] // Empty state
                }
        }
    }
    return PreviewWrapper()
        .useTheme()
        .useTypography()
}

#Preview("Journal • With Entries") {
    struct PreviewWrapper: View {
        @StateObject var viewModel = EntryViewModel()
        
        var body: some View {
            JournalView()
                .environmentObject(viewModel)
                .onAppear {
                    viewModel.loadMockEntries() // Load sample data for preview only
                }
        }
    }
    return PreviewWrapper()
        .useTheme()
        .useTypography()
}
