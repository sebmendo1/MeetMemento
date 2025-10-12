//
//  TopNav.swift (height-normalized)
//  MeetMemento
//

import SwiftUI

public enum TopNavVariant {
    case tabs
    case single
    case singleSelected
}

public enum JournalTopTab: String, CaseIterable, Identifiable, Hashable {
    case yourEntries
    case digDeeper

    public var id: String { rawValue }
    public var title: String {
        switch self {
        case .yourEntries: return "Your Entries"
        case .digDeeper:   return "Dig deeper"
        }
    }
}

public struct TopNav: View {
    public let variant: TopNavVariant
    @Binding public var selection: JournalTopTab

    // Consistent layout
    private let navHeight: CGFloat = 44     // ✅ same height for all variants
    private let labelSpacing: CGFloat = 12
    private let hitPadding: CGFloat = 4

    @Environment(\.theme) private var theme
    @Environment(\.typography) private var type
    
    // For smooth liquid glass animation
    @Namespace private var tabAnimation

    public init(variant: TopNavVariant, selection: Binding<JournalTopTab>) {
        self.variant = variant
        self._selection = selection
    }

    public var body: some View {
        HStack(spacing: labelSpacing) {
            switch variant {
            case .tabs:
                tabsContent
                    .accessibilityElement(children: .contain)
                    .accessibilityLabel("Top Navigation Tabs")

            case .single:
                // Plain header style but height matches selected tab
                Text("Your Insights")
                    .font(type.bodyBold)            // match pill tab font
                    .foregroundStyle(theme.primary)
                    .padding(.horizontal, hitPadding)
                    .contentShape(Rectangle())
                    .accessibilityAddTraits(.isHeader)

            case .singleSelected:
                // Styled exactly like a selected tab (no scale so height stays fixed)
                Text("Your Insights")
                    .font(type.bodyBold)            // match pill tab font
                    .foregroundStyle(theme.primary)
                    .padding(.horizontal, hitPadding)
                    .contentShape(Rectangle())
                    .accessibilityAddTraits([.isHeader, .isSelected])
            }
        }
        .frame(height: navHeight, alignment: .center) // ✅ locks height across states
        .background(.clear)
    }

    // MARK: - Tabs Content
    private var tabsContent: some View {
        HStack(spacing: labelSpacing) {
            tabLabel(.yourEntries)
            tabLabel(.digDeeper)
        }
    }

    @ViewBuilder
    private func tabLabel(_ tab: JournalTopTab) -> some View {
        let isSelected = (tab == selection)

        Button {
            guard !isSelected else { 
                print("🚫 Tab already selected: \(tab.title)")
                return 
            }
            print("👆 Tab clicked: \(tab.title), current selection: \(selection.title)")
            print("   Tab enum value: \(tab)")
            print("   Current selection enum: \(selection)")
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            
            // Explicitly animate the selection change to trigger TabView transition
            withAnimation(.spring(response: 0.4, dampingFraction: 0.75, blendDuration: 0)) {
                print("   🔄 Setting selection to: \(tab)")
                selection = tab
                print("   ✅ Selection is now: \(selection)")
            }
            
            // Double-check after animation block
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                print("   ⏱️ After 0.1s, selection is: \(selection)")
            }
        } label: {
            // Tab label text
            Text(tab.title)
                .font(type.bodyBold) // Use Manrope bold for tabs
                .foregroundStyle(theme.primary) // Same color for both states
                .padding(.horizontal, 16) // More padding for pill shape
                .padding(.vertical, 8)
                .background(
                    // Animated pill background using matchedGeometryEffect
                    ZStack {
                        if isSelected {
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .fill(theme.accent.opacity(0.12))
                                .matchedGeometryEffect(id: "tabPill", in: tabAnimation)
                        }
                    }
                )
                .frame(maxHeight: .infinity) // vertically centers within 44pt
                .contentShape(Rectangle())
                .accessibilityAddTraits(isSelected ? [.isHeader, .isSelected] : [.isHeader])
        }
        .buttonStyle(.plain)
    }
}

// MARK: - PreviewProvider (shows all states with identical height)
struct TopNav_Previews: PreviewProvider {
    private struct TabsWrapper: View {
        @State private var selection: JournalTopTab = .yourEntries
        var body: some View {
            VStack(alignment: .leading, spacing: 12) {
                TopNav(variant: .tabs, selection: $selection)
                    .useTheme()
                    .useTypography()
                    .frame(width: 320)

                Text("Selected: \(selection.title)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(Theme.light.background)
        }
    }

    private struct SingleVariantsWrapper: View {
        var body: some View {
            VStack(spacing: 12) {
                TopNav(variant: .single, selection: .constant(.yourEntries))
                    .useTheme()
                    .useTypography()
                    .frame(width: 320)

                TopNav(variant: .singleSelected, selection: .constant(.yourEntries))
                    .useTheme()
                    .useTypography()
                    .frame(width: 320)
            }
            .padding()
            .background(Theme.light.background)
        }
    }

    static var previews: some View {
        Group {
            TabsWrapper()
                .previewDisplayName("Tabs • Light")
                .preferredColorScheme(.light)
                .previewLayout(.sizeThatFits)

            TabsWrapper()
                .previewDisplayName("Tabs • Dark")
                .preferredColorScheme(.dark)
                .previewLayout(.sizeThatFits)

            SingleVariantsWrapper()
                .previewDisplayName("Single + SingleSelected • Light")
                .preferredColorScheme(.light)
                .previewLayout(.sizeThatFits)

            SingleVariantsWrapper()
                .previewDisplayName("Single + SingleSelected • Dark")
                .preferredColorScheme(.dark)
                .previewLayout(.sizeThatFits)
        }
    }
}
