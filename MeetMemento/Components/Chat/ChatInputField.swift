//
//  ChatInputField.swift
//  MeetMemento
//
//  Created by Sebastian Mendo on 10/24/25.
//

import SwiftUI

struct ChatInputField: View {
    @Environment(\.theme) private var theme
    @Environment(\.typography) private var typography

    @Binding var text: String
    @FocusState.Binding var isFocused: Bool

    let onSend: () -> Void

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            // Text Input Field Container
            VStack(alignment: .leading, spacing: 0) {
                TextField("Chat with your journal...", text: $text, axis: .vertical)
                    .font(typography.bodySmall)
                    .foregroundStyle(theme.foreground)
                    .focused($isFocused)
                    .lineLimit(1...6)
                Spacer(minLength: 0)
            }
            .frame(height: 68, alignment: .topLeading)
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 16)
            .padding(.trailing, 40) // Extra padding for the button
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: Color(red: 0.2, green: 0.2, blue: 0.2).opacity(0.1), radius: 16, x: 0, y: 8)

            // Send Button - positioned at bottom-right
            Button {
                onSend()
            } label: {
                Image(systemName: "arrow.up")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 40,  height: 40)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [theme.fabGradientStart, theme.fabGradientEnd]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(Circle())
                    .shadow(color: Color(red: 0.08, green: 0.08, blue: 0.08).opacity(0.2), radius: 8, x: 0, y: 8)
            }
            .disabled(text.isEmpty)
            .opacity(text.isEmpty ? 0.5 : 1.0)
            .padding(8) // Padding from the edge of the field
        }
        .frame(maxWidth: .infinity, maxHeight: 100)
    }
}

#Preview {
    @Previewable @State var text: String = ""
    @Previewable @FocusState var isFocused: Bool

    VStack {
        Spacer()

        ChatInputField(
            text: $text,
            isFocused: $isFocused,
            onSend: {
                print("Send tapped: \(text)")
                text = ""
            }
        )
        .padding(.horizontal, 16)
    }
    .useTheme()
    .useTypography()
}
