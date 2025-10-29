//
//  AIChatView.swift
//  MeetMemento
//
//  Created by Sebastian Mendo on 10/24/25.
//

import SwiftUI

struct AIChatView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) private var theme
    @Environment(\.typography) private var typography

    @State private var messageText: String = ""
    @State private var messages: [ChatMessage] = []
    @FocusState private var isInputFocused: Bool
    @State private var keyboardHeight: CGFloat = 0

    var body: some View {
        ZStack {
            // Background
            theme.background
                .ignoresSafeArea()
                .onTapGesture {
                    isInputFocused = false
                }

            VStack(spacing: 0) {
                // Top Navigation Bar
                navigationBar

                // Main Content Area
                GeometryReader { geometry in
                    ScrollView {
                        if messages.isEmpty {
                            // Empty State - dynamically centered
                            VStack {
                                Spacer()
                                ChatEmptyState()
                                Spacer()
                            }
                            .frame(
                                maxWidth: .infinity,
                                minHeight: calculateEmptyStateHeight(screenHeight: geometry.size.height)
                            )
                        } else {
                            // Chat Messages
                            LazyVStack(spacing: 16) {
                                ForEach(messages) { message in
                                    ChatBubble(message: message)
                                }
                            }
                            .padding(.vertical, 16)
                        }
                    }
                    .onTapGesture {
                        isInputFocused = false
                    }
                }

                // Bottom Chat Input
                ChatInputField(
                    text: $messageText,
                    isFocused: $isInputFocused,
                    onSend: sendMessage
                )
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
            }
        }
        .observeKeyboardHeight($keyboardHeight)
        .animation(.easeOut(duration: 0.25), value: keyboardHeight)
        .navigationBarHidden(true)
    }

    // MARK: - Helper Functions

    /// Calculate the height for EmptyState to be centered in available space
    /// Accounts for keyboard height when present
    private func calculateEmptyStateHeight(screenHeight: CGFloat) -> CGFloat {
        // Navigation bar height: ~68px (44 + padding)
        // Chat input field height: ~70px (varies with padding)
        // Adjust available height based on keyboard presence
        let navBarHeight: CGFloat = 68
        let inputFieldHeight: CGFloat = 70
        let availableHeight = screenHeight - navBarHeight - inputFieldHeight - keyboardHeight

        // Return at least 200 for very small screens
        return max(availableHeight, 200)
    }

    // MARK: - Navigation Bar
    private var navigationBar: some View {
        HStack(spacing: 16) {
            // Back Button
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(theme.foreground)
                    .frame(width: 44, height: 44)
                    .background(theme.card)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
            }

            Spacer()

            // Save as Journal Button
            Button {
                // TODO: Implement save as journal functionality
            } label: {
                Text("Save as journal")
                    .font(typography.button)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [theme.fabGradientStart, theme.fabGradientEnd]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 99, style: .continuous))
            }
            .opacity(messages.isEmpty ? 0.5 : 1.0)
            .disabled(messages.isEmpty)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Actions
    private func sendMessage() {
        guard !messageText.isEmpty else { return }

        let userMessageText = messageText

        // Add user message
        let userMessage = ChatMessage(
            text: userMessageText,
            sender: .user,
            timestamp: Date()
        )
        messages.append(userMessage)

        // Clear input
        messageText = ""

        // Auto-respond with default message after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let aiResponse = ChatMessage(
                text: "That's interesting! Tell me more about how you're feeling.",
                sender: .assistant,
                timestamp: Date()
            )
            messages.append(aiResponse)
        }
    }
}

#Preview {
    AIChatView()
        .useTheme()
        .useTypography()
}
