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
                    .font(type.h3)                 // match tab label size
                    .fontWeight(.semibold)
                    .foregroundStyle(theme.primary)
                    .padding(.horizontal, hitPadding)
                    .contentShape(Rectangle())
                    .accessibilityAddTraits(.isHeader)

            case .singleSelected:
                // Styled exactly like a selected tab (no scale so height stays fixed)
                Text("Your Insights")
                    .font(type.h3)
                    .fontWeight(.semibold)
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
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            // Update selection without animation wrapper to let TabView handle it
            selection = tab
            print("✅ Selection updated to: \(selection.title)")
        } label: {
            Text(tab.title)
                .font(type.h3)
                .fontWeight(isSelected ? .semibold : .medium)
                .foregroundStyle(theme.primary)
                .opacity(isSelected ? 1 : 0.55)
                .padding(.horizontal, hitPadding)
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
