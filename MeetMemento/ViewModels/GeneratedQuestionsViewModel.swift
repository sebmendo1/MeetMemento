// GeneratedQuestionsViewModel.swift
// ViewModel for managing AI-generated follow-up questions

import Foundation
import SwiftUI

@MainActor
class GeneratedQuestionsViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var currentWeekQuestions: [GeneratedFollowUpQuestion] = []
    @Published var isLoading = false
    @Published var isRefreshing = false
    @Published var error: String?
    @Published var showNewQuestionsNotification = false
    @Published var totalCompletedCount: Int = 0 // Total completed across all time (for first-time check)
    @Published var hasUnseenQuestions = false // Badge indicator for tab
    @Published var lastCompletionTime: Date? = nil // Tracks when a question was last completed (triggers UI refresh)
    private var isGeneratingInBackground = false // Lock to prevent concurrent generations
    private var fetchTask: Task<Void, Never>? // Track in-flight fetch operations

    // MARK: - Dependencies

    private let supabaseService: SupabaseService

    // MARK: - Initialization

    init(supabaseService: SupabaseService = .shared) {
        self.supabaseService = supabaseService
    }

    // MARK: - Public Methods

    /// Fetch questions for current week from database
    func fetchQuestions() async {
        // Cancel any in-flight fetch to prevent race conditions
        fetchTask?.cancel()

        // Create new task
        fetchTask = Task {
            print("📥 fetchQuestions() called")
            isLoading = true
            defer {
                isLoading = false
                print("🔓 isLoading reset to false")
            }
            error = nil

            do {
                // Fetch without aggressive timeout - let Supabase client handle it
                let questions = try await supabaseService.fetchCurrentWeekQuestions()

                // Check if cancelled before updating state
                guard !Task.isCancelled else {
                    print("   ⚠️ Fetch was cancelled")
                    return
                }

                let previousCompletedCount = completedCount

                // CRITICAL: Force array reassignment to trigger @Published
                await MainActor.run {
                    objectWillChange.send()  // Trigger BEFORE assignment
                    currentWeekQuestions = questions  // Assign new array
                    objectWillChange.send()  // Trigger AFTER assignment
                }

                let newCompletedCount = completedCount

                print("   📊 Fetched \(questions.count) questions")
                print("   ✅ Completed: \(newCompletedCount)/\(questions.count)")

                // Log detailed question states for debugging
                for (index, q) in questions.enumerated() {
                    let status = q.isCompleted ? "✅ DONE" : "⏳ TODO"
                    print("      [\(index + 1)] \(status) - \(q.questionText.prefix(50))...")
                }

                if newCompletedCount != previousCompletedCount {
                    print("   🎉 Completion count changed: \(previousCompletedCount) → \(newCompletedCount)")
                }

                // ADDITIONAL: Force second reassignment after delay to ensure SwiftUI detects change
                Task {
                    try? await Task.sleep(nanoseconds: 100_000_000) // 100ms
                    guard !Task.isCancelled else { return }
                    await MainActor.run {
                        let temp = self.currentWeekQuestions
                        self.currentWeekQuestions = temp
                        self.objectWillChange.send()
                        self.updateCounterDisplay()
                    }
                }

                // Fetch total completed count (non-critical)
                do {
                    await fetchTotalCompletedCount()
                } catch {
                    print("⚠️ Failed to fetch total completed count: \(error.localizedDescription)")
                }

                // Check if there are new questions this week
                if !questions.isEmpty && !hasSeenCurrentWeek() {
                    showNewQuestionsNotification = true
                    markWeekAsSeen()
                }
            } catch {
                guard !Task.isCancelled else {
                    print("   ⚠️ Fetch cancelled during error handling")
                    return
                }
                self.error = "Failed to load questions: \(error.localizedDescription)"
                print("❌ Error fetching questions:", error)
            }

            print("✅ fetchQuestions() completed")
        }

        // Wait for task to complete
        await fetchTask?.value
    }

    /// Fetch total completed question count for first-time user detection
    /// Optimized to only check if user has completed any questions (0 or 1+)
    private func fetchTotalCompletedCount() async {
        do {
            totalCompletedCount = try await supabaseService.fetchCompletedQuestionCount()
            print("📊 Total completed questions: \(totalCompletedCount == 0 ? "0 (first-time user)" : "1+ (returning user)")")
        } catch {
            print("⚠️ Failed to fetch completed count: \(error.localizedDescription)")
            // Don't update totalCompletedCount on error - keep existing value
        }
    }

    /// Manually refresh questions (generates new ones from 3 most recent entries)
    func refreshQuestions() async {
        isRefreshing = true
        error = nil

        do {
            // Generate new questions from 3 most recent entries (3s for TF-IDF computation)
            let response = try await withTimeout(seconds: 3) {
                try await self.supabaseService.generateFollowUpQuestions(
                    lookbackDays: 14, // Provided but edge function prioritizes mostRecentEntries
                    saveToDatabase: true,
                    mostRecentEntries: 3
                )
            }

            print("✅ Generated \(response.questions.count) questions")
            print("📊 Analyzed \(response.metadata.entriesAnalyzed) entries (from 3 most recent)")
            print("🎯 Found \(response.metadata.themesCount) themes")

            // Fetch the newly generated questions from database
            await fetchQuestions()

            // Show success notification
            showNewQuestionsNotification = true

        } catch {
            self.error = "Failed to generate questions: \(error.localizedDescription)"
            print("❌ Error generating questions:", error)
        }

        isRefreshing = false
    }

    /// Generate initial questions for first-time users (based on N most recent entries)
    /// - Parameter recentCount: Number of most recent entries to analyze (default: 1)
    func generateInitialQuestions(recentCount: Int = 1) async {
        isRefreshing = true
        error = nil

        print("🆕 Generating INITIAL questions from \(recentCount) most recent entries")

        do {
            // Generate questions from most recent entries (3s for TF-IDF computation)
            let response = try await withTimeout(seconds: 3) {
                try await self.supabaseService.generateFollowUpQuestions(
                    lookbackDays: 14, // Still provide this, but edge function will prioritize mostRecentEntries
                    saveToDatabase: true,
                    mostRecentEntries: recentCount
                )
            }

            print("✅ Generated \(response.questions.count) INITIAL questions")
            print("📊 Analyzed \(response.metadata.entriesAnalyzed) entries (from \(recentCount) most recent)")
            print("🎯 Found \(response.metadata.themesCount) themes")

            // Fetch the newly generated questions from database
            await fetchQuestions()

            // Show success notification
            showNewQuestionsNotification = true

        } catch {
            self.error = "Failed to generate initial questions: \(error.localizedDescription)"
            print("❌ Error generating initial questions:", error)
        }

        isRefreshing = false
    }

    // MARK: - Background Generation

    /// Silently generate questions in background (no loading spinner)
    /// Triggers: 2+ new entries OR all questions completed
    func generateQuestionsInBackground(entries: [Entry]) async {
        print("🔄 Background generation requested")

        // LOCK: Prevent concurrent background generations
        guard !isGeneratingInBackground else {
            print("⏸️ Generation already in progress - skipping")
            return
        }

        // CHECK: Verify conditions still valid
        guard !isLoading, !isRefreshing else {
            print("⏸️ Already loading - skipping background generation")
            return
        }

        // CHECK: Verify should generate (2+ new entries, cooldown passed)
        guard QuestionGenerationTracker.shared.shouldTriggerGeneration(
            entries: entries,
            incompleteQuestions: incompleteCount
        ) else {
            return
        }

        // LOCK: Set flag
        isGeneratingInBackground = true
        defer { isGeneratingInBackground = false }

        print("""
        🚀 BACKGROUND GENERATION STARTED
           - New entries since last gen: \(QuestionGenerationTracker.shared.countNewEntriesSinceGeneration(entries: entries))
           - Incomplete questions: \(incompleteCount)
           - Last generation: \(QuestionGenerationTracker.shared.lastGenerationDate?.description ?? "Never")
        """)

        do {
            // Determine strategy
            let isFirstTimeUser = totalCompletedCount == 0
            let strategy: String

            if isFirstTimeUser {
                // First-time: Analyze most recent entry
                strategy = "initial-1-entry"
                print("   Strategy: First-time user (1 most recent entry)")

                let response = try await withTimeout(seconds: 3) {
                    try await self.supabaseService.generateFollowUpQuestions(
                        lookbackDays: 14,
                        saveToDatabase: true,
                        mostRecentEntries: 1
                    )
                }

                print("   ✅ Generated \(response.questions.count) questions")

            } else {
                // Returning user: Analyze 3 most recent entries (optimized for background)
                strategy = "background-3-entries"
                print("   Strategy: Returning user (3 most recent entries)")

                let response = try await withTimeout(seconds: 3) {
                    try await self.supabaseService.generateFollowUpQuestions(
                        lookbackDays: 14,
                        saveToDatabase: true,
                        mostRecentEntries: 3  // Use recent entries, not 14-day window
                    )
                }

                print("   ✅ Generated \(response.questions.count) questions")
            }

            // Fetch newly generated questions
            await fetchQuestions()

            // Mark as unseen (show badge on tab)
            hasUnseenQuestions = true

            // Record successful generation (resets tracker)
            QuestionGenerationTracker.shared.recordSuccessfulGeneration(strategy: strategy)

            print("✅ BACKGROUND GENERATION COMPLETE - Questions ready!")

        } catch {
            print("❌ Background generation failed: \(error.localizedDescription)")
            print("   Will retry on next entry (tracker NOT reset)")
            // DON'T reset tracker - allow retry on next trigger
        }
    }

    /// Mark questions as seen (called when user views "Dig Deeper" tab)
    func markQuestionsAsSeen() {
        hasUnseenQuestions = false
    }

    /// Signal that a question was just completed (called from EntryViewModel)
    /// This triggers DigDeeperView to refresh even if already loading
    func signalQuestionCompleted() {
        print("📢 signalQuestionCompleted() - notifying UI to refresh")
        lastCompletionTime = Date()
    }

    /// Force counter display update by triggering @Published properties
    /// Call this after fetchQuestions() to ensure UI updates even if array unchanged
    func updateCounterDisplay() {
        print("🔢 updateCounterDisplay() - forcing counter refresh")
        // Force willChange notification to trigger SwiftUI updates
        objectWillChange.send()

        // Log current state for debugging
        print("   Completed: \(completedCount)/\(currentWeekQuestions.count)")
        print("   Incomplete: \(incompleteCount)")
    }

    /// Mark a question as completed
    func completeQuestion(
        _ question: GeneratedFollowUpQuestion,
        withEntryId entryId: UUID
    ) async {
        do {
            // Complete question with timeout (2s for simple update)
            try await withTimeout(seconds: 2) {
                try await self.supabaseService.completeFollowUpQuestion(
                    questionId: question.id,
                    entryId: entryId
                )
            }

            // Refresh questions to update UI
            await fetchQuestions()

            print("✅ Marked question as completed: \(question.questionText)")

        } catch {
            self.error = "Failed to complete question: \(error.localizedDescription)"
            print("❌ Error completing question:", error)
        }
    }

    /// Dismiss new questions notification
    func dismissNotification() {
        showNewQuestionsNotification = false
    }

    /// Force update question completion state (synchronous, bypasses async RPC)
    /// Use as a failsafe when RPC succeeds but UI doesn't update
    func forceUpdateQuestionState(questionId: UUID, isCompleted: Bool) {
        print("🔧 FORCE UPDATE: \(questionId.uuidString) → isCompleted: \(isCompleted)")

        if let index = currentWeekQuestions.firstIndex(where: { $0.id == questionId }) {
            let original = currentWeekQuestions[index]

            // Create new instance with updated completion state (struct is immutable)
            let updated = GeneratedFollowUpQuestion(
                id: original.id,
                userId: original.userId,
                questionText: original.questionText,
                relevanceScore: original.relevanceScore,
                generatedAt: original.generatedAt,
                weekNumber: original.weekNumber,
                year: original.year,
                isCompleted: isCompleted,
                completedAt: isCompleted ? Date() : nil,
                entryId: original.entryId,
                createdAt: original.createdAt,
                updatedAt: Date()
            )

            // Replace with new instance
            currentWeekQuestions[index] = updated
            objectWillChange.send()

            print("   ✅ Local state updated")
            print("   New completed count: \(completedCount)/\(currentWeekQuestions.count)")
        } else {
            print("   ⚠️ Question not found in currentWeekQuestions")
        }
    }

    // MARK: - Computed Properties

    /// Number of incomplete questions
    var incompleteCount: Int {
        currentWeekQuestions.filter { !$0.isCompleted }.count
    }

    /// Number of completed questions
    var completedCount: Int {
        currentWeekQuestions.filter { $0.isCompleted }.count
    }

    /// Completion percentage (0-100)
    var completionPercentage: Double {
        guard !currentWeekQuestions.isEmpty else { return 0 }
        return Double(completedCount) / Double(currentWeekQuestions.count) * 100
    }

    // MARK: - Private Helpers

    /// Check if user has seen questions for current week
    private func hasSeenCurrentWeek() -> Bool {
        let key = "seenGeneratedQuestions_\(getCurrentYear())_\(getCurrentWeekNumber())"
        return UserDefaults.standard.bool(forKey: key)
    }

    /// Mark current week's questions as seen
    private func markWeekAsSeen() {
        let key = "seenGeneratedQuestions_\(getCurrentYear())_\(getCurrentWeekNumber())"
        UserDefaults.standard.set(true, forKey: key)
    }

    /// Get current ISO week number
    private func getCurrentWeekNumber() -> Int {
        Calendar.current.component(.weekOfYear, from: Date())
    }

    /// Get current year
    private func getCurrentYear() -> Int {
        Calendar.current.component(.year, from: Date())
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

            let result = try await group.next()!
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
