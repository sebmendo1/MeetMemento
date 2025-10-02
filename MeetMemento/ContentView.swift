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
                        JournalView()
                    case .insights:
                        InsightsView()
                    }
                }
            }
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Sign Out") {
                            Task {
                                await authViewModel.signOut()
                            }
                        }
                        .foregroundStyle(.red)
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        NavigationLink {
                            SettingsView()
                                .useTheme()
                                .useTypography()
                                // AuthViewModel is already in environment from MeetMementoApp
                        } label: {
                            Image(systemName: "gear")
                                .foregroundStyle(theme.primary)
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
                    Button {
                        // create new entry
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(theme.primaryForeground)
                            .frame(width: 56, height: 56)
                            .background(
                                Circle()
                                    .fill(theme.primary)
                                    .shadow(color: .black.opacity(0.16), radius: 12, x: 0, y: 6)
                            )
                    }
                    .buttonStyle(.plain)
                    .padding(.trailing, hPadding)
                    .accessibilityLabel("New Entry")
                }
                .padding(.vertical, 10) // comfortable clearance from home indicator
                .background(.clear)
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
