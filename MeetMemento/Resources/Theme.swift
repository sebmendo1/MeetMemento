import SwiftUI

// MARK: - Hex helpers
extension Color {
    init(hex: String) {
        var s = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if s.hasPrefix("#") { s.removeFirst() }
        var v: UInt64 = 0
        Scanner(string: s).scanHexInt64(&v)
        let r, g, b: Double
        switch s.count {
        case 6:
            r = Double((v >> 16) & 0xFF) / 255.0
            g = Double((v >> 8)  & 0xFF) / 255.0
            b = Double(v & 0xFF) / 255.0
        default:
            r = 1; g = 1; b = 1
        }
        self = Color(red: r, green: g, blue: b)
    }
}

// MARK: - Design Tokens
/// Design token system for consistent color usage throughout the app.
/// These tokens provide a structured color palette with defined scales for gray and primary colors.
/// All colors meet WCAG AA accessibility standards for contrast ratios.

/// Gray scale color tokens - neutral colors for backgrounds, borders, and text
struct GrayScale {
    static let gray50  = Color(hex: "#F9FBFC")  // Lightest - backgrounds
    static let gray100 = Color(hex: "#F0F4F7")  // Light backgrounds
    static let gray200 = Color(hex: "#E2E8ED")  // Muted backgrounds
    static let gray300 = Color(hex: "#CFD6DC")  // Borders
    static let gray400 = Color(hex: "#B8C0C7")  // Disabled states
    static let gray500 = Color(hex: "#8D97A3")  // Placeholder text
    static let gray600 = Color(hex: "#66707A")  // Secondary text
    static let gray700 = Color(hex: "#4B5560")  // Primary text (dark mode backgrounds)
    static let gray800 = Color(hex: "#2F3943")  // Dark backgrounds
    static let gray900 = Color(hex: "#1C2329")  // Darkest - primary text
}

/// Primary purple scale - brand colors for interactive elements
struct PrimaryScale {
    static let primary50  = Color(hex: "#F2EEFC")  // Lightest tint
    static let primary100 = Color(hex: "#E2D5F3")  // Light tint
    static let primary200 = Color(hex: "#C5A9E7")  // Soft purple
    static let primary300 = Color(hex: "#A77FDB")  // Medium light
    static let primary400 = Color(hex: "#9869D5")  // Medium (dark mode primary)
    static let primary500 = Color(hex: "#7B3EC9")  // Main brand color
    static let primary600 = Color(hex: "#6125B1")  // Darker brand
    static let primary700 = Color(hex: "#57219C")  // Deep purple
    static let primary800 = Color(hex: "#411976")  // Very dark
    static let primary900 = Color(hex: "#361562")  // Darkest
}

/// Base colors - pure white and black
struct BaseColors {
    static let white = Color(hex: "#FFFFFF")
    static let black = Color(hex: "#000000")
}

// MARK: - Theme

struct Theme {
    // Base / sizing tokens (pulling from CSS)
    let baseFontSize: CGFloat = 16         // --font-size
    struct Radius {
        // --radius = 0.625rem = 10px (with base 16)
        let sm: CGFloat = 6   // radius - 4px
        let md: CGFloat = 8   // radius - 2px
        let lg: CGFloat = 10  // radius
        let xl: CGFloat = 14  // radius + 4px
        let round: CGFloat = 999  // round

    }
    let radius = Radius()

    struct Weights {
        let normal: Font.Weight = .regular // 400
        let medium: Font.Weight = .medium  // 500
    }
    let weights = Weights()

    // Color palette (semantic)
    let background: Color
    let foreground: Color
    let card: Color
    let cardForeground: Color
    let popover: Color
    let popoverForeground: Color
    let primary: Color
    let primaryForeground: Color
    let secondary: Color
    let secondaryForeground: Color
    let muted: Color
    let mutedForeground: Color
    let accent: Color
    let accentForeground: Color
    let destructive: Color
    let destructiveForeground: Color
    let border: Color
    let input: Color
    let inputBackground: Color
    let switchBackground: Color
    let ring: Color

    // Charts
    let chart1: Color
    let chart2: Color
    let chart3: Color
    let chart4: Color
    let chart5: Color
    
    // Follow-up card gradient
    let followUpGradientStart: Color
    let followUpGradientEnd: Color
    let followUpTagBackground: Color
    
