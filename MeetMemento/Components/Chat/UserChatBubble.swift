//
//  UserChatBubble.swift
//  MeetMemento
//
//  Created by Sebastian Mendo on 10/24/25.
//

import SwiftUI

struct UserChatBubble: View {
    @Environment(\.theme) private var theme
    @Environment(\.typography) private var typography

    let message: ChatMessage

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            Spacer(minLength: 60)

            VStack(alignment: .trailing, spacing: 4) {
                Text(message.text)
                    .font(typography.bodySmall)
                    .foregroundStyle(theme.foreground)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: theme.radius.lg, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: theme.radius.lg, style: .continuous)
                            .stroke(theme.border, lineWidth: 0)
                    )
            }
        }
        .padding(.horizontal, 16)
    }
}

#Preview {
    VStack(spacing: 16) {
        UserChatBubble(message: ChatMessage(
            text: "I'm feeling great, thanks for asking!",
            sender: .user,
            timestamp: Date()
        ))

        UserChatBubble(message: ChatMessage(
            text: "This is a longer message to show how the user chat bubble handles multiple lines of text. It should wrap nicely and maintain proper padding.",
            sender: .user,
            timestamp: Date()
        ))
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color(hex: "#efefef"))
    .useTheme()
    .useTypography()
}
