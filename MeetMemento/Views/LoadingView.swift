//
//  LoadingView.swift
//  MeetMemento
//
//  Loading screen shown while checking authentication state
//

import SwiftUI

struct LoadingView: View {
    @Environment(\.theme) private var theme
    @Environment(\.typography) private var type
    
    var body: some View {
        ZStack {
            theme.background.ignoresSafeArea()
            
            VStack(spacing: 24) {
                // App icon
                Image(systemName: "sparkles")
                    .font(.system(size: 64))
                    .foregroundStyle(theme.primary)
                    .symbolEffect(.pulse)
                
                // App name
                Text("MeetMemento")
                    .font(type.h1)
                    .headerGradient()
                
                // Loading indicator
                ProgressView()
                    .tint(theme.primary)
                    .scaleEffect(1.2)
            }
        }
    }
}

#Preview("Light") {
    LoadingView()
        .useTheme()
        .useTypography()
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    LoadingView()
        .useTheme()
        .useTypography()
        .preferredColorScheme(.dark)
}

