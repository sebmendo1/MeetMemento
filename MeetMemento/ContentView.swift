//
//  ContentView.swift
//  MeetMemento
//
//  Main content view that displays the journal with top navigation tabs.
//  - Journal tab: displays user's journal entries
//  - Insights tab: displays AI-generated insights and themes
//

import SwiftUI

// MARK: - Navigation routes for journal entry editor
public enum EntryRoute: Hashable {
    case create
    case edit(Entry)
}

// MARK: - Navigation route for settings
public enum SettingsRoute: Hashable {
    case main
    case profile
    case appearance
    case about
}

public struct ContentView: View {
    // Navigation path for entry editor and settings
    @State private var navigationPath = NavigationPath()

    // Entry view model for managing journal entries (shared across views)
    @StateObject private var entryViewModel = EntryViewModel()

    @Environment(\.theme) private var theme
    @EnvironmentObject var authViewModel: AuthViewModel

    public init() {}

    public var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack {
                theme.background.ignoresSafeArea()

                // Main journal view with top navigation tabs
                JournalView(
                    onSettingsTapped: {
                        navigationPath.append(SettingsRoute.main)
                    },
                    onNavigateToEntry: { route in
                        navigationPath.append(route)
                    }
                )
                .environmentObject(entryViewModel)

                // Bottom navigation with FAB only
                BottomNavigation(
                    onJournalCreate: {
                        navigationPath.append(EntryRoute.create)
                    }
                )
            }
            .ignoresSafeArea(.all, edges: .bottom)
            .navigationDestination(for: EntryRoute.self) { route in
                switch route {
                case .create:
                    AddEntryView(state: .create) { title, text in
                        entryViewModel.createEntry(title: title, text: text)
                        navigationPath.removeLast()
                    }
                case .edit(let entry):
                    AddEntryView(state: .edit(entry)) { title, text in
                        var updated = entry
                        updated.title = title
                        updated.text = text
                        entryViewModel.updateEntry(updated)
                        navigationPath.removeLast()
                    }
                }
            }
            .navigationDestination(for: SettingsRoute.self) { route in
                switch route {
                case .main:
                    SettingsView()
                        .environmentObject(authViewModel)
                case .profile:
                    ProfileSettingsView()
                        .environmentObject(authViewModel)
                case .appearance:
                    AppearanceSettingsView()
                case .about:
                    AboutSettingsView()
                }
            }
        }
        .useTheme()
        .useTypography()
        // Note: Entry loading is deferred to JournalView for faster app launch
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
