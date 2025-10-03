//
//  ContentView.swift
//  MeetMemento
//
//  Temporary playground that composes your existing screens + controls.
//  - Shows JournalView or InsightsView based on Bottom TabSwitcher
//  - Follows iOS spacing guidelines without custom transitions
//

import SwiftUI

// MARK: - Bottom tabs for TabSwitcher (uses your LabeledTab)
private enum AppTab: String, CaseIterable, Identifiable, Hashable, LabeledTab {
    case journal
    case insights

    var id: String { rawValue }
    var title: String {
        switch self {
        case .journal:  return "Journal"
        case .insights: return "Insights"
        }
    }
    var systemImage: String {
        switch self {
        case .journal:  return "book.closed.fill"
        case .insights: return "sparkles"
        }
    }
}

public struct ContentView: View {
    // Bottom tab selection drives which screen is shown
    @State private var bottomSelection: AppTab = .journal
    
    // Controls presentation of add entry sheet
    @State private var showAddEntry: Bool = false
    
    // Controls presentation of settings
    @State private var showSettings: Bool = false
    
    // Entry view model for managing journal entries (shared across views)
    @StateObject private var entryViewModel = EntryViewModel()

    @Environment(\.theme) private var theme
    @Environment(\.typography) private var type
    @EnvironmentObject var authViewModel: AuthViewModel

    // iOS spacing
    private let hPadding: CGFloat = 16

    public init() {}

    public var body: some View {
        NavigationStack {
            ZStack {
                theme.background.ignoresSafeArea()

                // Screen content driven by bottomSelection (no animation)
                Group {
                    switch bottomSelection {
                    case .journal:
                        JournalView(onSettingsTapped: { showSettings = true })
                            .environmentObject(entryViewModel) // Share the view model
                    case .insights:
                        InsightsView()
                    }
                }
            }
            // Bottom bar pinned to safe area
            .safeAreaInset(edge: .bottom, spacing: 0) {
                HStack(spacing: 12) {
                    // Centered segmented switch (drives which view is shown)
                    TabSwitcher<AppTab>(selection: $bottomSelection)
                        .useTypography()
                        .frame(width: 224)
                        .padding(.leading, hPadding)

                    Spacer(minLength: 8)

                    // Floating action button (56pt per HIG)
                    IconButton(systemImage: "plus") {
                        showAddEntry = true
                    }
                    .padding(.trailing, hPadding)
                    .accessibilityLabel("New Entry")
                }
                .padding(.vertical, 10) // comfortable clearance from home indicator
                .background(.clear)
            }
            .sheet(isPresented: $showAddEntry) {
                AddEntryView(
                    onSave: { text in
                        entryViewModel.createEntry(title: "", text: text)
                        showAddEntry = false
                    },
                    onCancel: { showAddEntry = false }
                )
                .useTheme()
                .useTypography()
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
                    .useTheme()
                    .useTypography()
            }
        }
        .useTheme()
        .useTypography()
    }
}

// MARK: - Previews
#Preview("Light • iPhone 15 Pro") {
    ContentView()
        .environmentObject(AuthViewModel())
        .preferredColorScheme(.light)
}

#Preview("Dark • iPhone 15 Pro") {
    ContentView()
        .environmentObject(AuthViewModel())
        .preferredColorScheme(.dark)
}
