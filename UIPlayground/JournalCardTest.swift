//
//  JournalCardTest.swift
//  UIPlayground
//
//  Minimal test to verify JournalCard loads
//

import SwiftUI

struct JournalCardTest: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text("JournalCard Test")
                    .font(.largeTitle)
                    .padding()
                
                // Simple card
                JournalCard(
                    title: "Test Entry",
                    excerpt: "This is a test to see if the card loads properly.",
                    date: Date()
                )
                .padding()
                
                // Card with pin
                JournalCard(
                    title: "Pinned Entry",
                    excerpt: "This entry is pinned to test the pin functionality.",
                    date: Date(),
                    pinned: true
                )
                .padding()
                
                // Long text card
                JournalCard(
                    title: "Long Entry Title That Should Truncate",
                    excerpt: "This is a longer excerpt to test how the card handles multiple lines of text. It should display nicely with proper line limits and spacing.",
                    date: Date().addingTimeInterval(-86400)
                )
                .padding()
            }
        }
    }
}

#Preview {
    JournalCardTest()
}

