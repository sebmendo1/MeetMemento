//
//  DigDeeperView.swift
//  MeetMemento
//
//  "Dig Deeper" tab - AI-generated follow-up questions based on recent entries
//

import SwiftUI

struct DigDeeperView: View {
    @ObservedObject var entryViewModel: EntryViewModel
    @ObservedObject var questionsViewModel: GeneratedQuestionsViewModel
    let currentTab: JournalTopTab
    @State private var hasAttemptedGeneration = false // Prevent infinite generation loops

    let onNavigateToEntry: (EntryRoute) -> Void

    @Environment(\.theme) private var theme
    @Environment(\.typography) private var type
    @Environment(\.scenePhase) private var scenePhase

    init(
        entryViewModel: EntryViewModel,
        questionsViewModel: GeneratedQuestionsViewModel,
        currentTab: JournalTopTab,
        onNavigateToEntry: @escaping (EntryRoute) -> Void
    ) {
        self.entryViewModel = entryViewModel
        self.questionsViewModel = questionsViewModel
        self.currentTab = currentTab
        self.onNavigateToEntry = onNavigateToEntry
    }

    var body: some View {
        Group {
            if entryViewModel.entries.isEmpty {
                // Empty state - no entries yet
                noEntriesState
            } else if questionsViewModel.isLoading && questionsViewModel.currentWeekQuestions.isEmpty {
                // Loading state - fetching or generating questions
                loadingState
            } else if questionsViewModel.currentWeekQuestions.isEmpty {
                // No questions for this week yet - will auto-generate on appear
                noQuestionsYetState
            } else if questionsViewModel.incompleteCount == 0 {
                // All questions completed - waiting for more entries
                allCompletedState
            } else {
                // Show questions (1+ entries, questions exist)
                questionsListView
            }
        }
        .onAppear {
            // AUTO-GENERATION: Generate questions on first visit if conditions are met
            autoGenerateQuestionsIfNeeded()

            // REFRESH LOGIC: Silently refresh questions when view appears
            // This catches completion updates when user returns from creating an entry
            if !questionsViewModel.currentWeekQuestions.isEmpty && !entryViewModel.entries.isEmpty {
                Task {
                    await refreshQuestionsIfNeeded()
                }
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            // Refresh when app returns to foreground (only if on this tab)
            if newPhase == .active && currentTab == .digDeeper && !questionsViewModel.currentWeekQuestions.isEmpty {
                Task {
                    await refreshQuestionsIfNeeded()
                }
            }
        }
    }

    // MARK: - Auto-Generation Logic

    private func autoGenerateQuestionsIfNeeded() {
        // Only auto-generate if:
        // 1. User has 1+ entries
        // 2. No questions exist for this week
        // 3. Not currently loading
        // 4. Haven't already attempted generation in this session
        guard !entryViewModel.entries.isEmpty,
              questionsViewModel.currentWeekQuestions.isEmpty,
              !questionsViewModel.isLoading,
              !questionsViewModel.isRefreshing,
              !hasAttemptedGeneration
        else {
            return
        }

        hasAttemptedGeneration = true

        // Check if this is a first-time user (never answered any follow-ups)
        let isFirstTimeUser = questionsViewModel.totalCompletedCount == 0

        if isFirstTimeUser {
            print("🆕 Auto-generating INITIAL questions from 1 most recent entry (first-time user)")
            Task {
                // Generate questions based on 1 most recent entry
                await questionsViewModel.generateInitialQuestions(recentCount: 1)
            }
        } else {
            print("🔄 Auto-generating weekly questions with 14-day lookback (returning user)")
            Task {
                // Generate questions based on 14-day lookback window
                await questionsViewModel.refreshQuestions()
            }
        }
    }

    // MARK: - Refresh Logic

    /// Silently refresh questions to catch completion updates
    /// This runs when the view appears or returns to foreground
    private func refreshQuestionsIfNeeded() async {
        // Only refresh if not already loading
        guard !questionsViewModel.isLoading, !questionsViewModel.isRefreshing else {
            print("⏸️ Skipping refresh - already loading")
            return
        }

        print("🔄 Refreshing questions to update completion state...")
        await questionsViewModel.fetchQuestions()
        print("✅ Questions refreshed - UI updated")
    }

    // MARK: - State Views

    private var noEntriesState: some View {
        emptyState(
            icon: "lightbulb.fill",
            title: "No entries yet",
            message: "Write your first journal entry to unlock personalized reflection questions."
        )
    }

    private var loadingState: some View {
        VStack(spacing: 12) {
            Spacer()
            ProgressView()
                .tint(theme.primary)
                .scaleEffect(1.2)

            // Different messages for fetching vs generating
            if questionsViewModel.isRefreshing {
                Text("Generating personalized questions...")
                    .font(type.body)
                    .foregroundStyle(theme.mutedForeground)
                Text("Analyzing your recent entries")
                    .font(type.bodySmall)
                    .foregroundStyle(theme.mutedForeground.opacity(0.7))
            } else {
                Text("Loading questions...")
                    .font(type.body)
                    .foregroundStyle(theme.mutedForeground)
            }

            Spacer()
        }
    }

    private var noQuestionsYetState: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "sparkles")
                .font(.system(size: 48))
                .headerGradient()

