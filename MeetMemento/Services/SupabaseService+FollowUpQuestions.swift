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

        print("🔍 fetchCurrentWeekQuestions - week \(weekNumber), year \(year)")

        let response = try await client
            .from("follow_up_questions")
            .select()
            .eq("user_id", value: try getCurrentUserId())
            .eq("week_number", value: weekNumber)
            .eq("year", value: year)
            .order("relevance_score", ascending: false)
            .limit(3)  // CRITICAL: Limit to top 3 questions (matches edge function output)
            .execute()

        print("   - Raw response data:", String(data: response.data, encoding: .utf8)?.prefix(500) ?? "(empty)")

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let questions = try decoder.decode([GeneratedFollowUpQuestion].self, from: response.data)

        print("   - Decoded \(questions.count) questions:")
        for (index, q) in questions.enumerated() {
            print("     [\(index)] id: \(q.id), isCompleted: \(q.isCompleted), text: \(q.questionText.prefix(50))...")
        }

        // DEDUPLICATE by question_text (keep first occurrence)
        let uniqueQuestions = questions.reduce(into: [GeneratedFollowUpQuestion]()) { result, question in
            if !result.contains(where: { $0.questionText == question.questionText }) {
                result.append(question)
            }
        }

        if uniqueQuestions.count < questions.count {
            print("   ⚠️ Removed \(questions.count - uniqueQuestions.count) duplicate questions")
            print("   - Total: \(questions.count) → Unique: \(uniqueQuestions.count)")
        }

        return uniqueQuestions
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

        print("🔧 completeFollowUpQuestion called:")
        print("   - questionId: \(questionId.uuidString)")
        print("   - entryId: \(entryId.uuidString)")

        // Create update payload
        struct QuestionCompletionUpdate: Encodable {
            let is_completed: Bool
            let completed_at: String
            let entry_id: String
            let updated_at: String
        }

        let formatter = ISO8601DateFormatter()
        let now = formatter.string(from: Date())

        let updateData = QuestionCompletionUpdate(
            is_completed: true,
            completed_at: now,
            entry_id: entryId.uuidString,
            updated_at: now
        )

        // Use direct UPDATE query instead of RPC to bypass PostgREST schema cache issues
        // This is more reliable and doesn't require RPC function deployment
        let response = try await client
            .from("follow_up_questions")
            .update(updateData)
            .eq("id", value: questionId.uuidString)
            .eq("user_id", value: try getCurrentUserId())
            .execute()

        print("   - UPDATE response status: \(response.response.statusCode)")
        print("   - UPDATE response data:", String(data: response.data, encoding: .utf8) ?? "(empty)")

        // Check for successful status code
        if response.response.statusCode == 200 || response.response.statusCode == 204 {
            print("✅ completeFollowUpQuestion succeeded - question marked complete")
        } else {
            print("⚠️ Unexpected status code: \(response.response.statusCode)")
            throw NSError(
                domain: "SupabaseService",
                code: response.response.statusCode,
                userInfo: [NSLocalizedDescriptionKey: "Failed to update question completion status"]
            )
        }
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
