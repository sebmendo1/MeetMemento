//
//  JournalView.swift
//  MeetMemento
//
//  Main journal view with tabs for "Your Entries" and "Dig Deeper"
//

import SwiftUI

public struct JournalView: View {
    @State private var topSelection: JournalTopTab = .yourEntries
    @EnvironmentObject var entryViewModel: EntryViewModel
    @StateObject private var questionsViewModel = GeneratedQuestionsViewModel()

    let onSettingsTapped: () -> Void
    let onNavigateToEntry: (EntryRoute) -> Void

    @Environment(\.theme) private var theme

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
                YourEntriesView(
                    entryViewModel: entryViewModel,
                    onNavigateToEntry: onNavigateToEntry
                )
                .tag(JournalTopTab.yourEntries)

                DigDeeperView(
                    entryViewModel: entryViewModel,
                    questionsViewModel: questionsViewModel,
                    currentTab: topSelection,
                    onNavigateToEntry: onNavigateToEntry
                )
                .tag(JournalTopTab.digDeeper)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
        .background(theme.background.ignoresSafeArea())
        .onAppear {
            // Connect EntryViewModel to GeneratedQuestionsViewModel for completion tracking
            entryViewModel.questionsViewModel = questionsViewModel

            // Load entries when JournalView appears (deferred from app launch for better performance)
            Task {
                await entryViewModel.loadEntriesIfNeeded()

                // After entries load, pre-fetch questions if user has any entries
                // (DigDeeperView will auto-generate if none exist)
                if !entryViewModel.entries.isEmpty {
                    await questionsViewModel.fetchQuestions()
                }
            }
        }
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
