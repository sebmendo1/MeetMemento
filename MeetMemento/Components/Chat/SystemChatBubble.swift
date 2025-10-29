//
//  SystemChatBubble.swift
//  MeetMemento
//
//  Created by Sebastian Mendo on 10/24/25.
//

import SwiftUI

struct SystemChatBubble: View {
    @Environment(\.theme) private var theme
    @Environment(\.typography) private var typography

    let message: ChatMessage

    var body: some View {
        Text(message.text)
            .font(typography.bodySmall.italic())
            .foregroundStyle(theme.foreground.opacity(0.6))
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 0)
            .padding(.vertical, 12)
            .background(Color(hex: "#f5f5f5"))
            .clipShape(RoundedRectangle(cornerRadius: theme.radius.lg, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: theme.radius.lg, style: .continuous)
                    .stroke(theme.border, lineWidth: 0)
            )
            .padding(.horizontal, 16)
    }
}

#Preview {
    VStack(spacing: 16) {
        SystemChatBubble(message: ChatMessage(
            text: "Chat session started",
            sender: .system,
            timestamp: Date()
        ))

        SystemChatBubble(message: ChatMessage(
            text: "Your conversation is being saved automatically",
            sender: .system,
            timestamp: Date()
        ))

        SystemChatBubble(message: ChatMessage(
            text: "Message failed to send. Please try again.",
            sender: .system,
            timestamp: Date()
        ))
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color(hex: "#efefef"))
    .useTheme()
    .useTypography()
}
