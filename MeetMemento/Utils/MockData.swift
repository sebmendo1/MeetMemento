//
//  MockData.swift
//  MeetMemento
//

import Foundation

struct MockData {
    // Add your mock data here for previews and testing
    
    static let sampleEntry = Entry(
        id: UUID(),
        title: "Sample Entry",
        text: "This is a sample journal entry for testing and previews.",
        createdAt: Date(),
        updatedAt: Date()
    )
    
    static let sampleInsight = Insight(id: UUID())
    static let sampleUser = User(id: UUID())
}

