//
//  Header.swift
//  MeetMemento
//
//  Created by Sebastian Mendo on 12/15/24.
//

import SwiftUI

// MARK: - Header Component
/// A reusable header component that combines TopTabNav and menu button
/// - Supports both tabbed and single-selected navigation variants
/// - Includes settings menu button with consistent styling
/// - Maintains proper spacing and padding
public struct Header: View {
    
    // MARK: - Properties
    public let variant: TopNavVariant
    @Binding public var selection: JournalTopTab
    public let onSettingsTapped: () -> Void
    
    @Environment(\.theme) private var theme
    
    // MARK: - Layout Constants
    private let horizontalPadding: CGFloat = 16
    private let topPadding: CGFloat = 12
    private let bottomPadding: CGFloat = 16
    private let spacing: CGFloat = 12
    
    // MARK: - Initializer
    public init(
        variant: TopNavVariant,
        selection: Binding<JournalTopTab>,
        onSettingsTapped: @escaping () -> Void
    ) {
        self.variant = variant
        self._selection = selection
        self.onSettingsTapped = onSettingsTapped
    }
    
    // MARK: - Body
    public var body: some View {
        HStack(alignment: .center, spacing: spacing) {
            // Top navigation with tabs
            TopNav(variant: variant, selection: $selection)
                .useTheme()
                .useTypography()
            
            Spacer()
            
            // Settings menu button (aligned with tabs)
            Button(action: onSettingsTapped) {
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [theme.fabGradientStart, theme.fabGradientEnd]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(Circle())
                    .shadow(color: theme.primary.opacity(0.3), radius: 6, x: 0, y: 4)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Settings")
        }
        .padding(.horizontal, horizontalPadding)
        .padding(.top, topPadding)
        .padding(.bottom, bottomPadding)
    }
}

// MARK: - Previews
#Preview("Header • Tabs") {
    @Previewable @State var selectedTab: JournalTopTab = .yourEntries
    
    VStack {
        Header(
            variant: .tabs,
            selection: $selectedTab,
            onSettingsTapped: {
                print("Settings tapped")
            }
        )
        
        Spacer()
    }
    .useTheme()
    .useTypography()
    .preferredColorScheme(.light)
}

#Preview("Header • Single Selected") {
    @Previewable @State var selectedTab: JournalTopTab = .yourEntries
    
    VStack {
        Header(
            variant: .singleSelected,
            selection: $selectedTab,
            onSettingsTapped: {
                print("Settings tapped")
            }
        )
        
        Spacer()
    }
    .useTheme()
    .useTypography()
    .preferredColorScheme(.dark)
}
