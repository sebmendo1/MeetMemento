// GeneratedFollowUpQuestion.swift
// Model for AI-generated follow-up questions from TF-IDF analysis

import Foundation

/// AI-generated follow-up question from journal entry analysis
/// Stored in Supabase follow_up_questions table
struct GeneratedFollowUpQuestion: Codable, Identifiable, Equatable, Hashable {
    let id: UUID
    let userId: UUID
    let questionText: String
    let relevanceScore: Double
    let generatedAt: Date
    let weekNumber: Int
    let year: Int
    let isCompleted: Bool
    let completedAt: Date?
    let entryId: UUID?
    let createdAt: Date
    let updatedAt: Date

    // MARK: - Equatable & Hashable

    // Equatable: Two questions are equal if they have the same ID and completion state
    static func == (lhs: GeneratedFollowUpQuestion, rhs: GeneratedFollowUpQuestion) -> Bool {
        lhs.id == rhs.id && lhs.isCompleted == rhs.isCompleted
    }

    // Hashable: Hash based on ID and completion state (critical for SwiftUI change detection)
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(isCompleted)
    }

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case questionText = "question_text"
        case relevanceScore = "relevance_score"
        case generatedAt = "generated_at"
        case weekNumber = "week_number"
        case year
        case isCompleted = "is_completed"
        case completedAt = "completed_at"
        case entryId = "entry_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - Edge Function Response Models

/// Response from generate-follow-up edge function
struct GeneratedQuestionsResponse: Codable {
    let questions: [QuestionWithScore]
    let metadata: QuestionMetadata

    struct QuestionWithScore: Codable {
        let text: String
        let score: Double
    }

    struct QuestionMetadata: Codable {
        let entriesAnalyzed: Int
        let generatedAt: String
        let themesCount: Int
        let lookbackDays: Int
        let savedToDatabase: Bool
    }
}

/// Request body for generating questions
struct GenerateQuestionsRequest: Encodable {
    let lookbackDays: Int
    let saveToDatabase: Bool
}

// MARK: - Preview Helpers

extension GeneratedFollowUpQuestion {
    /// Create a mock question for testing/previews
    static func mockQuestion(
        text: String,
        isCompleted: Bool = false,
        relevanceScore: Double = 0.75
    ) -> GeneratedFollowUpQuestion {
        GeneratedFollowUpQuestion(
            id: UUID(),
            userId: UUID(),
            questionText: text,
            relevanceScore: relevanceScore,
            generatedAt: Date(),
            weekNumber: 42,
            year: 2025,
            isCompleted: isCompleted,
            completedAt: isCompleted ? Date() : nil,
            entryId: isCompleted ? UUID() : nil,
            createdAt: Date(),
            updatedAt: Date()
        )
    }

    /// Mock set of 3 incomplete questions for testing
    static var mockQuestions: [GeneratedFollowUpQuestion] {
        [
            .mockQuestion(text: "What strategies help you manage stress effectively?", relevanceScore: 0.85),
            .mockQuestion(text: "What boundaries do you need to set to protect your energy?", relevanceScore: 0.78),
            .mockQuestion(text: "What can you delegate or let go of to create more space?", relevanceScore: 0.72)
        ]
    }
}
