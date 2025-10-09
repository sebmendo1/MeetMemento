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

    /// Light theme (from `:root`)
    static let light = Theme(
        background: Color(hex: "#FFFFFF"),
        foreground: Color(hex: "#0A0A0A"),               // oklch(0.145 0 0)
        card: Color(hex: "#FFFFFF"),
        cardForeground: Color(hex: "#0A0A0A"),           // oklch(0.145 0 0)
        popover: Color(hex: "#FFFFFF"),                  // oklch(1 0 0)
        popoverForeground: Color(hex: "#0A0A0A"),        // oklch(0.145 0 0)
        primary: Color(hex: "#8A38F5"),
        primaryForeground: Color(hex: "#F0F2F5"),        // oklch(1 0 0)
        secondary: Color(hex: "#ECEEF2"),                // oklch(0.95 0.0058 264.53)
        secondaryForeground: Color(hex: "#ffffff"),
        muted: Color(hex: "#ECECF0"),
        mutedForeground: Color(hex: "#717182"),
        accent: Color(hex: "#8A38F5"),
        accentForeground: Color(hex: "#030213"),
        destructive: Color(hex: "#D4183D"),
        destructiveForeground: Color(hex: "#FFFFFF"),
        border: Color.black.opacity(0.1),                // rgba(0,0,0,0.1)
        input: .clear,                                   // transparent
        inputBackground: Color(hex: "#F3F3F5"),
        switchBackground: Color(hex: "#CBCED4"),
        ring: Color(hex: "#A1A1A1"),                     // oklch(0.708 0 0)

        chart1: Color(hex: "#F54900"),                   // oklch(0.646 0.222 41.116)
        chart2: Color(hex: "#009689"),                   // oklch(0.6 0.118 184.704)
        chart3: Color(hex: "#104E64"),                   // oklch(0.398 0.07 227.392)
        chart4: Color(hex: "#FFB900"),                   // oklch(0.828 0.189 84.429)
        chart5: Color(hex: "#FE9A00"),                   // oklch(0.769 0.188 70.08)
        
        followUpGradientStart: Color(hex: "#8A2BE2"),    // Blue Violet
        followUpGradientEnd: Color(hex: "#4B0082"),      // Indigo
        followUpTagBackground: Color.white.opacity(0.2),

        sidebar: Color(hex: "#FAFAFA"),                  // oklch(0.985 0 0)
        sidebarForeground: Color(hex: "#0A0A0A"),        // oklch(0.145 0 0)
        sidebarPrimary: Color(hex: "#030213"),
        sidebarPrimaryForeground: Color(hex: "#FAFAFA"), // oklch(0.985 0 0)
        sidebarAccent: Color(hex: "#F5F5F5"),            // oklch(0.97 0 0)
        sidebarAccentForeground: Color(hex: "#171717"),  // oklch(0.205 0 0)
        sidebarBorder: Color(hex: "#E5E5E5"),            // oklch(0.922 0 0)
        sidebarRing: Color(hex: "#A1A1A1")               // oklch(0.708 0 0)
    )

    /// Dark theme (from `.dark`)
    static let dark = Theme(
        background: Color(hex: "#0A0A0A"),               // oklch(0.145 0 0)
        foreground: Color(hex: "#FAFAFA"),               // oklch(0.985 0 0)
        card: Color(hex: "#0A0A0A"),
        cardForeground: Color(hex: "#FAFAFA"),
        popover: Color(hex: "#0A0A0A"),
        popoverForeground: Color(hex: "#FAFAFA"),
        primary: Color(hex: "#FAFAFA"),                  // oklch(0.985 0 0)
        primaryForeground: Color(hex: "#171717"),        // oklch(0.205 0 0)
        secondary: Color(hex: "#262626"),                // oklch(0.269 0 0)
        secondaryForeground: Color(hex: "#FAFAFA"),
        muted: Color(hex: "#262626"),
        mutedForeground: Color(hex: "#A1A1A1"),          // oklch(0.708 0 0)
        accent: Color(hex: "#262626"),
        accentForeground: Color(hex: "#FAFAFA"),
        destructive: Color(hex: "#82181A"),              // oklch(0.396 0.141 25.723)
        destructiveForeground: Color(hex: "#FB2C36"),    // oklch(0.637 0.237 25.331)
        border: Color(hex: "#262626"),
        input: Color(hex: "#262626"),
        inputBackground: Color(hex: "#262626"),          // not defined in dark; align to input
        switchBackground: Color(hex: "#CBCED4"),         // keep same as light
        ring: Color(hex: "#525252"),                     // oklch(0.439 0 0)

        chart1: Color(hex: "#1447E6"),                   // oklch(0.488 0.243 264.376)
        chart2: Color(hex: "#00BC7D"),                   // oklch(0.696 0.17 162.48)
        chart3: Color(hex: "#FE9A00"),                   // oklch(0.769 0.188 70.08)
        chart4: Color(hex: "#AD46FF"),                   // oklch(0.627 0.265 303.9)
        chart5: Color(hex: "#FF2056"),                   // oklch(0.645 0.246 16.439)
        
        followUpGradientStart: Color(hex: "#8A2BE2"),    // Blue Violet
        followUpGradientEnd: Color(hex: "#4B0082"),      // Indigo
        followUpTagBackground: Color.white.opacity(0.2),

        sidebar: Color(hex: "#171717"),                  // oklch(0.205 0 0)
        sidebarForeground: Color(hex: "#FAFAFA"),
        sidebarPrimary: Color(hex: "#1447E6"),           // oklch(0.488 0.243 264.376)
        sidebarPrimaryForeground: Color(hex: "#FAFAFA"),
        sidebarAccent: Color(hex: "#262626"),
        sidebarAccentForeground: Color(hex: "#FAFAFA"),
        sidebarBorder: Color(hex: "#262626"),
        sidebarRing: Color(hex: "#525252")
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
