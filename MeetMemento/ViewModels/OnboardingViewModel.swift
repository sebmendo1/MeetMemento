//
//  OnboardingViewModel.swift
//  MeetMemento
//
//  Centralized state management for onboarding flow
//

import Foundation
import SwiftUI

@MainActor
class OnboardingViewModel: ObservableObject {
    // MARK: - Published State

    @Published var firstName: String = ""
    @Published var lastName: String = ""
    @Published var personalizationText: String = ""
    @Published var isProcessing: Bool = false
    @Published var errorMessage: String? = nil

    // Resume state tracking
    @Published var hasProfile: Bool = false
    @Published var hasPersonalization: Bool = false
    @Published var isLoadingState: Bool = false

    // MARK: - Step Validation

    /// Validates if profile step can proceed
    var canProceedFromProfile: Bool {
        !firstName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !lastName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// Validates if personalization step can proceed
    var canProceedFromPersonalization: Bool {
        personalizationText.trimmingCharacters(in: .whitespacesAndNewlines).count >= 50
    }

    // MARK: - Resume Logic

    /// Determines if user should start at profile step (no profile data saved)
    var shouldStartAtProfile: Bool {
        !hasProfile
    }

    /// Determines if user should start at personalization step (has profile, no personalization)
    var shouldStartAtPersonalization: Bool {
        hasProfile && !hasPersonalization
    }

    // MARK: - Data Persistence

    /// Save profile data to Supabase
    func saveProfileData() async throws {
        isProcessing = true
        errorMessage = nil

        do {
            let trimmedFirstName = firstName.trimmingCharacters(in: .whitespacesAndNewlines)
            let trimmedLastName = lastName.trimmingCharacters(in: .whitespacesAndNewlines)

            try await SupabaseService.shared.updateUserMetadata(
                firstName: trimmedFirstName,
                lastName: trimmedLastName
            )

            AppLogger.log("✅ Profile data saved: \(trimmedFirstName) \(trimmedLastName)",
                         category: AppLogger.general)
        } catch {
            errorMessage = "Failed to save profile: \(error.localizedDescription)"
            AppLogger.log("❌ Profile save error: \(error.localizedDescription)",
                         category: AppLogger.general,
                         type: .error)
            throw error
        }

        isProcessing = false
    }

    /// Creates first journal entry from onboarding text
    func createFirstJournalEntry(text: String) async throws {
        isProcessing = true
        errorMessage = nil

        do {
            let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)

            // Create the first journal entry
            let _ = try await SupabaseService.shared.createEntry(
                title: "My First Entry",
                text: trimmedText
            )

            AppLogger.log("✅ First journal entry created: \(trimmedText.prefix(50))...",
                         category: AppLogger.general)
        } catch {
            errorMessage = "Failed to create journal entry: \(error.localizedDescription)"
            AppLogger.log("❌ First entry creation error: \(error.localizedDescription)",
                         category: AppLogger.general,
                         type: .error)
            throw error
        }

        isProcessing = false
    }

    /// Complete onboarding process
    func completeOnboarding() async throws {
        isProcessing = true
        errorMessage = nil

        do {
            try await SupabaseService.shared.completeUserOnboarding()

            AppLogger.log("✅ Onboarding completed successfully",
                         category: AppLogger.general)
        } catch {
            errorMessage = "Failed to complete onboarding: \(error.localizedDescription)"
            AppLogger.log("❌ Onboarding completion error: \(error.localizedDescription)",
                         category: AppLogger.general,
                         type: .error)
            throw error
        }

        isProcessing = false
    }

    /// Load current onboarding state from Supabase to determine resume point
    func loadCurrentState() async {
        isLoadingState = true
        errorMessage = nil

        do {
            // Get current user from Supabase
            guard let user = try await SupabaseService.shared.getCurrentUser() else {
                AppLogger.log("⚠️ No user found when loading onboarding state",
                             category: AppLogger.general,
                             type: .error)
                isLoadingState = false
                return
            }

            // Check user_metadata for saved onboarding data
            let userMetadata = user.userMetadata

            // Check if profile data exists (first_name and last_name)
            // Use pattern matching for AnyJSON type
            if case .string(let firstName) = userMetadata["first_name"],
               case .string(let lastName) = userMetadata["last_name"],
               !firstName.isEmpty, !lastName.isEmpty {
                self.hasProfile = true
                self.firstName = firstName
                self.lastName = lastName
                AppLogger.log("✅ Found existing profile: \(firstName) \(lastName)",
                             category: AppLogger.general)
            }

            // Check if user has created at least one entry (indicates onboarding complete)
            let entryCount = try? await SupabaseService.shared.getUserEntryCount()
            if let count = entryCount, count > 0 {
                self.hasPersonalization = true
                AppLogger.log("✅ Found \(count) existing entries",
                             category: AppLogger.general)
            }

            AppLogger.log("📊 Onboarding state loaded - Profile: \(hasProfile), HasEntries: \(hasPersonalization)",
                         category: AppLogger.general)

        } catch {
            errorMessage = "Failed to load onboarding state: \(error.localizedDescription)"
            AppLogger.log("❌ Failed to load onboarding state: \(error.localizedDescription)",
                         category: AppLogger.general,
                         type: .error)
        }

        isLoadingState = false
    }

    // MARK: - Helper Methods

    /// Reset all onboarding data (useful for testing)
    func reset() {
        firstName = ""
        lastName = ""
        personalizationText = ""
        isProcessing = false
        errorMessage = nil
        hasProfile = false
        hasPersonalization = false
        isLoadingState = false
    }
}
