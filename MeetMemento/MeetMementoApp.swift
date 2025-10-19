//
//  MeetMementoApp.swift
//  MeetMemento
//
//  Created by Sebastian Mendo on 9/30/25.
//

import SwiftUI

@main
struct MeetMementoApp: App {
    @StateObject private var authViewModel = AuthViewModel()

    init() {
        print("🔴 MeetMementoApp init() called")
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if authViewModel.isAuthenticated && authViewModel.hasCompletedOnboarding {
                    // Fully onboarded user - show main app
                    ContentView()
                        .environmentObject(authViewModel)
                        .onAppear {
                            print("🔴 ContentView appeared")
                        }
                } else {
                    // Not authenticated OR incomplete onboarding - show WelcomeView
                    // WelcomeView will handle routing to correct step (Phase 2)
                    WelcomeView()
                        .useTheme()
                        .useTypography()
                        .environmentObject(authViewModel)
                        .onAppear {
                            print("🔴 WelcomeView appeared")
                            print("🔴 Auth state: isAuthenticated=\(authViewModel.isAuthenticated), hasCompletedOnboarding=\(authViewModel.hasCompletedOnboarding)")
                        }
                }
            }
            .task {
                print("🔴 .task block started")
                // Initialize auth AFTER UI renders to prevent SIGKILL crashes
                // Note: checkAuthState() already checks onboarding status atomically,
                // no need for separate checkOnboardingStatus() call
                await authViewModel.initializeAuth()
                print("🔴 .task block completed")
            }
            .onOpenURL { url in
                Task { try? await AuthService.shared.handleRedirectURL(url) }
            }
        }
    }
}
