//
//  AuthViewModel.swift
//  MeetMemento
//
//  Global authentication state manager
//

import Foundation
import SwiftUI
import Supabase

// MARK: - Authentication State

/// Combined authentication state that prevents race conditions
/// between isAuthenticated and hasCompletedOnboarding updates
public enum AuthState: Equatable {
    case unauthenticated
    case authenticated(needsOnboarding: Bool)

    var isAuthenticated: Bool {
        switch self {
        case .unauthenticated:
            return false
        case .authenticated:
            return true
        }
    }

    var needsOnboarding: Bool {
        switch self {
        case .unauthenticated:
            return false
        case .authenticated(let needsOnboarding):
            return needsOnboarding
        }
    }
}

@MainActor
class AuthViewModel: ObservableObject {
    // Combined authentication state (atomic updates)
    @Published var authState: AuthState = .unauthenticated

    // Legacy properties for backwards compatibility
    @Published var isAuthenticated = false
    @Published var currentUser: Supabase.User?
    @Published var isLoading = false
    @Published var hasCompletedOnboarding = false  // Changed default to false for safety
    private var authCheckInProgress = false

    // Passwordless auth state
    @Published var otpSent: Bool = false
    @Published var userEmail: String = ""

    // Temporary storage for Apple-provided names (pending profile save)
    @Published var pendingFirstName: String? = nil
    @Published var pendingLastName: String? = nil

    init() {
        // NO async work in init - prevents SIGKILL crashes
    }

    // MARK: - Pending Profile Management

    /// Store Apple-provided names temporarily until user confirms in CreateAccountView
    func storePendingAppleProfile(firstName: String?, lastName: String?) {
        pendingFirstName = firstName
        pendingLastName = lastName
        AppLogger.log("✅ Stored pending Apple profile: \(firstName ?? "") \(lastName ?? "")",
                     category: AppLogger.general)
    }

    /// Clear pending profile data after successful save
    func clearPendingProfile() {
        pendingFirstName = nil
        pendingLastName = nil
        AppLogger.log("✅ Cleared pending profile data", category: AppLogger.general)
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
        let shouldShowLoading = !authState.isAuthenticated && currentUser == nil
        if shouldShowLoading {
            isLoading = true
        }

        do {
            // Add timeout to prevent indefinite hanging
            currentUser = try await withTimeout(seconds: 2) {
                try await SupabaseService.shared.getCurrentUser()
            }

            if let user = currentUser {
                // User is authenticated - check onboarding status atomically
                let needsOnboarding: Bool
                do {
                    let onboardingComplete = try await SupabaseService.shared.hasCompletedOnboarding()
                    needsOnboarding = !onboardingComplete
                    AppLogger.log("User authenticated: \(user.email ?? "Unknown"), needsOnboarding: \(needsOnboarding)",
                                 category: AppLogger.general)
                } catch {
                    // On error checking onboarding, assume complete to avoid blocking user
                    needsOnboarding = false
                    AppLogger.log("Error checking onboarding, assuming complete: \(error.localizedDescription)",
                                 category: AppLogger.general,
                                 type: .error)
                }

                // Update ALL state atomically
                authState = .authenticated(needsOnboarding: needsOnboarding)
                isAuthenticated = true
                hasCompletedOnboarding = !needsOnboarding

            } else {
                AppLogger.log("No authenticated user", category: AppLogger.general)
                authState = .unauthenticated
                isAuthenticated = false
                hasCompletedOnboarding = false
            }
        } catch {
            AppLogger.log("Auth check error: \(error.localizedDescription)",
                         category: AppLogger.general,
                         type: .error)
            authState = .unauthenticated
            isAuthenticated = false
            currentUser = nil
            hasCompletedOnboarding = false
        }

        isLoading = false
        authCheckInProgress = false
    }

    /// Check if user has completed onboarding (legacy - now handled atomically in checkAuthState)
    func checkOnboardingStatus() async {
        guard authState.isAuthenticated else {
            authState = .unauthenticated
            hasCompletedOnboarding = false
            return
        }

        do {
            let onboardingComplete = try await SupabaseService.shared.hasCompletedOnboarding()
            let needsOnboarding = !onboardingComplete

            // Update state atomically
            authState = .authenticated(needsOnboarding: needsOnboarding)
            hasCompletedOnboarding = onboardingComplete

            AppLogger.log("Onboarding status updated: complete=\(onboardingComplete)", category: AppLogger.general)
        } catch {
            AppLogger.log("Error checking onboarding status: \(error.localizedDescription)",
                         category: AppLogger.general,
                         type: .error)
            // On error, assume onboarding is complete to avoid blocking user
            authState = .authenticated(needsOnboarding: false)
            hasCompletedOnboarding = true
        }
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

        // IMPORTANT: Check auth state which now atomically updates both
        // isAuthenticated AND hasCompletedOnboarding to prevent race conditions
        await checkAuthState()

        AppLogger.log("OTP verified - authState: \(authState)", category: AppLogger.general)
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

    // MARK: - Account Deletion

    /// Deletes the user's account and all associated data
    /// WARNING: This action is irreversible
    func deleteAccount() async throws {
        try await SupabaseService.shared.deleteAccount()

        // Sign out after successful deletion
        currentUser = nil
        isAuthenticated = false
        hasCompletedOnboarding = true

        AppLogger.log("User account deleted and signed out", category: AppLogger.general)
    }
}

