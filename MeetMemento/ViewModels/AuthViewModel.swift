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

    // Auth check guard - uses Swift actor for async-safe locking
    private let checkGuard = AuthCheckGuard()

    // Passwordless auth state
    @Published var otpSent: Bool = false
    @Published var userEmail: String = ""

    // Temporary storage for Apple-provided names (pending profile save)
    @Published var pendingFirstName: String? = nil
    @Published var pendingLastName: String? = nil

    // UserDefaults keys for caching auth state
    private let cachedAuthStateKey = "com.meetmemento.cachedAuthState"
    private let cachedOnboardingKey = "com.meetmemento.cachedOnboarding"

    init() {
        // NO async work in init - prevents SIGKILL crashes
        #if DEBUG
        print("🟢 AuthViewModel init() called")
        #endif

        // Immediately restore cached auth state for instant UI update
        restoreCachedAuthState()
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

    // MARK: - Auth State Caching

    /// Restores cached auth state from UserDefaults for instant UI update
    /// This runs synchronously in init() to avoid showing wrong views
    private func restoreCachedAuthState() {
        let isAuthenticatedCached = UserDefaults.standard.bool(forKey: cachedAuthStateKey)
        let hasOnboardingCached = UserDefaults.standard.bool(forKey: cachedOnboardingKey)

        // Only restore if user was authenticated
        if isAuthenticatedCached {
            let needsOnboarding = !hasOnboardingCached

            // Update state immediately (no await needed - we're in init)
            authState = .authenticated(needsOnboarding: needsOnboarding)
            isAuthenticated = true
            hasCompletedOnboarding = hasOnboardingCached

            #if DEBUG
            print("🟢 Restored cached auth state: authenticated=\(isAuthenticatedCached), onboarding=\(hasOnboardingCached)")
            #endif
            AppLogger.log("✅ Restored cached auth state - skipping loading screen", category: AppLogger.general)
        } else {
            #if DEBUG
            print("🟢 No cached auth state - user not authenticated")
            #endif
        }
    }

    /// Saves current auth state to UserDefaults for next app launch
    private func cacheAuthState() {
        UserDefaults.standard.set(isAuthenticated, forKey: cachedAuthStateKey)
        UserDefaults.standard.set(hasCompletedOnboarding, forKey: cachedOnboardingKey)
        #if DEBUG
        print("🟢 Cached auth state: authenticated=\(isAuthenticated), onboarding=\(hasCompletedOnboarding)")
        #endif
    }

    /// Clears cached auth state (call on sign out)
    private func clearCachedAuthState() {
        UserDefaults.standard.removeObject(forKey: cachedAuthStateKey)
        UserDefaults.standard.removeObject(forKey: cachedOnboardingKey)
        #if DEBUG
        print("🟢 Cleared cached auth state")
        #endif
    }

    /// Initialize auth state after UI renders
    func initializeAuth() async {
        #if DEBUG
        print("🟢 AuthViewModel.initializeAuth() called")
        #endif
        await checkAuthState()
        #if DEBUG
        print("🟢 AuthViewModel.checkAuthState() completed")
        #endif
        await setupAuthObserver()
        #if DEBUG
        print("🟢 AuthViewModel.setupAuthObserver() completed")
        #endif
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
        #if DEBUG
        print("🟢 checkAuthState() START")
        #endif
        // Prevent duplicate simultaneous checks with async-safe actor guard
        guard await checkGuard.beginCheck() else {
            #if DEBUG
            print("🟢 checkAuthState() SKIP - already in progress")
            #endif
            return
        }
        defer { Task { await checkGuard.endCheck() } }

        // Only show loading if we don't already know the auth state
        // This prevents UI flickering when re-checking after login
        let shouldShowLoading = !authState.isAuthenticated && currentUser == nil
        if shouldShowLoading {
            isLoading = true
        }

        #if DEBUG
        print("🟢 checkAuthState() About to call getCurrentUser()...")
        #endif
        do {
            // Add timeout to prevent indefinite hanging (5s for OAuth token exchange + network latency)
            currentUser = try await withTimeout(seconds: 5) {
                try await SupabaseService.shared.getCurrentUser()
            }
            #if DEBUG
            print("🟢 checkAuthState() getCurrentUser() returned")
            #endif

            if let user = currentUser {
                // User is authenticated - check onboarding status directly from metadata (synchronous)
                let onboardingComplete: Bool
                if case .bool(let completed) = user.userMetadata["onboarding_completed"] {
                    onboardingComplete = completed
                } else {
                    onboardingComplete = false // Default to incomplete if flag not set
                }
                let needsOnboarding = !onboardingComplete
                AppLogger.log("User authenticated: \(user.email ?? "Unknown"), needsOnboarding: \(needsOnboarding)",
                             category: AppLogger.general)

                // Update ALL state atomically
                authState = .authenticated(needsOnboarding: needsOnboarding)
                isAuthenticated = true
                hasCompletedOnboarding = !needsOnboarding

                // Cache auth state for next app launch
                cacheAuthState()

            } else {
                AppLogger.log("No authenticated user", category: AppLogger.general)
                authState = .unauthenticated
                isAuthenticated = false
                hasCompletedOnboarding = false

                // Clear cached auth state
                clearCachedAuthState()
            }
        } catch {
            AppLogger.log("Auth check error: \(error.localizedDescription)",
                         category: AppLogger.general,
                         type: .error)
            authState = .unauthenticated
            isAuthenticated = false
            currentUser = nil
            hasCompletedOnboarding = false

            // Clear cached auth state on error
            clearCachedAuthState()
        }

        isLoading = false
        #if DEBUG
        print("🟢 checkAuthState() END - auth state: \(authState)")
        #endif
    }

    /// Check if user has completed onboarding (legacy - now handled atomically in checkAuthState)
    func checkOnboardingStatus() async {
        guard authState.isAuthenticated, let user = currentUser else {
            authState = .unauthenticated
            hasCompletedOnboarding = false
            return
        }

        // Check onboarding status directly from user metadata (synchronous)
        let onboardingComplete: Bool
        if case .bool(let completed) = user.userMetadata["onboarding_completed"] {
            onboardingComplete = completed
        } else {
            onboardingComplete = false // Default to incomplete if flag not set
        }
        let needsOnboarding = !onboardingComplete

        // Update state atomically
        authState = .authenticated(needsOnboarding: needsOnboarding)
        hasCompletedOnboarding = onboardingComplete

        AppLogger.log("Onboarding status updated: complete=\(onboardingComplete)", category: AppLogger.general)
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

            guard let result = try await group.next() else {
                throw TimeoutError()
            }
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
            authState = .unauthenticated
            hasCompletedOnboarding = false

            // Clear cached auth state
            clearCachedAuthState()

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
        authState = .unauthenticated
        hasCompletedOnboarding = false

        // Clear cached auth state
        clearCachedAuthState()

        AppLogger.log("User account deleted and signed out", category: AppLogger.general)
    }
}

// MARK: - Auth Check Guard Actor

/// Async-safe guard for preventing duplicate auth checks
/// Replaces NSLock which is unsafe in async contexts
actor AuthCheckGuard {
    private var isInProgress = false

    /// Attempts to begin an auth check
    /// Returns true if check should proceed, false if already in progress
    func beginCheck() -> Bool {
        guard !isInProgress else { return false }
        isInProgress = true
        return true
    }

    /// Marks auth check as complete
    func endCheck() {
        isInProgress = false
    }
}

