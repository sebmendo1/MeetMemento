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
    @StateObject private var insightViewModel = InsightViewModel()
    @Environment(\.theme) private var theme
    @Environment(\.typography) private var type

    public init() {}

    public var body: some View {
        Group {
            if entryViewModel.entries.isEmpty {
                // Empty state - no entries
                emptyState(
                    icon: "sparkles",
                    title: "No insights yet",
                    message: "Your insights will appear here after journaling."
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if insightViewModel.isLoading {
                // Loading state
                loadingState
            } else if let errorMessage = insightViewModel.errorMessage {
                // Check if it's a milestone progress message
                if errorMessage.contains("more") && (errorMessage.contains("entry") || errorMessage.contains("entries")) {
                    // Milestone progress state
                    milestoneProgressState(message: errorMessage, entryCount: entryViewModel.entries.count)
                } else {
                    // Regular error state
                    errorState(message: errorMessage)
                }
            } else if let insights = insightViewModel.insights {
                // Content with insights
                insightsContent(insights: insights)
            } else {
                // Initial state - has entries but hasn't loaded insights yet
                loadingState
            }
        }
        .background(Color.clear)
        .ignoresSafeArea()
        .onAppear {
            // Only load if insights don't exist (handles first load + ViewModel recreation)
            // Otherwise, insights will be cached in memory and reused
            if insightViewModel.insights == nil {
                Task {
                    await insightViewModel.generateInsights(from: entryViewModel.entries)
                }
            }
        }
        .onDisappear {
            // Cleanup real-time subscription when view disappears
            Task {
                await insightViewModel.cleanup()
            }
        }
        .onChange(of: entryViewModel.entries.count) { oldValue, newValue in
            // Reload insights when entries change
            if newValue > 0 {
                Task {
                    await insightViewModel.generateInsights(from: entryViewModel.entries)
                }
            }
        }
    }

    /// Content view showing AI insights
    private func insightsContent(insights: JournalInsights) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 40) {
                // AI Summary Section
                AISummarySection(
                    title: insights.summary,
                    body: insights.description
                )

                // Timestamp - when insights were last updated
                timestampView(insights: insights)

                // Date Annotations Timeline (between description and themes)
                if !insights.annotations.isEmpty {
                    InsightAnnotationsSection(annotations: insights.annotations)
                }

                // Themes Section
                InsightsThemesSection(
                    themes: insights.themes.map { $0.name }
                )

                // Cache indicator (if from cache)
                if insights.fromCache {
                    cacheIndicator(insights: insights)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 108) // 80px header + 28px spacing
            .padding(.bottom, 24) // Bottom padding for scroll content
        }
        .refreshable {
            // Pull to refresh - force new insights
            await loadInsights(force: true)
        }
    }

    /// Loading state view
    private var loadingState: some View {
        VStack(spacing: 16) {
            Spacer()

            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                .scaleEffect(1.2)

            Text("Analyzing your journal...")
                .font(type.body)
                .foregroundStyle(.white.opacity(0.8))

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    /// Error state view
    private func errorState(message: String) -> some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 36))
                .foregroundStyle(.white)

            Text("Couldn't load insights")
                .font(type.h3)
                .fontWeight(.semibold)
                .foregroundStyle(.white)

            Text(message)
                .font(type.body)
                .foregroundStyle(.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button(action: { Task { await loadInsights(force: true) } }) {
                Text("Try Again")
                    .font(type.body)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.white.opacity(0.2))
                    )
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    /// Milestone progress state - shows user how many more entries needed
    private func milestoneProgressState(message: String, entryCount: Int) -> some View {
        VStack(spacing: 24) {
            Spacer()

            // Progress icon
            ZStack {
                Circle()
                    .stroke(.white.opacity(0.2), lineWidth: 8)
                    .frame(width: 120, height: 120)

                Circle()
                    .trim(from: 0, to: {
                        // Calculate progress toward next milestone
                        let remainder = entryCount % 3
                        return remainder == 0 ? 1.0 : CGFloat(remainder) / 3.0
                    }())
                    .stroke(.white, lineWidth: 8)
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 4) {
                    Text("\(entryCount)")
                        .font(.system(size: 36))
                        .fontWeight(.bold)
                        .foregroundStyle(.white)

                    Text(entryCount == 1 ? "entry" : "entries")
                        .font(.system(size: 14))
                        .foregroundStyle(.white.opacity(0.6))
                }
            }

            // Title and message
            VStack(spacing: 12) {
                Text("Almost there!")
                    .font(type.h3)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)

                Text(message)
                    .font(type.body)
                    .foregroundStyle(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            // Info text
            Text("First insights unlock at 2 entries")
                .font(.system(size: 13))
                .foregroundStyle(.white.opacity(0.5))

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    /// Cache indicator for cached insights
    private func cacheIndicator(insights: JournalInsights) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "clock")
                .font(.system(size: 12))
                .foregroundStyle(.white.opacity(0.6))

            Text("Last updated \(timeAgo(from: insights.generatedAt))")
                .font(.system(size: 13))
                .foregroundStyle(.white.opacity(0.6))

            Spacer()

            if insightViewModel.shouldRefreshInsights {
                Text("Pull to refresh")
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.6))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.white.opacity(0.1))
        )
    }

    /// Timestamp view showing when insights were last updated
    private func timestampView(insights: JournalInsights) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "clock")
                .font(.system(size: 12))
                .foregroundStyle(theme.mutedForeground)

            Text("Updated \(timeAgo(from: insights.generatedAt))")
                .font(.system(size: 13))
                .foregroundStyle(theme.mutedForeground)

            Spacer()

            if insightViewModel.isRegeneratingInBackground {
                ProgressView()
                    .controlSize(.mini)
                    .tint(theme.mutedForeground)
            }
        }
        .padding(.horizontal, 4)
    }

    /// Reusable empty state view - matches JournalView exactly
    private func emptyState(icon: String, title: String, message: String) -> some View {
        VStack(spacing: 12) {
            Spacer()

            Image(systemName: icon)
                .font(.system(size: 36))
                .foregroundStyle(.white)

            Text(title)
                .font(type.h3)
                .fontWeight(.semibold)
                .foregroundStyle(.white)

            Text(message)
                .font(type.body)
                .foregroundStyle(.white.opacity(0.8))

            Spacer()
        }
        .multilineTextAlignment(.center)
        .padding(.horizontal, 16)
    }

    // MARK: - Helper Methods

    /// Loads insights if not already loaded
    private func loadInsightsIfNeeded() {
        guard !entryViewModel.entries.isEmpty else { return }
        guard insightViewModel.insights == nil else { return }

        Task {
            await loadInsights()
        }
    }

    /// Loads insights from entries
    /// - Parameter force: If true, clears cache and forces fresh insights
    private func loadInsights(force: Bool = false) async {
        if force {
            insightViewModel.clearInsights()
        }

        await insightViewModel.generateInsights(from: entryViewModel.entries)
    }

    /// Formats time ago string
    private func timeAgo(from date: Date) -> String {
        let seconds = Date().timeIntervalSince(date)
        let minutes = seconds / 60
        let hours = minutes / 60
        let days = hours / 24

        if days >= 1 {
            let count = Int(days)
            return "\(count) \(count == 1 ? "day" : "days") ago"
        } else if hours >= 1 {
            let count = Int(hours)
            return "\(count) \(count == 1 ? "hour" : "hours") ago"
        } else if minutes >= 1 {
            let count = Int(minutes)
            return "\(count) \(count == 1 ? "minute" : "minutes") ago"
        } else {
            return "just now"
        }
    }
}

