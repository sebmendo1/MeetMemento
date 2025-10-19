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
    @Published var selectedThemes: Set<String> = []
    @Published var isProcessing: Bool = false
    @Published var errorMessage: String? = nil

    // Resume state tracking
    @Published var hasProfile: Bool = false
    @Published var hasPersonalization: Bool = false
    @Published var hasThemes: Bool = false
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

    /// Validates if themes step can proceed
    var canProceedFromThemes: Bool {
        !selectedThemes.isEmpty
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

    /// Determines if user should start at themes step (has profile + personalization, no themes)
    var shouldStartAtThemes: Bool {
        hasProfile && hasPersonalization && !hasThemes
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

    /// Save personalization text to Supabase
    func savePersonalization() async throws {
        isProcessing = true
        errorMessage = nil

        do {
            let trimmedText = personalizationText.trimmingCharacters(in: .whitespacesAndNewlines)

            try await SupabaseService.shared.updateUserPersonalization(trimmedText)

            AppLogger.log("✅ Personalization saved: \(trimmedText.prefix(50))...",
                         category: AppLogger.general)
        } catch {
            errorMessage = "Failed to save personalization: \(error.localizedDescription)"
            AppLogger.log("❌ Personalization save error: \(error.localizedDescription)",
                         category: AppLogger.general,
                         type: .error)
            throw error
        }

        isProcessing = false
    }

    /// Save selected themes to Supabase
    func saveThemes() async throws {
        isProcessing = true
        errorMessage = nil

        do {
            let themesArray = Array(selectedThemes)

            try await SupabaseService.shared.updateUserThemes(themesArray)

            AppLogger.log("✅ Themes saved: \(themesArray.joined(separator: ", "))",
                         category: AppLogger.general)
        } catch {
            errorMessage = "Failed to save themes: \(error.localizedDescription)"
            AppLogger.log("❌ Themes save error: \(error.localizedDescription)",
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

            // Check if personalization text exists (key is user_personalization_node in Supabase)
            // Use pattern matching for AnyJSON type
            if case .string(let personalization) = userMetadata["user_personalization_node"],
               !personalization.isEmpty {
                self.hasPersonalization = true
                self.personalizationText = personalization
                AppLogger.log("✅ Found existing personalization text",
                             category: AppLogger.general)
            }

            // Check if themes exist (stored as comma-separated string)
            // Use pattern matching for AnyJSON type
            if case .string(let themesString) = userMetadata["selected_themes"],
               !themesString.isEmpty {
                let themesArray = themesString.split(separator: ",").map { String($0) }
                self.hasThemes = true
                self.selectedThemes = Set(themesArray)
                AppLogger.log("✅ Found existing themes: \(themesArray.joined(separator: ", "))",
                             category: AppLogger.general)
            }

            AppLogger.log("📊 Onboarding state loaded - Profile: \(hasProfile), Personalization: \(hasPersonalization), Themes: \(hasThemes)",
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
        selectedThemes = []
        isProcessing = false
        errorMessage = nil
        hasProfile = false
        hasPersonalization = false
        hasThemes = false
        isLoadingState = false
    }

    /// Generate sample themes based on personalization text
    /// (Placeholder - will be replaced with backend algorithm)
    func generateThemes() -> [String] {
        // Hardcoded themes for now - will be replaced with AI analysis
        return [
            "Work related stress",
            "Keeping an image",
            "Closing doors",
            "Reaching acceptance",
            "Choosing better",
            "Living your own life"
        ]
    }
}