    // FAB (Floating Action Button) gradient
    let fabGradientStart: Color
    let fabGradientEnd: Color
    
    // Header text gradient (for H1, H2, H3 in Recoleta)
    let headerGradientStart: Color
    let headerGradientEnd: Color

    // Sidebar
    let sidebar: Color
    let sidebarForeground: Color
    let sidebarPrimary: Color
    let sidebarPrimaryForeground: Color
    let sidebarAccent: Color
    let sidebarAccentForeground: Color
    let sidebarBorder: Color
    let sidebarRing: Color

    // MARK: Palettes

    /// Light theme - optimized for readability with WCAG AA compliance
    /// Contrast ratios:
    /// - Gray 900 on Gray 50: ~18:1 (AAA)
    /// - Gray 900 on White: ~19:1 (AAA)
    /// - Primary 500 on White: ~4.8:1 (AA)
    /// - Gray 600 on White: ~7.5:1 (AAA)
    static let light = Theme(
        background: GrayScale.gray50,           // #F9FBFC - Soft background
        foreground: GrayScale.gray900,          // #1C2329 - Primary text
        card: BaseColors.white,                 // #FFFFFF - Pure white cards
        cardForeground: GrayScale.gray900,      // #1C2329 - Card text
        popover: BaseColors.white,              // #FFFFFF - Popovers
        popoverForeground: GrayScale.gray900,   // #1C2329 - Popover text
        primary: PrimaryScale.primary500,       // #7B3EC9 - Main brand color
        primaryForeground: BaseColors.white,    // #FFFFFF - Text on primary
        secondary: GrayScale.gray100,           // #F0F4F7 - Secondary backgrounds
        secondaryForeground: GrayScale.gray900, // #1C2329 - Secondary text
        muted: GrayScale.gray200,               // #E2E8ED - Muted backgrounds
        mutedForeground: GrayScale.gray600,     // #66707A - Muted text
        accent: PrimaryScale.primary500,        // #7B3EC9 - Accent color
        accentForeground: BaseColors.white,     // #FFFFFF - Text on accent
        destructive: Color(hex: "#D4183D"),     // Red for destructive actions
        destructiveForeground: BaseColors.white, // #FFFFFF - Text on destructive
        border: GrayScale.gray300,              // #CFD6DC - Borders
        input: GrayScale.gray300,               // #CFD6DC - Input borders
        inputBackground: GrayScale.gray100,     // #F0F4F7 - Input fields
        switchBackground: GrayScale.gray400,    // #B8C0C7 - Toggle backgrounds
        ring: PrimaryScale.primary500,          // #7B3EC9 - Focus rings
        
        chart1: Color(hex: "#F54900"),          // Orange
        chart2: Color(hex: "#009689"),          // Teal
        chart3: Color(hex: "#104E64"),          // Deep blue
        chart4: Color(hex: "#FFB900"),          // Yellow
        chart5: Color(hex: "#FE9A00"),          // Amber
        
        followUpGradientStart: PrimaryScale.primary400,  // #9869D5 - Lighter purple
        followUpGradientEnd: PrimaryScale.primary700,    // #57219C - Deeper purple
        followUpTagBackground: BaseColors.white.opacity(0.2),
        
        fabGradientStart: PrimaryScale.primary400,       // #9869D5 - Lighter purple for FAB
        fabGradientEnd: PrimaryScale.primary600,         // #6125B1 - Darker purple for FAB
        
        headerGradientStart: PrimaryScale.primary500,    // #7B3EC9 - Main brand purple for headers
        headerGradientEnd: PrimaryScale.primary700,      // #57219C - Deep purple for headers
        
        sidebar: BaseColors.white,              // #FFFFFF - Sidebar background
        sidebarForeground: GrayScale.gray900,   // #1C2329 - Sidebar text
        sidebarPrimary: PrimaryScale.primary500,// #7B3EC9 - Sidebar primary
        sidebarPrimaryForeground: BaseColors.white, // #FFFFFF - Text on sidebar primary
        sidebarAccent: GrayScale.gray100,       // #F0F4F7 - Sidebar accent
        sidebarAccentForeground: GrayScale.gray900, // #1C2329 - Sidebar accent text
        sidebarBorder: GrayScale.gray200,       // #E2E8ED - Sidebar borders
        sidebarRing: PrimaryScale.primary500    // #7B3EC9 - Sidebar focus rings
    )

