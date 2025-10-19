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

    // MARK: - Dependencies

    private let supabaseService: SupabaseService

    // MARK: - Initialization

    init(supabaseService: SupabaseService = .shared) {
        self.supabaseService = supabaseService
    }

    // MARK: - Public Methods

    /// Fetch questions for current week from database
    func fetchQuestions() async {
        print("📥 fetchQuestions() called")
        isLoading = true
        error = nil

        do {
            // Add timeout to prevent hanging (2s for simple query)
            let questions = try await withTimeout(seconds: 2) {
                try await self.supabaseService.fetchCurrentWeekQuestions()
            }

            let previousCompletedCount = completedCount
            currentWeekQuestions = questions
            let newCompletedCount = completedCount

            print("   📊 Fetched \(questions.count) questions")
            print("   ✅ Completed: \(newCompletedCount)/\(questions.count)")

            if newCompletedCount != previousCompletedCount {
                print("   🎉 Completion count changed: \(previousCompletedCount) → \(newCompletedCount)")
            }

            // Fetch total completed count (for first-time generation check)
            await fetchTotalCompletedCount()

            // Check if there are new questions this week
            if !questions.isEmpty && !hasSeenCurrentWeek() {
                showNewQuestionsNotification = true
                markWeekAsSeen()
            }
        } catch {
            self.error = "Failed to load questions: \(error.localizedDescription)"
            print("❌ Error fetching questions:", error)
        }

        isLoading = false
        print("✅ fetchQuestions() completed")
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

    /// Manually refresh questions (generates new ones based on recent entries)
    func refreshQuestions() async {
        isRefreshing = true
        error = nil

        do {
            // Generate new questions with 14-day lookback (3s for TF-IDF computation)
            let response = try await withTimeout(seconds: 3) {
                try await self.supabaseService.generateFollowUpQuestions(
                    lookbackDays: 14,
                    saveToDatabase: true
                )
            }

            print("✅ Generated \(response.questions.count) questions")
            print("📊 Analyzed \(response.metadata.entriesAnalyzed) entries")
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
