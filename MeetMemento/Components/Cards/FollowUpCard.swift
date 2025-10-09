//
//  FollowUpCard.swift
//  MeetMemento
//
//  A card component for displaying follow-up questions to help users dig deeper into their journaling.
//

import SwiftUI

struct FollowUpCard: View {
    let question: String
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
            VStack(alignment: .leading, spacing: 12) {
                headerSection
                questionSection
            }
            .padding(16)
            .padding(.bottom, 4)
            .background(cardBackground)
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
        .accessibilityHint("Tap to journal about this reflection question")
    }
    
    private var headerSection: some View {
        HStack {
            // FOLLOW-UP tag
            HStack(spacing: 6) {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white)
                Text("FOLLOW-UP")
                    .font(type.label)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 10)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(theme.followUpTagBackground)
            )
            
            Spacer()
            
            // Chevron icon
            Image(systemName: "chevron.right")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)
        }
    }
    
    private var questionSection: some View {
        Text(question)
            .font(type.h4)
            .fontWeight(.bold)
            .foregroundStyle(.white)
            .lineLimit(2)
            .multilineTextAlignment(.leading)
    }
    
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
            .fill(
                LinearGradient(
                    gradient: Gradient(colors: [theme.followUpGradientStart, theme.followUpGradientEnd]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .shadow(
                color: Color.black.opacity(isPressed ? 0 : 0.2),
                radius: isPressed ? 0 : 8,
                x: 0,
                y: isPressed ? 0 : 4
            )
    }
}

// MARK: - Previews

#Preview("Follow-up Card") {
    FollowUpCard(question: "What was the most challenging part of your day?") {
        print("Follow-up card tapped!")
    }
    .padding()
    .useTheme()
    .useTypography()
}

#Preview("Multiple Cards") {
    VStack(spacing: 16) {
        FollowUpCard(question: "What was the most challenging part of your day?") {
            print("Card 1 tapped!")
        }
        FollowUpCard(question: "How did you practice self-care today?") {
            print("Card 2 tapped!")
        }
        FollowUpCard(question: "What are you grateful for right now?") {
            print("Card 3 tapped!")
        }
    }
    .padding()
    .useTheme()
    .useTypography()
    .background(Color.gray.opacity(0.1).ignoresSafeArea())
}
