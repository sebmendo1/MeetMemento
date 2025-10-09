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
                if authViewModel.isAuthenticated {
                    // User is authenticated - show main app
                    ContentView()
                        .environmentObject(authViewModel)
                } else {
                    // User not authenticated - show welcome/login
                    WelcomeView(onNext: {
                        // Optional: handle "Get Started" if you want onboarding
                    })
                    .useTheme()
                    .useTypography()
                    .environmentObject(authViewModel)
                }
            }
            .task {
                // Initialize auth AFTER UI renders to prevent SIGKILL crashes
                await authViewModel.initializeAuth()
            }
            .onOpenURL { url in
                Task { try? await AuthService.shared.handleRedirectURL(url) }
            }
        }
    }
}
