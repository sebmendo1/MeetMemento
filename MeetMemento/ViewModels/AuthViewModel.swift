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
    @Published var isLoading = false
    private var authCheckInProgress = false  // NEW: Prevent duplicate checks
    
    init() {
        // NO async work in init - prevents SIGKILL crashes
    }
    
    /// Initialize auth state after UI renders
    func initializeAuth() async {
        await checkAuthState()
        await setupAuthObserver()
    }
    
    private func setupAuthObserver() async {
        // Observe auth changes from Supabase (handles OAuth browser returns)
        AuthService.shared.observeAuthChanges { [weak self] _ in
            guard let self else { return }
            Task { await self.checkAuthState() }
        }
    }
    
    // MARK: - Auth State Management
    
    func checkAuthState() async {
        // Prevent duplicate simultaneous checks
        guard !authCheckInProgress else { return }
        authCheckInProgress = true
        
        // Only show loading if we don't already know the auth state
        // This prevents UI flickering when re-checking after login
        let shouldShowLoading = !isAuthenticated && currentUser == nil
        if shouldShowLoading {
            isLoading = true
        }
        
        do {
            // Add timeout to prevent indefinite hanging
            currentUser = try await withTimeout(seconds: 2) {
                try await SupabaseService.shared.getCurrentUser()
            }
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
        authCheckInProgress = false
    }
    // MARK: - Timeout Helper
    
    private func withTimeout<T>(
        seconds: TimeInterval,
        operation: @escaping () async throws -> T
    ) async throws -> T {
        try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask {
                try await operation()
            }
            
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                throw TimeoutError()
            }
            
            let result = try await group.next()!
            group.cancelAll()
            return result
        }
    }
    
    private struct TimeoutError: Error {
        var localizedDescription: String {
            "Authentication check timed out"
        }
    }
    
    // MARK: - Sign In
    
    func signIn(email: String, password: String) async throws {
        try await SupabaseService.shared.signIn(email: email, password: password)
        
        // Optimistically set state without another network call
        // The auth observer will update if needed
        do {
            currentUser = try await SupabaseService.shared.getCurrentUser()
            isAuthenticated = currentUser != nil
        } catch {
            // Fallback to full check if quick fetch fails
            await checkAuthState()
        }
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

