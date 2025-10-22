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

// MARK: - Navigation routes for journal entry editor
public enum EntryRoute: Hashable {
    case create
    case edit(Entry)
    case followUp(String) // Legacy: hardcoded follow-up question
    case followUpGenerated(questionText: String, questionId: UUID) // NEW: Database-backed question
}

// MARK: - Navigation route for settings
public enum SettingsRoute: Hashable {
    case main
    case profile
    case appearance
    case about
}

public struct ContentView: View {
    // Bottom tab selection drives which screen is shown
    @State private var bottomSelection: AppTab = .journal

    // Navigation path for entry editor and settings
    @State private var navigationPath = NavigationPath()

    // Entry view model for managing journal entries (shared across views)
    @StateObject private var entryViewModel = EntryViewModel()

    // Show success view after follow-up question is answered
    @State private var showJournalCreated = false

    @Environment(\.theme) private var theme
    @Environment(\.typography) private var type
    @EnvironmentObject var authViewModel: AuthViewModel

    // iOS spacing
    private let hPadding: CGFloat = 16

    public init() {}

    public var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack {
                theme.background.ignoresSafeArea()

                // Screen content driven by bottomSelection (no animation)
                Group {
                    switch bottomSelection {
                    case .journal:
                        JournalView(
                            onSettingsTapped: {
                                navigationPath.append(SettingsRoute.main)
                            },
                            onNavigateToEntry: { route in
                                navigationPath.append(route)
                            }
                        )
                        .environmentObject(entryViewModel) // Share the view model
                    case .insights:
                        InsightsView()
                            .environmentObject(entryViewModel) // Share the view model
                    }
                }
                
                // Bottom navigation with TabSwitcher and FAB
                BottomNavigation(
                    tabSelection: $bottomSelection,
                    onJournalCreate: {
                        navigationPath.append(EntryRoute.create)
                    }
                )
            }
            .ignoresSafeArea(.all, edges: .bottom)
            .navigationDestination(for: EntryRoute.self) { route in
                switch route {
                case .create:
                    AddEntryView(state: .create) { title, text, _ in
                        entryViewModel.createEntry(title: title, text: text)
                        navigationPath.removeLast()
                    }
                case .edit(let entry):
                    AddEntryView(state: .edit(entry)) { title, text, _ in
                        var updated = entry
                        updated.title = title
                        updated.text = text
                        entryViewModel.updateEntry(updated)
                        navigationPath.removeLast()
                    }
                case .followUp(let question):
                    // Legacy: Hardcoded question (no database tracking)
                    AddEntryView(state: .followUp(questionText: question, questionId: nil)) { title, text, questionId in
                        entryViewModel.createFollowUpEntry(
                            title: title,
                            text: text,
                            questionId: questionId,
                            question: question
                        )
                        // Show success screen instead of immediately going back
                        showJournalCreated = true
                    }
                case .followUpGenerated(let questionText, let questionId):
                    // NEW: Database-backed question with completion tracking
                    AddEntryView(state: .followUp(questionText: questionText, questionId: questionId)) { title, text, qId in
                        print("🟠🟠🟠 SAVE CALLBACK RECEIVED! 🟠🟠🟠")
                        print("   Title: '\(title)'")
                        print("   Text: \(text.count) chars")
                        print("   qId (from callback): \(qId?.uuidString ?? "NIL")")
                        print("   questionId (captured): \(questionId.uuidString)")

                        entryViewModel.createFollowUpEntry(
                            title: title,
                            text: text,
                            questionId: qId,  // Pass question ID from callback parameter
                            question: questionText
                        )

                        print("   createFollowUpEntry() call completed")
                        // Show success screen instead of immediately going back
                        showJournalCreated = true
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
        .fullScreenCover(isPresented: $showJournalCreated) {
            JournalCreatedView {
                // Dismiss the success view and navigate back to journal
                showJournalCreated = false
                navigationPath.removeLast()
            }
            .useTheme()
            .useTypography()
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
