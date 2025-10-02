//
//  Theme+Optimized.swift
//  MeetMemento
//
//  Optimized theme system for faster SwiftUI previews
//

import SwiftUI

// MARK: - Fast Color Cache
/// Pre-computed colors to avoid repeated hex parsing
private struct ColorCache {
    // Light theme colors
    static let lightBackground = Color(red: 1, green: 1, blue: 1)
    static let lightForeground = Color(red: 0.039, green: 0.039, blue: 0.039)
    static let lightPrimary = Color(red: 0.541, green: 0.220, blue: 0.961)
    static let lightPrimaryForeground = Color(red: 0.941, green: 0.949, blue: 0.961)
    static let lightSecondary = Color(red: 0.925, green: 0.933, blue: 0.949)
    static let lightMuted = Color(red: 0.925, green: 0.925, blue: 0.941)
    static let lightMutedForeground = Color(red: 0.443, green: 0.443, blue: 0.510)
    static let lightBorder = Color.black.opacity(0.1)
    static let lightInputBackground = Color(red: 0.953, green: 0.953, blue: 0.961)
    static let lightCard = Color.white
    static let lightCardForeground = Color(red: 0.039, green: 0.039, blue: 0.039)
    
    // Dark theme colors
    static let darkBackground = Color(red: 0.039, green: 0.039, blue: 0.039)
    static let darkForeground = Color(red: 0.980, green: 0.980, blue: 0.980)
    static let darkPrimary = Color(red: 0.980, green: 0.980, blue: 0.980)
    static let darkPrimaryForeground = Color(red: 0.090, green: 0.090, blue: 0.090)
    static let darkSecondary = Color(red: 0.149, green: 0.149, blue: 0.149)
    static let darkMuted = Color(red: 0.149, green: 0.149, blue: 0.149)
    static let darkMutedForeground = Color(red: 0.631, green: 0.631, blue: 0.631)
    static let darkBorder = Color(red: 0.149, green: 0.149, blue: 0.149)
    static let darkInputBackground = Color(red: 0.149, green: 0.149, blue: 0.149)
    static let darkCard = Color(red: 0.039, green: 0.039, blue: 0.039)
    static let darkCardForeground = Color(red: 0.980, green: 0.980, blue: 0.980)
}

// MARK: - Lightweight Theme (for previews)
/// Use this in previews for instant rendering
public struct PreviewTheme {
    let background: Color
    let foreground: Color
    let primary: Color
    let primaryForeground: Color
    let secondary: Color
    let muted: Color
    let mutedForeground: Color
    let border: Color
    let inputBackground: Color
    let card: Color
    let cardForeground: Color
    
    let radius: CGFloat = 10
    
    static let light = PreviewTheme(
        background: ColorCache.lightBackground,
        foreground: ColorCache.lightForeground,
        primary: ColorCache.lightPrimary,
        primaryForeground: ColorCache.lightPrimaryForeground,
        secondary: ColorCache.lightSecondary,
        muted: ColorCache.lightMuted,
        mutedForeground: ColorCache.lightMutedForeground,
        border: ColorCache.lightBorder,
        inputBackground: ColorCache.lightInputBackground,
        card: ColorCache.lightCard,
        cardForeground: ColorCache.lightCardForeground
    )
    
    static let dark = PreviewTheme(
        background: ColorCache.darkBackground,
        foreground: ColorCache.darkForeground,
        primary: ColorCache.darkPrimary,
        primaryForeground: ColorCache.darkPrimaryForeground,
        secondary: ColorCache.darkSecondary,
        muted: ColorCache.darkMuted,
        mutedForeground: ColorCache.darkMutedForeground,
        border: ColorCache.darkBorder,
        inputBackground: ColorCache.darkInputBackground,
        card: ColorCache.darkCard,
        cardForeground: ColorCache.darkCardForeground
    )
}

// MARK: - Minimal Preview Wrapper
/// Drop-in replacement for .useTheme().useTypography() in previews
public extension View {
    func previewTheme(_ colorScheme: ColorScheme = .light) -> some View {
        self
            .preferredColorScheme(colorScheme)
            .previewLayout(.sizeThatFits)
    }
}

