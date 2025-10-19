//
//  TopNav.swift (fixed + animated preview)
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
    private let navHeight: CGFloat = 44
    private let labelSpacing: CGFloat = 12
    private let hitPadding: CGFloat = 4

    @Environment(\.theme) private var theme
    @Environment(\.typography) private var type
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
                Text("Your Insights")
                    .font(type.bodyBold)
                    .foregroundStyle(theme.primary)
                    .padding(.horizontal, hitPadding)
                    .contentShape(Rectangle())
                    .accessibilityAddTraits(.isHeader)

            case .singleSelected:
                Text("Your Insights")
                    .font(type.bodyBold)
                    .foregroundStyle(theme.primary)
                    .padding(.horizontal, hitPadding)
                    .contentShape(Rectangle())
                    .accessibilityAddTraits([.isHeader, .isSelected])
            }
        }
        .frame(height: navHeight, alignment: .center)
        .background(.clear)
        // ✅ Drive all geometry transitions off selection
        .animation(.spring(response: 0.32, dampingFraction: 0.85, blendDuration: 0.12), value: selection)
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
            guard !isSelected else { return }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            // ✅ Update selection WITHOUT animation wrapper
            // This allows TabView to handle page transitions properly
            // The pill animation is handled by .animation() modifier on the view (line 73)
            selection = tab
        } label: {
            Text(tab.title)
                .font(type.bodyBold)
                .foregroundStyle(theme.primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    ZStack {
                        if isSelected {
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .fill(theme.accent.opacity(0.12))
                                .matchedGeometryEffect(id: "tabPill", in: tabAnimation)
                        }
                    }
                )
                .frame(maxHeight: .infinity)
                .contentShape(Rectangle())
                .accessibilityAddTraits(isSelected ? [.isHeader, .isSelected] : [.isHeader])
        }
        .buttonStyle(.plain)
        .zIndex(isSelected ? 1 : 0) // ✅ ensure selected pill stays visually on top
    }
}

#Preview {
    VStack(spacing: 24) {
        // Simulated environment
        TopNav(variant: .tabs, selection: .constant(.yourEntries))
            .environment(\.theme, Theme.light)
            .environment(\.typography, Typography())
            .previewDisplayName("Static (Your Entries)")

        TopNavPreviewInteractive()
            .previewDisplayName("Interactive Switch")
    }
    .padding()
    .background(Color(.systemBackground))
}

// MARK: - Interactive Preview
private struct TopNavPreviewInteractive: View {
    @State private var selection: JournalTopTab = .yourEntries

    var body: some View {
        VStack(spacing: 12) {
            TopNav(variant: .tabs, selection: $selection)
                .environment(\.theme, Theme.light)
                .environment(\.typography, Typography())
                .frame(width: 320)

            Text("Selected: \(selection.title)")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(radius: 1)
    }
}
