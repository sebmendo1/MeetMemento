import SwiftUI

// Typography system using custom fonts with safe fallbacks.
// Headings use Recoleta Black, body and UI text use Manrope.
// Sizes are aligned to the provided spec: 40, 32, 24, 20, 17, 15, 13, 11.

public struct Typography {
    // Spec sizes
    public let micro: CGFloat       // 11
    public let caption: CGFloat     // 13
    public let bodyS: CGFloat       // 15
    public let bodyL: CGFloat       // 17
    public let titleS: CGFloat      // 20
    public let titleM: CGFloat      // 24
    public let displayL: CGFloat    // 32
    public let displayXL: CGFloat   // 40

    public let weightNormal: Font.Weight
    public let weightMedium: Font.Weight

    // Font family names. Ensure these match the installed font PostScript names.
    // Using Recoleta Black (highest weight) for all heading sizes (titleS, titleM, displayL, displayXL)
    private let headingFontName = "Recoleta-Black"
    private let bodyFontName = "Manrope-Regular"
    private let bodyMediumFontName = "Manrope-Medium"
    private let bodyBoldFontName = "Manrope-Bold"

    public init(
        micro: CGFloat = 11,
        caption: CGFloat = 13,
        bodyS: CGFloat = 15,
        bodyL: CGFloat = 17,
        titleS: CGFloat = 20,
        titleM: CGFloat = 24,
        displayL: CGFloat = 32,
        displayXL: CGFloat = 40,
        weightNormal: Font.Weight = .regular,
        weightMedium: Font.Weight = .medium
    ) {
        self.micro = micro
        self.caption = caption
        self.bodyS = bodyS
        self.bodyL = bodyL
        self.titleS = titleS
        self.titleM = titleM
        self.displayL = displayL
        self.displayXL = displayXL
        self.weightNormal = weightNormal
        self.weightMedium = weightMedium
    }

    // Derived line spacing for ~1.5 line-height.
    private func lineSpacing(for size: CGFloat) -> CGFloat { max(0, size * 0.5) }

    // Helpers to safely use custom fonts with fallback to system.
    private func headingFont(size: CGFloat) -> Font {
        Font.custom(headingFontName, size: size, relativeTo: .title)
            .weight(.bold) // Ensure all Recoleta headings are bold
    }
    private func bodyFont(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        switch weight {
        case .bold:
            return Font.custom(bodyBoldFontName, size: size, relativeTo: .body)
        case .medium, .semibold:
            return Font.custom(bodyMediumFontName, size: size, relativeTo: .body)
        default:
            return Font.custom(bodyFontName, size: size, relativeTo: .body)
        }
    }

    // MARK: Fonts (semantic)
    public var h1: Font { headingFont(size: displayXL) }
    public var h2: Font { headingFont(size: displayL) }
    public var h3: Font { headingFont(size: titleM) }
    public var h4: Font { headingFont(size: titleS) }

    public var body: Font { bodyFont(size: bodyL, weight: weightNormal) }
    public var bodyBold: Font { bodyFont(size: bodyL, weight: .bold) }
    public var bodySmall: Font { bodyFont(size: bodyS, weight: weightNormal) }
    public var bodySmallBold: Font { bodyFont(size: bodyS, weight: .bold) }
    public var label: Font { bodyFont(size: caption, weight: weightMedium) }
    public var labelBold: Font { bodyFont(size: caption, weight: .bold) }
    public var button: Font { bodyFont(size: bodyL, weight: weightMedium) }
    public var input: Font { bodyFont(size: bodyL, weight: weightNormal) }
    public var captionText: Font { bodyFont(size: caption, weight: weightNormal) }
    public var captionBold: Font { bodyFont(size: caption, weight: .bold) }
    public var microText: Font { bodyFont(size: micro, weight: weightNormal) }
    public var microBold: Font { bodyFont(size: micro, weight: .bold) }

    // MARK: Modifiers to apply line-height-ish spacing
    public func lineSpacingModifier(for size: CGFloat) -> some ViewModifier {
        LineHeight(spacing: lineSpacing(for: size))
    }

    struct LineHeight: ViewModifier {
        let spacing: CGFloat
        func body(content: Content) -> some View {
            content.lineSpacing(spacing)
        }
    }
}

// MARK: - Environment + Defaults

private struct TypographyKey: EnvironmentKey {
    static let defaultValue = Typography()
}
public extension EnvironmentValues {
    var typography: Typography {
        get { self[TypographyKey.self] }
        set { self[TypographyKey.self] = newValue }
    }
}
public struct TypographyProvider: ViewModifier {
    let typography: Typography
    public init() {
        self.typography = Typography()
    }
    public func body(content: Content) -> some View {
        content.environment(\.typography, typography)
    }
}
public extension View {
    func useTypography() -> some View {
        modifier(TypographyProvider())
    }
}

// MARK: - Sugar

public extension View {
    // Heading styles
    func h1(_ env: EnvironmentValues) -> some View {
        self.font(env.typography.h1)
            .modifier(env.typography.lineSpacingModifier(for: env.typography.displayXL))
    }
    func h2(_ env: EnvironmentValues) -> some View {
        self.font(env.typography.h2)
            .modifier(env.typography.lineSpacingModifier(for: env.typography.displayL))
    }
    func h3(_ env: EnvironmentValues) -> some View {
        self.font(env.typography.h3)
            .modifier(env.typography.lineSpacingModifier(for: env.typography.titleM))
    }
    func h4(_ env: EnvironmentValues) -> some View {
        self.font(env.typography.h4)
            .modifier(env.typography.lineSpacingModifier(for: env.typography.titleS))
    }

    // Body / label / button / input
    func bodyText(_ env: EnvironmentValues) -> some View {
        self.font(env.typography.body)
            .modifier(env.typography.lineSpacingModifier(for: env.typography.bodyL))
    }
    func labelText(_ env: EnvironmentValues) -> some View {
        self.font(env.typography.label)
            .modifier(env.typography.lineSpacingModifier(for: env.typography.caption))
    }
    func buttonText(_ env: EnvironmentValues) -> some View {
        self.font(env.typography.button)
            .modifier(env.typography.lineSpacingModifier(for: env.typography.bodyL))
    }
    func inputText(_ env: EnvironmentValues) -> some View {
        self.font(env.typography.input)
            .modifier(env.typography.lineSpacingModifier(for: env.typography.bodyL))
    }
}

// MARK: - Header Gradient Extension

/// A view modifier that applies a gradient to header text using theme tokens
struct HeaderGradientModifier: ViewModifier {
    @Environment(\.theme) private var theme
    
    func body(content: Content) -> some View {
        content.foregroundStyle(
            LinearGradient(
                gradient: Gradient(colors: [theme.headerGradientStart, theme.headerGradientEnd]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
}

public extension View {
    /// Applies a gradient to header text (H1, H2, H3) using theme tokens
    func headerGradient() -> some View {
        self.modifier(HeaderGradientModifier())
    }
}
