// SupabaseService+FollowUpQuestions.swift
// Extension for AI-generated follow-up question management

import Foundation
import Supabase

extension SupabaseService {

    // MARK: - Fetch Questions

    /// Fetch current week's AI-generated questions from database
    func fetchCurrentWeekQuestions() async throws -> [GeneratedFollowUpQuestion] {
        guard let client = client else {
            throw SupabaseServiceError.clientNotConfigured
        }

        let weekNumber = getCurrentWeekNumber()
        let year = getCurrentYear()

        let response = try await client
            .from("follow_up_questions")
            .select()
            .eq("user_id", value: try getCurrentUserId())
            .eq("week_number", value: weekNumber)
            .eq("year", value: year)
            .order("relevance_score", ascending: false)
            .execute()

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        return try decoder.decode([GeneratedFollowUpQuestion].self, from: response.data)
    }

    /// Fetch all incomplete questions for the user
    func fetchIncompleteQuestions() async throws -> [GeneratedFollowUpQuestion] {
        guard let client = client else {
            throw SupabaseServiceError.clientNotConfigured
        }

        let response = try await client
            .from("follow_up_questions")
            .select()
            .eq("user_id", value: try getCurrentUserId())
            .eq("is_completed", value: false)
            .order("generated_at", ascending: false)
            .limit(10)
            .execute()

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        return try decoder.decode([GeneratedFollowUpQuestion].self, from: response.data)
    }

    /// Fetch completed question count for first-time user detection
    /// Returns count of completed questions (limited to 1 for efficiency)
    func fetchCompletedQuestionCount() async throws -> Int {
        guard let client = client else {
            throw SupabaseServiceError.clientNotConfigured
        }

        // Only fetch 1 record to check if user has ever completed any question
        // This prevents memory issues from fetching thousands of records
        let response = try await client
            .from("follow_up_questions")
            .select()
            .eq("user_id", value: try getCurrentUserId())
            .eq("is_completed", value: true)
            .limit(1)
            .execute()

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let questions = try decoder.decode([GeneratedFollowUpQuestion].self, from: response.data)

        // If any completed questions exist, return 1 (not first-time user)
        // If none exist, return 0 (first-time user)
        return questions.isEmpty ? 0 : 1
    }

    // MARK: - Generate Questions

    /// Generate new follow-up questions using TF-IDF analysis
    /// - Parameters:
    ///   - lookbackDays: Number of days to analyze (default: 14)
    ///   - saveToDatabase: Whether to save questions to database (default: true)
    ///   - mostRecentEntries: If provided, analyzes only N most recent entries instead of time-based lookback
    /// - Returns: Response with generated questions and metadata
    func generateFollowUpQuestions(
        lookbackDays: Int = 14,
        saveToDatabase: Bool = true,
        mostRecentEntries: Int? = nil
    ) async throws -> GeneratedQuestionsResponse {
        guard let client = client else {
            throw SupabaseServiceError.clientNotConfigured
        }

        // Encode request as JSON
        var requestDict: [String: Any] = [
            "lookbackDays": lookbackDays,
            "saveToDatabase": saveToDatabase
        ]

        // Add mostRecentEntries if provided (for first-time users)
        if let mostRecent = mostRecentEntries {
            requestDict["mostRecentEntries"] = mostRecent
        }

        let requestData = try JSONSerialization.data(withJSONObject: requestDict)

        // Invoke edge function
        let responseData: Data = try await client.functions.invoke(
            "generate-follow-up",
            options: FunctionInvokeOptions(body: requestData)
        )

        // Decode response
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(GeneratedQuestionsResponse.self, from: responseData)
    }

    // MARK: - Update Questions

    /// Mark a follow-up question as completed
    /// - Parameters:
    ///   - questionId: ID of the question to complete
    ///   - entryId: ID of the journal entry that answered the question
    func completeFollowUpQuestion(
        questionId: UUID,
        entryId: UUID
    ) async throws {
        guard let client = client else {
            throw SupabaseServiceError.clientNotConfigured
        }

        struct RPCParams: Encodable {
            let p_question_id: String
            let p_entry_id: String
        }

        let params = RPCParams(
            p_question_id: questionId.uuidString,
            p_entry_id: entryId.uuidString
        )

        let encoder = JSONEncoder()
        let paramsData = try encoder.encode(params)

        _ = try await client.rpc(
            "complete_follow_up_question",
            params: paramsData
        ).execute()
    }

    // MARK: - Helper Functions

    /// Get current ISO week number
    private func getCurrentWeekNumber() -> Int {
        let calendar = Calendar.current
        let weekOfYear = calendar.component(.weekOfYear, from: Date())
        return weekOfYear
    }

    /// Get current year
    private func getCurrentYear() -> Int {
        let calendar = Calendar.current
        return calendar.component(.year, from: Date())
    }

    /// Get current authenticated user ID
    private func getCurrentUserId() throws -> String {
        guard let client = client else {
            throw SupabaseServiceError.clientNotConfigured
        }

        guard let userId = client.auth.currentUser?.id.uuidString else {
            throw NSError(
                domain: "SupabaseService",
                code: 401,
                userInfo: [NSLocalizedDescriptionKey: "User not authenticated"]
            )
        }
        return userId
    }
}
