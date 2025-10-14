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

    // Passwordless auth state
    @Published var otpSent: Bool = false
    @Published var userEmail: String = ""

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

    // MARK: - Passwordless Authentication (OTP)

    /// Step 1: Send OTP to email
    func sendOTP(email: String) async throws {
        userEmail = email
        try await SupabaseService.shared.signInWithOTP(email: email)
        otpSent = true
        AppLogger.log("OTP sent to \(email)", category: AppLogger.general)
    }

    /// Step 2: Verify OTP and sign in
    func verifyOTP(code: String) async throws {
        try await SupabaseService.shared.verifyOTP(
            email: userEmail,
            token: code
        )

        // Check auth state after verification
        await checkAuthState()

        AppLogger.log("OTP verified, authenticated: \(isAuthenticated)", category: AppLogger.general)
    }

    /// Check if user needs to complete profile (for new users)
    func checkIfUserNeedsOnboarding() async throws -> Bool {
        guard let user = currentUser else { return true }

        // Check if user has metadata (name, etc.)
        let metadata = user.userMetadata
        let hasFirstName = metadata["first_name"] != nil
        let hasLastName = metadata["last_name"] != nil

        return !(hasFirstName && hasLastName)
    }

    /// Update user profile metadata
    func updateProfile(firstName: String, lastName: String) async throws {
        try await SupabaseService.shared.updateUserMetadata(
            firstName: firstName,
            lastName: lastName
        )

        // Refresh user data
        await checkAuthState()

        AppLogger.log("Profile updated for user", category: AppLogger.general)
    }
}