// MARK: - Previews
#Preview("Empty State • Light") {
    @Previewable @StateObject var viewModel = EntryViewModel()
    @Previewable @Environment(\.theme) var theme

    ZStack {
        theme.insightsBackground
            .ignoresSafeArea()

        InsightsView()
            .environmentObject(viewModel)
            .onAppear {
                viewModel.entries = [] // Empty state
            }
    }
    .useTheme()
    .useTypography()
    .preferredColorScheme(.light)
}

#Preview("Loading State • Light") {
    @Previewable @StateObject var entryViewModel = EntryViewModel()
    @Previewable @Environment(\.theme) var theme

    ZStack {
        theme.insightsBackground
            .ignoresSafeArea()

        InsightsView()
            .environmentObject(entryViewModel)
            .onAppear {
                entryViewModel.loadMockEntries()
            }
    }
    .useTheme()
    .useTypography()
    .preferredColorScheme(.light)
}

#Preview("With Insights • Light") {
    @Previewable @StateObject var entryViewModel = EntryViewModel()
    @Previewable @Environment(\.theme) var theme
    @Previewable @Environment(\.typography) var type

    ZStack {
        theme.insightsBackground
            .ignoresSafeArea()

        ScrollView {
            VStack(alignment: .leading, spacing: 40) {
                AISummarySection(
                    title: JournalInsights.sample.summary,
                    body: JournalInsights.sample.description
                )

                InsightAnnotationsSection(annotations: JournalInsights.sample.annotations)

                InsightsThemesSection(
                    themes: JournalInsights.sample.themes.map { $0.name }
                )
            }
            .padding(.horizontal, 20)
            .padding(.top, 108)
            .padding(.bottom, 24)
        }
    }
    .useTheme()
    .useTypography()
    .preferredColorScheme(.light)
}

#Preview("With Insights • Dark") {
    @Previewable @StateObject var entryViewModel = EntryViewModel()
    @Previewable @Environment(\.theme) var theme
    @Previewable @Environment(\.typography) var type

    ZStack {
        theme.insightsBackground
            .ignoresSafeArea()

        ScrollView {
            VStack(alignment: .leading, spacing: 40) {
                AISummarySection(
                    title: JournalInsights.sample.summary,
                    body: JournalInsights.sample.description
                )

                InsightAnnotationsSection(annotations: JournalInsights.sample.annotations)

                InsightsThemesSection(
                    themes: JournalInsights.sample.themes.map { $0.name }
                )
            }
            .padding(.horizontal, 20)
            .padding(.top, 108)
            .padding(.bottom, 24)
        }
    }
    .useTheme()
    .useTypography()
    .preferredColorScheme(.dark)
}
