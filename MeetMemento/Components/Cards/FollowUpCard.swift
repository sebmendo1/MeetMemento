//
//  FollowUpCard.swift
//  MeetMemento
//
//  A card component for displaying follow-up questions to help users dig deeper into their journaling.
//

import SwiftUI

struct FollowUpCard: View {
    let question: String
    let isCompleted: Bool
    let onTap: () -> Void

    @Environment(\.theme) private var theme
    @Environment(\.typography) private var type

    // MARK: - State
    @State private var isPressed = false

    var body: some View {
        Button(action: {
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            onTap()
        }) {
            HStack(alignment: .center, spacing: 12) {
                // Question text
                Text(question)
                    .font(type.bodySmallBold)
                    .foregroundStyle(isCompleted ? theme.mutedForeground : theme.foreground)
                    .strikethrough(isCompleted, color: theme.mutedForeground)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)

                // Icon (chevron for incomplete, checkmark for complete)
                if isCompleted {
                    // Purple checkmark circle
                    ZStack {
                        Circle()
                            .fill(theme.primary)
                            .frame(width: 24, height: 24)

                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.white)
                    }
                } else {
                    // Chevron icon with circle border
                    ZStack {
                        Circle()
                            .stroke(theme.mutedForeground, lineWidth: 1.5)
                            .frame(width: 24, height: 24)

                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(theme.mutedForeground)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(theme.secondary)
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {})
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Follow-up question: \(question)")
        .accessibilityHint(isCompleted ? "Completed" : "Tap to journal about this reflection question")
    }
    
}

// MARK: - Previews

#Preview("Both States") {
    VStack(spacing: 16) {
        // Incomplete state
        FollowUpCard(
            question: "What do you think is next for reaching acceptance about your recent loss?",
            isCompleted: false
        ) {
            print("Incomplete card tapped!")
        }

        // Complete state
        FollowUpCard(
            question: "What do you think is next for reaching acceptance about your recent loss?",
            isCompleted: true
        ) {
            print("Complete card tapped!")
        }
    }
    .padding()
    .useTheme()
    .useTypography()
}

#Preview("Multiple Cards - Mixed States") {
    VStack(spacing: 16) {
        FollowUpCard(
            question: "What was the most challenging part of your day?",
            isCompleted: false
        ) {
            print("Card 1 tapped!")
        }
        FollowUpCard(
            question: "How did you practice self-care today?",
            isCompleted: true
        ) {
            print("Card 2 tapped!")
        }
        FollowUpCard(
            question: "What are you grateful for right now?",
            isCompleted: false
        ) {
            print("Card 3 tapped!")
        }
    }
    .padding()
    .useTheme()
    .useTypography()
    .background(Color.gray.opacity(0.1).ignoresSafeArea())
}
