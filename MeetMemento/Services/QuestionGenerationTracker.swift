//
//  QuestionGenerationTracker.swift
//  MeetMemento
//
//  Tracks question generation state using timestamps for reliable background generation
//

import Foundation

/// Tracks question generation state using timestamps (persistent, reliable)
class QuestionGenerationTracker {
    static let shared = QuestionGenerationTracker()

    private let lastGenerationKey = "lastQuestionGenerationTimestamp"
    private let lastGenerationStrategyKey = "lastQuestionGenerationStrategy"

    private init() {}

    // MARK: - Public API

    /// Count entries created AFTER last generation
    /// - Parameter entries: All user entries
    /// - Returns: Number of NEW entries since last generation
    func countNewEntriesSinceGeneration(entries: [Entry]) -> Int {
        guard let lastGen = lastGenerationDate else {
            // Never generated before - count all non-follow-up entries
            return entries.filter { !$0.isFollowUp }.count
        }

        // Only count regular entries (not follow-ups) created after last generation
        return entries.filter { entry in
            entry.createdAt > lastGen && !entry.isFollowUp
        }.count
    }

    /// Check if should trigger background generation
    /// - Parameters:
    ///   - entries: All user entries
    ///   - incompleteQuestions: Number of incomplete questions (ignored - for compatibility)
    /// - Returns: True if 2+ new entries exist AND cooldown period passed
    func shouldTriggerGeneration(entries: [Entry], incompleteQuestions: Int) -> Bool {
        // Check cooldown (5 minutes minimum between generations)
        if let lastGen = lastGenerationDate {
            let timeSinceLastGen = Date().timeIntervalSince(lastGen)
            if timeSinceLastGen < 300 { // 5 minutes
                print("⏸️ Cooldown active - last generation \(Int(timeSinceLastGen))s ago")
                return false
            }
        }

        // Check entry threshold (2 new entries triggers generation)
        let newEntriesCount = countNewEntriesSinceGeneration(entries: entries)
        if newEntriesCount >= 2 {
            print("✅ Generation threshold met - \(newEntriesCount) new entries (incomplete questions: \(incompleteQuestions))")
            return true
        }

        print("⏸️ Not enough new entries - need 2, have \(newEntriesCount)")
        return false
    }

    /// Record successful generation (resets tracking)
    func recordSuccessfulGeneration(strategy: String) {
        UserDefaults.standard.set(Date(), forKey: lastGenerationKey)
        UserDefaults.standard.set(strategy, forKey: lastGenerationStrategyKey)

        print("""
        📝 Generation recorded:
           - Timestamp: \(Date())
           - Strategy: \(strategy)
        """)
    }

    /// Get last generation date (for debugging)
    var lastGenerationDate: Date? {
        UserDefaults.standard.object(forKey: lastGenerationKey) as? Date
    }

    /// Get last generation strategy (for debugging)
    var lastGenerationStrategy: String? {
        UserDefaults.standard.string(forKey: lastGenerationStrategyKey)
    }
}
