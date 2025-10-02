//
//  AuthViewModel.swift
//  MeetMemento
//
//  Global authentication state manager
//

import Foundation
import SwiftUI
import Supabase

@MainActor
class AuthViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: Supabase.User?
    @Published var isLoading = true
    
    init() {
        // Check authentication state on init
        Task {
            await checkAuthState()
        }

        // Observe auth changes from Supabase (handles OAuth browser returns)
        AuthService.shared.observeAuthChanges { [weak self] _ in
            guard let self else { return }
            Task { await self.checkAuthState() }
        }
    }
    
    // MARK: - Auth State Management
    
    func checkAuthState() async {
        isLoading = true
        
        do {
            currentUser = try await SupabaseService.shared.getCurrentUser()
            isAuthenticated = currentUser != nil
            
            if let user = currentUser {
                AppLogger.log("User authenticated: \(user.email ?? "Unknown")", 
                             category: AppLogger.general)
            } else {
                AppLogger.log("No authenticated user", category: AppLogger.general)
            }
        } catch {
            AppLogger.log("Auth check error: \(error.localizedDescription)", 
                         category: AppLogger.general, 
                         type: .error)
            isAuthenticated = false
            currentUser = nil
        }
        
        isLoading = false
    }
    
    // MARK: - Sign In
    
    func signIn(email: String, password: String) async throws {
        try await SupabaseService.shared.signIn(email: email, password: password)
        await checkAuthState()
    }
    
    // MARK: - Sign Up
    
    func signUp(email: String, password: String) async throws {
        try await SupabaseService.shared.signUp(email: email, password: password)
        await checkAuthState()
        // Some Supabase auth configs require email confirmation and do not create a session.
        // If no session exists after sign-up, attempt a direct sign-in with the same credentials
        // to ensure redirect into the authenticated app for testing environments.
        if !isAuthenticated {
            do {
                try await signIn(email: email, password: password)
            } catch {
                // If this fails, the user likely needs to confirm email first.
                AppLogger.log("Post-signup sign-in failed: \(error.localizedDescription)",
                             category: AppLogger.general,
                             type: .error)
            }
        }
    }
    
    // MARK: - Sign Out
    
    func signOut() async {
        do {
            try await SupabaseService.shared.signOut()
            currentUser = nil
            isAuthenticated = false
            
            AppLogger.log("User signed out", category: AppLogger.general)
        } catch {
            AppLogger.log("Sign out error: \(error.localizedDescription)", 
                         category: AppLogger.general, 
                         type: .error)
        }
    }
}

