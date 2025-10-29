//
//  AssistantChatBubble.swift
//  MeetMemento
//
//  Created by Sebastian Mendo on 10/24/25.
//

import SwiftUI

struct AssistantChatBubble: View {
    @Environment(\.theme) private var theme
    @Environment(\.typography) private var typography

    let message: ChatMessage

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            VStack(alignment: .leading, spacing: 4) {
                MarkdownText(text: message.text)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(theme.card)
                    .clipShape(RoundedRectangle(cornerRadius: theme.radius.lg, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: theme.radius.lg, style: .continuous)
                            .stroke(theme.border, lineWidth: 0)
                    )
            }

            Spacer(minLength: 60)
        }
        .padding(.horizontal, 12)
    }
}

#Preview("Plain Text") {
    VStack(spacing: 16) {
        AssistantChatBubble(message: ChatMessage(
            text: "Hello! How are you feeling today?",
            sender: .assistant,
            timestamp: Date()
        ))

        AssistantChatBubble(message: ChatMessage(
            text: "That's interesting! Tell me more about how you're feeling. I'm here to listen and understand your thoughts better.",
            sender: .assistant,
            timestamp: Date()
        ))
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color(hex: "#efefef"))
    .useTheme()
    .useTypography()
}

#Preview("With Markdown") {
    VStack(spacing: 16) {
        AssistantChatBubble(message: ChatMessage(
            text: """
# How are you feeling today?

I'm here to listen and help you explore your thoughts.

## Things to consider:
What happened today that made you feel this way?

### Remember
It's okay to take your time.
""",
            sender: .assistant,
            timestamp: Date()
        ))

        AssistantChatBubble(message: ChatMessage(
            text: """
## Your emotional patterns

I've noticed some interesting patterns in your entries.

### Recent insights
You tend to feel more positive in the mornings.
""",
            sender: .assistant,
            timestamp: Date()
        ))
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color(hex: "#efefef"))
    .useTheme()
    .useTypography()
}

#Preview("Mixed Content") {
    VStack(spacing: 16) {
        AssistantChatBubble(message: ChatMessage(
            text: """
# Welcome to your journal chat

This is a space where you can freely express your thoughts and feelings.

## How it works
Simply type what's on your mind and I'll help you explore your emotions.
""",
            sender: .assistant,
            timestamp: Date()
        ))
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color(hex: "#efefef"))
    .useTheme()
    .useTypography()
}