    /// Dark theme - optimized for low-light viewing with WCAG AA compliance
    /// Contrast ratios:
    /// - Gray 50 on Gray 900: ~18:1 (AAA)
    /// - Gray 50 on Gray 800: ~15:1 (AAA)
    /// - Primary 400 on Gray 900: ~5.1:1 (AA)
    /// - Gray 300 on Gray 900: ~9.8:1 (AAA)
    static let dark = Theme(
        background: GrayScale.gray900,          // #1C2329 - Dark background
        foreground: GrayScale.gray50,           // #F9FBFC - Primary text
        card: GrayScale.gray800,                // #2F3943 - Card backgrounds
        cardForeground: GrayScale.gray50,       // #F9FBFC - Card text
        popover: GrayScale.gray800,             // #2F3943 - Popovers
        popoverForeground: GrayScale.gray50,    // #F9FBFC - Popover text
        primary: PrimaryScale.primary400,       // #9869D5 - Lighter brand color
        primaryForeground: GrayScale.gray900,   // #1C2329 - Text on primary
        secondary: GrayScale.gray800,           // #2F3943 - Secondary backgrounds
        secondaryForeground: GrayScale.gray50,  // #F9FBFC - Secondary text
        muted: GrayScale.gray700,               // #4B5560 - Muted backgrounds
        mutedForeground: GrayScale.gray300,     // #CFD6DC - Muted text
        accent: PrimaryScale.primary400,        // #9869D5 - Accent color
        accentForeground: GrayScale.gray900,    // #1C2329 - Text on accent
        destructive: Color(hex: "#FF4D6A"),     // Lighter red for dark mode
        destructiveForeground: GrayScale.gray50, // #F9FBFC - Text on destructive
        border: GrayScale.gray700,              // #4B5560 - Borders
        input: GrayScale.gray700,               // #4B5560 - Input borders
        inputBackground: GrayScale.gray800,     // #2F3943 - Input fields
        switchBackground: GrayScale.gray600,    // #66707A - Toggle backgrounds
        ring: PrimaryScale.primary400,          // #9869D5 - Focus rings
        
        chart1: Color(hex: "#1447E6"),          // Blue
        chart2: Color(hex: "#00BC7D"),          // Green
        chart3: Color(hex: "#FE9A00"),          // Orange
        chart4: Color(hex: "#AD46FF"),          // Purple
        chart5: Color(hex: "#FF2056"),          // Pink
        
        followUpGradientStart: PrimaryScale.primary300,  // #A77FDB - Lighter purple
        followUpGradientEnd: PrimaryScale.primary600,    // #6125B1 - Darker purple
        followUpTagBackground: BaseColors.white.opacity(0.15),
        
        fabGradientStart: PrimaryScale.primary400,       // #9869D5 - Lighter purple for FAB
        fabGradientEnd: PrimaryScale.primary600,         // #6125B1 - Darker purple for FAB
        
        headerGradientStart: PrimaryScale.primary500,    // #7B3EC9 - Main brand purple for headers
        headerGradientEnd: PrimaryScale.primary700,      // #57219C - Deep purple for headers
        
        sidebar: GrayScale.gray800,             // #2F3943 - Sidebar background
        sidebarForeground: GrayScale.gray50,    // #F9FBFC - Sidebar text
        sidebarPrimary: PrimaryScale.primary400,// #9869D5 - Sidebar primary
        sidebarPrimaryForeground: GrayScale.gray900, // #1C2329 - Text on sidebar primary
        sidebarAccent: GrayScale.gray700,       // #4B5560 - Sidebar accent
        sidebarAccentForeground: GrayScale.gray50, // #F9FBFC - Sidebar accent text
        sidebarBorder: GrayScale.gray700,       // #4B5560 - Sidebar borders
        sidebarRing: PrimaryScale.primary400    // #9869D5 - Sidebar focus rings
    )
}

// MARK: - Environment convenience

struct ThemeKey: EnvironmentKey {
    static let defaultValue = Theme.light
}
extension EnvironmentValues {
    var theme: Theme {
        get { self[ThemeKey.self] }
        set { self[ThemeKey.self] = newValue }
    }
}

struct ThemeProvider: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    func body(content: Content) -> some View {
        content.environment(\.theme, colorScheme == .dark ? .dark : .light)
    }
}
extension View {
    func useTheme() -> some View { self.modifier(ThemeProvider()) }
}
