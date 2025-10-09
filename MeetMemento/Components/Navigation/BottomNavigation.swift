//
//  BottomNavigation.swift
//  MeetMemento
//
//  Created by Sebastian Mendo on 12/15/24.
//

import SwiftUI

// MARK: - Bottom Navigation Component
/// A fixed bottom navigation component that combines TabSwitcher and FAB
/// - Positioned at the bottom with proper padding and spacing
/// - Handles tab switching and journal entry creation
public struct BottomNavigation<Tab: LabeledTab & CaseIterable & Hashable & Identifiable>: View
where Tab.AllCases: RandomAccessCollection {
    
    // MARK: - Properties
    @Binding public var tabSelection: Tab
    public let onJournalCreate: () -> Void
    
    @Environment(\.theme) private var theme
    
    // MARK: - Layout Constants
    private let horizontalPadding: CGFloat = 16
    private let bottomPadding: CGFloat = 32
    
    // MARK: - Initializer
    public init(
        tabSelection: Binding<Tab>,
        onJournalCreate: @escaping () -> Void
    ) {
        self._tabSelection = tabSelection
        self.onJournalCreate = onJournalCreate
    }
    
    // MARK: - Body
    public var body: some View {
        VStack {
            Spacer()
            
            HStack {
                // TabSwitcher - 16px from left, 32px from bottom
                TabSwitcher<Tab>(selection: $tabSelection)
                    .useTypography()
                    .frame(width: 224)
                    .padding(.leading, horizontalPadding)
                
                Spacer()
                
                // FAB - 16px from right, 32px from bottom
                IconButton(systemImage: "plus") {
                    onJournalCreate()
                }
                .padding(.trailing, horizontalPadding)
                .accessibilityLabel("New Entry")
            }
            .padding(.bottom, bottomPadding)
        }
        .allowsHitTesting(true)
    }
}

// MARK: - Preview Support
fileprivate enum PreviewTab: String, CaseIterable, Identifiable, Hashable, LabeledTab {
    case journal, insights
    var id: String { rawValue }
    var title: String { self == .journal ? "Journal" : "Insights" }
    var systemImage: String { self == .journal ? "book.closed.fill" : "sparkles" }
}

// MARK: - Previews
#Preview("Bottom Navigation • Light") {
    @Previewable @State var selectedTab: PreviewTab = .journal
    
    ZStack {
        Color.gray.opacity(0.1)
            .ignoresSafeArea()
        
        BottomNavigation(
            tabSelection: $selectedTab,
            onJournalCreate: {
                print("Create journal entry tapped")
            }
        )
    }
    .useTheme()
    .useTypography()
    .preferredColorScheme(.light)
}

#Preview("Bottom Navigation • Dark") {
    @Previewable @State var selectedTab: PreviewTab = .insights
    
    ZStack {
        Color.gray.opacity(0.1)
            .ignoresSafeArea()
        
        BottomNavigation(
            tabSelection: $selectedTab,
            onJournalCreate: {
                print("Create journal entry tapped")
            }
        )
    }
    .useTheme()
    .useTypography()
    .preferredColorScheme(.dark)
}