            Text("Generating questions...")
                .font(type.h3)
                .fontWeight(.semibold)
                .headerGradient()

            Text("We're analyzing your journal entries to create personalized reflection questions.")
                .font(type.body)
                .foregroundStyle(theme.mutedForeground)
                .multilineTextAlignment(.center)

            Spacer()
        }
        .padding(.horizontal, 32)
    }

    private var allCompletedState: some View {
        VStack(spacing: 20) {
            Spacer()

            // Celebration icon with completion badge
            ZStack(alignment: .topTrailing) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 56))
                    .headerGradient()

                // Completion count badge
                Text("\(questionsViewModel.currentWeekQuestions.count)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 28, height: 28)
                    .background(
                        Circle()
                            .fill(theme.primary)
                    )
                    .offset(x: 4, y: -4)
            }
            .padding(.bottom, 8)

            Text("All caught up!")
                .font(type.h3)
                .fontWeight(.semibold)
                .headerGradient()

            // Completion counter
            Text("\(questionsViewModel.completedCount)/\(questionsViewModel.currentWeekQuestions.count) questions completed")
                .font(type.bodyBold)
                .foregroundStyle(theme.primary)
                .padding(.bottom, 4)

            VStack(spacing: 8) {
                Text("You've answered all your reflection questions.")
                    .font(type.body)
                    .foregroundStyle(theme.mutedForeground)

                Text("Keep journaling to unlock new personalized questions.")
                    .font(type.body)
                    .foregroundStyle(theme.mutedForeground)
            }
            .multilineTextAlignment(.center)

            Spacer()
        }
        .padding(.horizontal, 32)
    }

    private var questionsListView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Header with progress
                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .center) {
                        Text("Reflection Questions")
                            .font(type.h3)
                            .headerGradient()

                        Spacer()

                        // Enhanced counter with badge style
                        HStack(spacing: 6) {
                            Image(systemName: questionsViewModel.incompleteCount > 0 ? "circle.dashed" : "checkmark.circle.fill")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(questionsViewModel.incompleteCount > 0 ? theme.mutedForeground : theme.primary)

                            Text("\(questionsViewModel.completedCount)/\(questionsViewModel.currentWeekQuestions.count)")
                                .font(type.bodyBold)
                                .foregroundStyle(questionsViewModel.incompleteCount > 0 ? theme.mutedForeground : theme.primary)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(questionsViewModel.incompleteCount > 0 ? theme.secondary : theme.accent.opacity(0.15))
                        )
                    }

                    Text("Explore these questions based on your recent journal entries.")
                        .font(type.body)
                        .foregroundStyle(theme.mutedForeground)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.top, 28)

                // Question cards
                VStack(spacing: 16) {
                    ForEach(questionsViewModel.currentWeekQuestions, id: \.id) { question in
                        FollowUpCard(
                            question: question.questionText,
                            isCompleted: question.isCompleted
                        ) {
                            onNavigateToEntry(.followUpGenerated(
                                questionText: question.questionText,
                                questionId: question.id
                            ))
                        }
                        .id("\(question.id)-\(question.isCompleted)") // Force update on completion change
                        .animation(.easeInOut(duration: 0.3), value: question.isCompleted)
                    }
                }
                .padding(.horizontal, 16)
            }
        }
        .refreshable {
            await questionsViewModel.fetchQuestions()
        }
    }

    // MARK: - Helper Views

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

#Preview("No Entries") {
    @Previewable @StateObject var entryViewModel = EntryViewModel()
    @Previewable @StateObject var questionsViewModel = GeneratedQuestionsViewModel()

    DigDeeperView(
        entryViewModel: entryViewModel,
        questionsViewModel: questionsViewModel,
        currentTab: .digDeeper,
        onNavigateToEntry: { _ in }
    )
    .onAppear {
        entryViewModel.entries = []
    }
    .useTheme()
    .useTypography()
}

#Preview("Loading Questions") {
    @Previewable @StateObject var entryViewModel = EntryViewModel()
    @Previewable @StateObject var questionsViewModel = GeneratedQuestionsViewModel()

    DigDeeperView(
        entryViewModel: entryViewModel,
        questionsViewModel: questionsViewModel,
        currentTab: .digDeeper,
        onNavigateToEntry: { _ in }
    )
    .onAppear {
        entryViewModel.entries = Array(Entry.sampleEntries.prefix(1))
        questionsViewModel.isLoading = true
    }
    .useTheme()
    .useTypography()
}
