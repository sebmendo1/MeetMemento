//
//  FollowUpQuestionCard.swift
//  MeetMemento
//
//  A card component for displaying follow-up questions to help users dig deeper into their journaling.
//

import SwiftUI

struct FollowUpQuestionCard: View {
    let question: FollowUpQuestion
    let onTap: () -> Void
    
    @Environment(\.theme) private var theme
    @Environment(\.typography) private var type
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                // Header with icon and category
                HStack(spacing: 8) {
                    // Category icon
                    Image(systemName: question.category.icon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Color(hex: question.category.color))
                        .frame(width: 24, height: 24)
                    
                    // Category label
                    Text(question.category.displayName)
                        .font(type.body)
                        .foregroundStyle(Color(hex: question.category.color))
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    // Completion indicator
                    if question.isCompleted {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(.green)
                    } else {
                        Image(systemName: "circle")
                            .font(.system(size: 16))
                            .foregroundStyle(theme.mutedForeground)
                    }
                }
                
                // Question title
                Text(question.title)
                    .font(type.h4)
                    .foregroundStyle(theme.foreground)
                    .multilineTextAlignment(.leading)
                    .lineLimit(3)
                
                // Question description
                Text(question.description)
                    .font(type.body)
                    .foregroundStyle(theme.mutedForeground)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                
                Spacer(minLength: 4)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(PlainButtonStyle())
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.background)
                .shadow(
                    color: Color(red: 99/255, green: 99/255, blue: 99/255, opacity: 0.2),
                    radius: 4,
                    x: 0,
                    y: 2
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color(hex: "#dddddd"), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(question.category.displayName): \(question.title)")
        .accessibilityHint("Tap to explore this reflection question")
    }
}

// MARK: - Previews

#Preview("Follow-up Question Card") {
    FollowUpQuestionCard(
        question: FollowUpQuestion.sampleQuestions[0]
    ) {
        print("Question tapped")
    }
    .padding()
    .useTheme()
    .useTypography()
}

#Preview("Completed Question") {
    FollowUpQuestionCard(
        question: FollowUpQuestion(
            title: "What am I grateful for today?",
            description: "Take a moment to reflect on the positive aspects of your day.",
            category: .gratitude,
            isCompleted: true
        )
    ) {
        print("Question tapped")
    }
    .padding()
    .useTheme()
    .useTypography()
}
