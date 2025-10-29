//
//  ChatBubble.swift
//  MeetMemento
//
//  Created by Sebastian Mendo on 10/24/25.
//

import SwiftUI

struct ChatBubble: View {
    let message: ChatMessage

    var body: some View {
        switch message.sender {
        case .user:
            UserChatBubble(message: message)
        case .assistant:
            AssistantChatBubble(message: message)
        case .system:
            SystemChatBubble(message: message)
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        ChatBubble(message: ChatMessage(
            text: "Hello! How are you feeling today?",
            sender: .assistant,
            timestamp: Date()
        ))

        ChatBubble(message: ChatMessage(
            text: "I'm feeling great, thanks for asking!",
            sender: .user,
            timestamp: Date()
        ))

        ChatBubble(message: ChatMessage(
            text: "Chat session started",
            sender: .system,
            timestamp: Date()
        ))
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color(hex: "#efefef"))
    .useTheme()
    .useTypography()
}
