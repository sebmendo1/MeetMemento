//
//  MarkdownText.swift
//  MeetMemento
//
//  Created by Sebastian Mendo on 10/26/25.
//

import SwiftUI

/// SwiftUI component that renders markdown text with headings and paragraphs
struct MarkdownText: View {
    @Environment(\.theme) private var theme
    @Environment(\.typography) private var typography

    let text: String

    private var blocks: [MarkdownBlock] {
        MarkdownParser.parse(text)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(Array(blocks.enumerated()), id: \.offset) { index, block in
                switch block {
                case .heading(let level, let text):
                    headingView(level: level, text: text)
                        .padding(.top, index > 0 ? 4 : 0)

                case .paragraph(let text):
                    paragraphView(text: text)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Component Views

    @ViewBuilder
    private func headingView(level: Int, text: String) -> some View {
        Text(text)
            .font(fontForHeading(level: level))
            .foregroundStyle(theme.foreground)
            .multilineTextAlignment(.leading)
    }

    @ViewBuilder
    private func paragraphView(text: String) -> some View {
        Text(text)
            .font(typography.bodySmall)
            .foregroundStyle(theme.foreground)
            .multilineTextAlignment(.leading)
    }

    // MARK: - Helper Functions

    private func fontForHeading(level: Int) -> Font {
        switch level {
        case 1:
            return typography.h1
        case 2:
            return typography.h2
        case 3:
            return typography.h3
        default:
            return typography.body
        }
    }
}

// MARK: - Previews

#Preview("Simple Markdown") {
    VStack(spacing: 16) {
        MarkdownText(text: """
# Main Topic
This is a description of the main topic.

## Subtopic One
More details about this aspect.

### Detail Level
Even more specific information.
""")
        .padding()
        .background(Color(hex: "#f5f5f5"))
        .cornerRadius(12)
    }
    .padding()
    .useTheme()
    .useTypography()
}

#Preview("Plain Text Fallback") {
    VStack(spacing: 16) {
        MarkdownText(text: "Just a regular message without any markdown formatting. This should render as a simple paragraph.")
            .padding()
            .background(Color(hex: "#f5f5f5"))
            .cornerRadius(12)
    }
    .padding()
    .useTheme()
    .useTypography()
}

#Preview("Mixed Content") {
    VStack(spacing: 16) {
        MarkdownText(text: """
# How are you feeling today?

I'm here to listen and help you explore your thoughts and emotions.

## Things to consider:
What happened today that made you feel this way?

### Remember
It's okay to take your time and express yourself fully.
""")
        .padding()
        .background(Color(hex: "#f5f5f5"))
        .cornerRadius(12)
    }
    .padding()
    .useTheme()
    .useTypography()
}
