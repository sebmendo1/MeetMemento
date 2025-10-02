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
            // Top navigation as a singleSelected state
            TopNav(variant: .singleSelected, selection: .constant(.yourEntries))
                .useTheme()
                .useTypography()
                .padding(.top, 12)

            Spacer()

            // Empty state placeholder
            VStack(spacing: 12) {
                Image(systemName: "sparkles")
                    .font(.system(size: 36))
                    .foregroundStyle(theme.mutedForeground)

                Text("No insights yet")
                    .font(type.h3)
                    .fontWeight(.semibold)
                    .foregroundStyle(theme.foreground)

                Text("Your insights will appear here after journaling.")
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
