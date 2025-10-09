//
//  FollowUpQuestion.swift
//  MeetMemento
//
//  Model representing a follow-up question to help users dig deeper into their journaling.
//

import Foundation

/// Represents a follow-up question to help users dig deeper into their journaling
public struct FollowUpQuestion: Identifiable, Codable, Equatable, Hashable {
    public let id: UUID
    public let title: String
    public let description: String
    public let category: QuestionCategory
    public let isCompleted: Bool
    public let createdAt: Date
    public let completedAt: Date?
    
    public init(
        id: UUID = UUID(),
        title: String,
        description: String,
        category: QuestionCategory,
        isCompleted: Bool = false,
        createdAt: Date = Date(),
        completedAt: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.category = category
        self.isCompleted = isCompleted
        self.createdAt = createdAt
        self.completedAt = completedAt
    }
}

/// Categories for follow-up questions
public enum QuestionCategory: String, CaseIterable, Codable {
    case reflection = "reflection"
    case gratitude = "gratitude"
    case goal = "goal"
    case emotion = "emotion"
    case relationship = "relationship"
    case growth = "growth"
    
    public var displayName: String {
        switch self {
        case .reflection: return "Reflection"
        case .gratitude: return "Gratitude"
        case .goal: return "Goals"
        case .emotion: return "Emotions"
        case .relationship: return "Relationships"
        case .growth: return "Growth"
        }
    }
    
    public var icon: String {
        switch self {
        case .reflection: return "brain.head.profile"
        case .gratitude: return "heart.fill"
        case .goal: return "target"
        case .emotion: return "face.smiling"
        case .relationship: return "person.2.fill"
        case .growth: return "arrow.up.circle.fill"
        }
    }
    
    public var color: String {
        switch self {
        case .reflection: return "#8A38F5"
        case .gratitude: return "#FF6B6B"
        case .goal: return "#4ECDC4"
        case .emotion: return "#45B7D1"
        case .relationship: return "#96CEB4"
        case .growth: return "#FFEAA7"
        }
    }
}

// MARK: - Sample Data

extension FollowUpQuestion {
    static let sampleQuestions: [FollowUpQuestion] = [
        FollowUpQuestion(
            title: "What am I grateful for today?",
            description: "Take a moment to reflect on the positive aspects of your day.",
            category: .gratitude
        ),
        FollowUpQuestion(
            title: "What emotion am I feeling right now?",
            description: "Check in with your current emotional state and explore why.",
            category: .emotion
        ),
        FollowUpQuestion(
            title: "What did I learn about myself today?",
            description: "Reflect on any insights or self-discoveries from your experiences.",
            category: .reflection
        ),
        FollowUpQuestion(
            title: "How did I grow today?",
            description: "Identify ways you've developed or improved as a person.",
            category: .growth
        ),
        FollowUpQuestion(
            title: "What relationship am I nurturing?",
            description: "Think about the connections that matter most to you right now.",
            category: .relationship
        ),
        FollowUpQuestion(
            title: "What goal am I working towards?",
            description: "Reflect on your progress and what steps you can take next.",
            category: .goal
        )
    ]
}
