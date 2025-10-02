//
//  JournalView.swift
//  MeetMemento
//
//  Shows TopNav with tabs (Your Entries / Follow-ups) and empty state
//

import SwiftUI

public struct JournalView: View {
    @State private var topSelection: JournalTopTab = .yourEntries

    @Environment(\.theme) private var theme
    @Environment(\.typography) private var type

    public init() {}

    public var body: some View {
        VStack(spacing: 0) {
            // Top navigation with tabs
            TopNav(variant: .tabs, selection: $topSelection)
                .useTheme()
                .useTypography()
                .padding(.top, 12)

            Spacer()

            // Empty state placeholder
            VStack(spacing: 12) {
                Image(systemName: "book.closed.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(theme.mutedForeground)

                Text("No journal entries yet")
                    .font(type.h3)
                    .fontWeight(.semibold)
                    .foregroundStyle(theme.foreground)

                Text("Start writing your first entry to see it here.")
                    .font(type.body)
                    .foregroundStyle(theme.mutedForeground)
            }
            .multilineTextAlignment(.center)
            .padding(.horizontal, 24)

            Spacer()
        }
        .background(theme.background.ignoresSafeArea())
    }
}

// MARK: - PreviewProvider
struct JournalView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            JournalView()
                .previewDisplayName("Journal • Light")
                .preferredColorScheme(.light)

            JournalView()
                .previewDisplayName("Journal • Dark")
                .preferredColorScheme(.dark)
        }
    }
}
