// GeneratedFollowUpQuestion.swift
// Model for AI-generated follow-up questions from TF-IDF analysis

import Foundation

/// AI-generated follow-up question from journal entry analysis
/// Stored in Supabase follow_up_questions table
struct GeneratedFollowUpQuestion: Codable, Identifiable {
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
