//
//  InsightsView.swift
//  MeetMemento
//
//  Shows AI-generated insights based on journal entries.
//  Displays empty state when no entries exist, otherwise shows SummaryCard with insights.
//

import SwiftUI

public struct InsightsView: View {
    @EnvironmentObject var entryViewModel: EntryViewModel
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

            // Content: Show empty state or insights based on entry count
            if entryViewModel.entries.isEmpty {
                emptyState(
                    icon: "sparkles",
                    title: "No insights yet",
                    message: "Your insights will appear here after journaling."
                )
                .padding(.top, -40) // Move up 16px to match JournalView position exactly
            } else {
                insightsContent
            }
        }
        .background(theme.background.ignoresSafeArea())
    }

    /// Content view showing AI insights with SummaryCard
    private var insightsContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // SummaryCard at the top
                SummaryCard(insights: [
                    "Over the past week, you've reflected frequently on work stress and overwhelm around deadlines and meetings.",
                    "You tend to feel better after short morning runs; consider scheduling two 20–30 minute sessions mid-week.",
                    "One-on-one conversations leave you more energized than large group events."
                ])

                // Future: Add more insight components here
            }
            ThemesSection(
                themes: [
                    "Work-related stress", "Purpose",
                    "Inner growth", "Closing doors",
                    "Acceptance", "Realizing the truth",
                    "Choosing better", "Living your life"
                ]
            )
            .padding(.top, 28) // Match JournalTView top padding (12px existing + 16px additional)
            .padding(.bottom, 24) // Bottom padding for scroll content
        }
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

// MARK: - Previews
#Preview("Empty State • Light") {
    @Previewable @StateObject var viewModel = EntryViewModel()

    InsightsView()
        .environmentObject(viewModel)
        .onAppear {
            viewModel.entries = [] // Empty state
        }
        .useTheme()
        .useTypography()
        .preferredColorScheme(.light)
}

#Preview("With Insights • Light") {
    @Previewable @StateObject var viewModel = EntryViewModel()

    InsightsView()
        .environmentObject(viewModel)
        .onAppear {
            viewModel.loadMockEntries() // Load sample data
        }
        .useTheme()
        .useTypography()
        .preferredColorScheme(.light)
}

#Preview("With Insights • Dark") {
    @Previewable @StateObject var viewModel = EntryViewModel()

    InsightsView()
        .environmentObject(viewModel)
        .onAppear {
            viewModel.loadMockEntries() // Load sample data
        }
        .useTheme()
        .useTypography()
        .preferredColorScheme(.dark)
}
