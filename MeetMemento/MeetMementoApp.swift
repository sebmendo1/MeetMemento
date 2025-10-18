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
    
    var body: some Scene {
        WindowGroup {
            Group {
                if authViewModel.isAuthenticated && authViewModel.hasCompletedOnboarding {
                    // Fully onboarded user - show main app
                    ContentView()
                        .environmentObject(authViewModel)
                } else {
                    // Not authenticated OR incomplete onboarding - show WelcomeView
                    // WelcomeView will handle routing to correct step (Phase 2)
                    WelcomeView()
                        .useTheme()
                        .useTypography()
                        .environmentObject(authViewModel)
                }
            }
            .task {
                // Initialize auth AFTER UI renders to prevent SIGKILL crashes
                await authViewModel.initializeAuth()

                // Check onboarding status AFTER auth, with delay to ensure UI renders
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 second delay
                await authViewModel.checkOnboardingStatus()
            }
            .onOpenURL { url in
                Task { try? await AuthService.shared.handleRedirectURL(url) }
            }
        }
    }
}
