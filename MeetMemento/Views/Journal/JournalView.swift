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
    @State private var showDeleteConfirmation: Bool = false
    @State private var entryToDelete: Entry?
    
    let onSettingsTapped: () -> Void
    let onNavigateToEntry: (EntryRoute) -> Void
    
    @Environment(\.theme) private var theme
    @Environment(\.typography) private var type
    
    public init(
        onSettingsTapped: @escaping () -> Void = {},
        onNavigateToEntry: @escaping (EntryRoute) -> Void = { _ in }
    ) {
        self.onSettingsTapped = onSettingsTapped
        self.onNavigateToEntry = onNavigateToEntry
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header with tabs and settings button
            Header(
                variant: .tabs,
                selection: $topSelection,
                onSettingsTapped: onSettingsTapped
            )
            
            // Content area - swipeable between tabs with lazy loading
            TabView(selection: $topSelection) {
                yourEntriesContent
                    .tag(JournalTopTab.yourEntries)
                
                digDeeperContent
                    .tag(JournalTopTab.digDeeper)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .onChange(of: topSelection) { oldValue, newValue in
                print("🔄 JournalView: Tab selection changed from \(oldValue.title) to \(newValue.title)")
                print("   Old value: \(oldValue), New value: \(newValue)")
            }
        }
        .background(theme.background.ignoresSafeArea())
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
    @ViewBuilder
    private var yourEntriesContent: some View {
        if entryViewModel.isLoading && entryViewModel.entries.isEmpty {
            // Loading state (only show spinner if no cached entries)
            VStack(spacing: 12) {
                Spacer()
                ProgressView()
                    .tint(theme.primary)
                    .scaleEffect(1.2)
                Text("Loading your entries...")
                    .font(type.body)
                    .foregroundStyle(theme.mutedForeground)
                Spacer()
            }
        } else if let errorMessage = entryViewModel.errorMessage, entryViewModel.entries.isEmpty {
            // Error state (only show if no cached entries)
            VStack(spacing: 12) {
                Spacer()
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 36))
                    .headerGradient()
                Text("Failed to load entries")
                    .font(type.h3)
                    .fontWeight(.semibold)
                    .headerGradient()
                Text(errorMessage)
                    .font(type.body)
                    .foregroundStyle(theme.mutedForeground)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                Button("Try Again") {
                    Task {
                        await entryViewModel.loadEntries()
                    }
                }
                .padding(.top, 8)
                Spacer()
            }
        } else if entryViewModel.entries.isEmpty {
            // Empty state
            emptyState(
                icon: "book.closed.fill",
                title: "No journal entries yet",
                message: "Start writing your first entry to see it here."
            )

        } else {
            // Content with entries grouped by day
            ScrollView {
                LazyVStack(spacing: 32, pinnedViews: []) {
                    // Show error banner if there's an error (but we have cached entries)
                    if let errorMessage = entryViewModel.errorMessage {
                        HStack(spacing: 12) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .foregroundStyle(theme.destructive)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Sync Error")
                                    .font(type.body)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(theme.foreground)
                                Text(errorMessage)
                                    .font(type.body)
                                    .foregroundStyle(theme.mutedForeground)
                            }
                            Spacer()
                        }
                        .padding(12)
                        .background(theme.destructive.opacity(0.1))
                        .cornerRadius(8)
                    }
                    
                    // Month groups - entries organized by month
                    ForEach(entryViewModel.entriesByMonth) { monthGroup in
                        VStack(alignment: .leading, spacing: 8) {
                            // Month header
                            HStack {
                                Text(monthGroup.monthLabel)
                                    .font(type.h4)
                                    .foregroundStyle(theme.foreground)
                                
                                Spacer()
                                
                                Text("\(monthGroup.entryCount) \(monthGroup.entryCount == 1 ? "entry" : "entries")")
                                    .font(type.body)
                                    .foregroundStyle(theme.mutedForeground)
                            }
                            .padding(.horizontal, 4)
                            
                            // Entries for this month
                            VStack(spacing: 0) {
                                ForEach(monthGroup.entries) { entry in
                                    JournalCard(
                                        title: entry.displayTitle,
                                        excerpt: entry.excerpt,
                                        date: entry.createdAt,
                                        onTap: {
                                            onNavigateToEntry(.edit(entry))
                                        },
                                        onMoreTapped: {
                                            entryToDelete = entry
                                            showDeleteConfirmation = true
                                        }
                                    )
                                    .frame(maxWidth: .infinity) // Stretch to full width
                                    .id(entry.id) // Explicit ID for better diffing
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 28) // 12px existing + 16px additional = 28px total
            }
            .refreshable {
                // Pull-to-refresh - force reload even if already loaded
                await entryViewModel.refreshEntries()
            }
        }
    }
    
    /// "Dig deeper" tab - Follow-up questions to help users reflect
    private var digDeeperContent: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Reflection Questions")
                        .font(type.h3)
                        .headerGradient()
                    
                    Text("Explore these questions to deepen your self-awareness and growth.")
                        .font(type.body)
                        .foregroundStyle(theme.mutedForeground)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.top, 28) // 12px existing + 16px additional = 28px total
                
                // Follow-up question cards
                VStack(spacing: 16) {
                    FollowUpCard(question: "What was the most challenging part of your day?") {
                        print("Tapped: What was the most challenging part of your day?")
                    }
                    
                    FollowUpCard(question: "How did you practice self-care today?") {
                        print("Tapped: How did you practice self-care today?")
                    }
                    
                    FollowUpCard(question: "What are you grateful for right now?") {
                        print("Tapped: What are you grateful for right now?")
                    }
                    
                    FollowUpCard(question: "What is one small step you can take tomorrow towards a goal?") {
                        print("Tapped: What is one small step you can take tomorrow towards a goal?")
                    }
                    
                    FollowUpCard(question: "Describe a moment that brought you joy today.") {
                        print("Tapped: Describe a moment that brought you joy today.")
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }
    
    // MARK: - Subviews
    
    /// Reusable empty state view
    private func emptyState(icon: String, title: String, message: String) -> some View {
        VStack(spacing: 12) {
            Spacer()
            
            Image(systemName: icon)
                .font(.system(size: 36))
                .headerGradient()
            
            Text(title)
                .font(type.h3)
                .fontWeight(.semibold)
                .headerGradient()
            
            Text(message)
                .font(type.body)
                .foregroundStyle(theme.mutedForeground)
            
            Spacer()
        }
        .multilineTextAlignment(.center)
        .padding(.horizontal, 16)
    }
}

// MARK: - Previews

#Preview("Journal • Empty") {
    @Previewable @StateObject var viewModel = EntryViewModel()
    
    JournalView(
        onSettingsTapped: {},
        onNavigateToEntry: { _ in }
    )
    .environmentObject(viewModel)
    .onAppear {
        viewModel.entries = [] // Empty state
    }
    .useTheme()
    .useTypography()
}

#Preview("Journal • With Entries") {
    @Previewable @StateObject var viewModel = EntryViewModel()
    
    JournalView(
        onSettingsTapped: {},
        onNavigateToEntry: { _ in }
    )
    .environmentObject(viewModel)
    .onAppear {
        viewModel.loadMockEntries() // Load sample data for preview only
    }
    .useTheme()
    .useTypography()
}
