//
//  InsightsView.swift
//  MeetMemento
//
//  Shows TopNav with singleSelected state and empty state
//

import SwiftUI

public struct InsightsView: View {
    @Environment(\.theme) private var theme
    @Environment(\.typography) private var type

    public init() {}

    public var body: some View {
        VStack(spacing: 0) {
            // Header with single selected state
            Header(
                variant: .singleSelected,
                selection: .constant(.yourEntries),
                onSettingsTapped: {
                    // No settings action for insights view
                }
            )

            // Empty state placeholder - positioned exactly like JournalView empty state
            emptyState(
                icon: "sparkles",
                title: "No insights yet",
                message: "Your insights will appear here after journaling."
            )
            .padding(.top, -40) // Move up 16px to match JournalView position exactly
        }
        .background(theme.background.ignoresSafeArea())
    }
    
    /// Reusable empty state view - matches JournalView exactly
    private func emptyState(icon: String, title: String, message: String) -> some View {
        VStack(spacing: 12) {
            Spacer()
            
            Image(systemName: icon)
                .font(.system(size: 36))
                .headerGradient()
            
            Text(title)
                .font(type.h3)
                .fontWeight(.semibold)
                .headerGradient()
            
            Text(message)
                .font(type.body)
                .foregroundStyle(theme.mutedForeground)
            
            Spacer()
        }
        .multilineTextAlignment(.center)
        .padding(.horizontal, 16)
    }
}

// MARK: - PreviewProvider
struct InsightsView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            InsightsView()
                .previewDisplayName("Insights • Light")
                .preferredColorScheme(.light)

            InsightsView()
                .previewDisplayName("Insights • Dark")
                .preferredColorScheme(.dark)
        }
    }
}
