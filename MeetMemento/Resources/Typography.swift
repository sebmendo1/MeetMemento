import SwiftUI

// Semantic typography, matching your CSS block
// h1..h4, p, label, button, input
// Line-height ~1.5 is approximated via .lineSpacing.

public struct Typography {
    public let base: CGFloat      // corresponds to var(--text-base) ~ 16
    public let lg: CGFloat        // var(--text-lg)
    public let xl: CGFloat        // var(--text-xl)
    public let xxl: CGFloat       // var(--text-2xl)
    public let weightNormal: Font.Weight
    public let weightMedium: Font.Weight

    public init(base: CGFloat = 16,
                lg: CGFloat = 18,
                xl: CGFloat = 20,
                xxl: CGFloat = 24,
                weightNormal: Font.Weight = .regular,
                weightMedium: Font.Weight = .medium) {
        self.base = base
        self.lg = lg
        self.xl = xl
        self.xxl = xxl
        self.weightNormal = weightNormal
        self.weightMedium = weightMedium
    }

    // Derived line spacing for ~1.5 line-height.
    private func lineSpacing(for size: CGFloat) -> CGFloat { max(0, size * 0.5) }

    // MARK: Fonts
    public var h1: Font { .system(size: xxl, weight: weightMedium) }
    public var h2: Font { .system(size: xl,  weight: weightMedium) }
    public var h3: Font { .system(size: lg,  weight: weightMedium) }
    public var h4: Font { .system(size: base,weight: weightMedium) }
    public var body: Font { .system(size: base, weight: weightNormal) }
    public var label: Font { .system(size: base, weight: weightMedium) }
    public var button: Font { .system(size: base, weight: weightMedium) }
    public var input: Font { .system(size: base, weight: weightNormal) }

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
    public init(base: CGFloat = 16, lg: CGFloat = 18, xl: CGFloat = 20, xxl: CGFloat = 24) {
        self.typography = Typography(base: base, lg: lg, xl: xl, xxl: xxl)
    }
    public func body(content: Content) -> some View {
        content.environment(\.typography, typography)
    }
}
public extension View {
    func useTypography(base: CGFloat = 16, lg: CGFloat = 18, xl: CGFloat = 20, xxl: CGFloat = 24) -> some View {
        modifier(TypographyProvider(base: base, lg: lg, xl: xl, xxl: xxl))
    }
}

// MARK: - Sugar

public extension View {
    // Heading styles
    func h1(_ env: EnvironmentValues) -> some View {
        self.font(env.typography.h1)
            .modifier(env.typography.lineSpacingModifier(for: env.typography.xxl))
    }
    func h2(_ env: EnvironmentValues) -> some View {
        self.font(env.typography.h2)
            .modifier(env.typography.lineSpacingModifier(for: env.typography.xl))
    }
    func h3(_ env: EnvironmentValues) -> some View {
        self.font(env.typography.h3)
            .modifier(env.typography.lineSpacingModifier(for: env.typography.lg))
    }
    func h4(_ env: EnvironmentValues) -> some View {
        self.font(env.typography.h4)
            .modifier(env.typography.lineSpacingModifier(for: env.typography.base))
    }

    // Body / label / button / input
    func bodyText(_ env: EnvironmentValues) -> some View {
        self.font(env.typography.body)
            .modifier(env.typography.lineSpacingModifier(for: env.typography.base))
    }
    func labelText(_ env: EnvironmentValues) -> some View {
        self.font(env.typography.label)
            .modifier(env.typography.lineSpacingModifier(for: env.typography.base))
    }
    func buttonText(_ env: EnvironmentValues) -> some View {
        self.font(env.typography.button)
            .modifier(env.typography.lineSpacingModifier(for: env.typography.base))
    }
    func inputText(_ env: EnvironmentValues) -> some View {
        self.font(env.typography.input)
            .modifier(env.typography.lineSpacingModifier(for: env.typography.base))
    }
}
