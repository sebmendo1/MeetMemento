//
//  ChatEmptyState.swift
//  MeetMemento
//
//  Created by Sebastian Mendo on 10/24/25.
//

import SwiftUI

struct ChatEmptyState: View {
    @Environment(\.theme) private var theme
    @Environment(\.typography) private var typography

    var body: some View {
        VStack(spacing: 20) {
            // Logo
            Image("LaunchLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 48, height: 48)

            // Title
            Text("Let's explore your thoughts")
                .font(typography.h3)
                .foregroundStyle(
                    LinearGradient(
                        gradient: Gradient(colors: [theme.headerGradientStart, theme.headerGradientEnd]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 32)
    }
}

#Preview {
    ChatEmptyState()
        .useTheme()
        .useTypography()
}
