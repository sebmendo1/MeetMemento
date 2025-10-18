//
//  OnboardingCoordinatorView.swift
//  MeetMemento
//
//  Coordinates navigation flow for onboarding steps
//

import SwiftUI

// MARK: - Onboarding Routes

enum OnboardingRoute: Hashable {
    case learnAboutYourself
    case themesIdentified
    case loading
}

// MARK: - Onboarding Coordinator View

public struct OnboardingCoordinatorView: View {
    @Environment(\.theme) private var theme
    @Environment(\.typography) private var type
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var onboardingViewModel = OnboardingViewModel()

    @State private var navigationPath = NavigationPath()
    @State private var hasLoadedState = false
    @State private var hasMetMinimumLoadTime = false

    public init() {}

    public var body: some View {
        NavigationStack(path: $navigationPath) {
            Group {
                if !hasLoadedState || onboardingViewModel.isLoadingState || !hasMetMinimumLoadTime {
                    // Show loading while checking current state
                    // AND enforce minimum display time for smooth UX
                    LoadingView()
                } else {
                    // Show correct starting point based on resume logic
                    initialView
                }
            }
            .navigationDestination(for: OnboardingRoute.self) { route in
                switch route {
                case .learnAboutYourself:
                    LearnAboutYourselfView { userInput in
                        handlePersonalizationComplete(userInput)
                    }
                    .environmentObject(authViewModel)

                case .themesIdentified:
                    ThemesIdentifiedView(
                        themes: onboardingViewModel.generateThemes()
                    ) { selectedThemes in
                        handleThemesComplete(selectedThemes)
                    }
                    .environmentObject(authViewModel)

                case .loading:
                    LoadingStateView {
                        handleOnboardingComplete()
                    }
                    .environmentObject(authViewModel)
                }
            }
        }
        .environmentObject(onboardingViewModel)
        .useTheme()
        .useTypography()
        .task {
            // Load current state on appear to determine resume point
            if !hasLoadedState {
                // Start minimum display time enforcement immediately
                let minimumLoadTask = Task {
                    // Enforce minimum 1.2 second loading display for smooth transition from OTP
                    try? await Task.sleep(nanoseconds: 1_200_000_000) // 1.2 seconds
                    await MainActor.run {
                        hasMetMinimumLoadTime = true
                        AppLogger.log("✅ Minimum onboarding load time met", category: AppLogger.general)
                    }
                }

                // Load state concurrently
                await onboardingViewModel.loadCurrentState()
                hasLoadedState = true

                // Wait for minimum time if not already met
                await minimumLoadTask.value

                AppLogger.log("✅ Onboarding state loaded and ready to show", category: AppLogger.general)
            }
        }
    }

    // MARK: - Initial View Logic

    @ViewBuilder
    private var initialView: some View {
        if onboardingViewModel.shouldStartAtProfile {
            // Start at profile (CreateAccountView)
            CreateAccountView(
                onComplete: {
                    handleProfileComplete()
                }
            )
            .environmentObject(authViewModel)
        } else if onboardingViewModel.shouldStartAtPersonalization {
            // Skip to personalization
            LearnAboutYourselfView { userInput in
                handlePersonalizationComplete(userInput)
            }
            .environmentObject(authViewModel)
        } else if onboardingViewModel.shouldStartAtThemes {
            // Skip to themes
            ThemesIdentifiedView(
                themes: onboardingViewModel.generateThemes()
            ) { selectedThemes in
                handleThemesComplete(selectedThemes)
            }
            .environmentObject(authViewModel)
        } else {
            // All steps completed - go to loading/completion
            LoadingStateView {
                handleOnboardingComplete()
            }
            .environmentObject(authViewModel)
        }
    }

    /// Navigate to the appropriate step after loading state
    private func navigateToResumePoint() {
        // This function is kept for potential future use
        // Currently, initialView handles the correct starting point
    }

    // MARK: - Navigation Handlers

    /// Handle profile completion (Step 1)
    private func handleProfileComplete() {
        // Profile data is saved in CreateAccountView via authViewModel.updateProfile
        // Mark as completed in view model for resume logic
        onboardingViewModel.hasProfile = true

        // Navigate to LearnAboutYourself
        navigationPath.append(OnboardingRoute.learnAboutYourself)
    }

    /// Handle personalization completion (Step 2)
    private func handlePersonalizationComplete(_ userInput: String) {
        // Store personalization text
        onboardingViewModel.personalizationText = userInput

        // Save to Supabase
        Task {
            do {
                try await onboardingViewModel.savePersonalization()

                // Mark as completed in view model for resume logic
                await MainActor.run {
                    onboardingViewModel.hasPersonalization = true
                }

                // Navigate to themes
                await MainActor.run {
                    navigationPath.append(OnboardingRoute.themesIdentified)
                }
            } catch {
                // Handle error - could show alert
                AppLogger.log("Error saving personalization: \(error.localizedDescription)",
                             category: AppLogger.general,
                             type: .error)
            }
        }
    }

    /// Handle themes selection completion (Step 3)
    private func handleThemesComplete(_ selectedThemes: [String]) {
        // Store selected themes
        onboardingViewModel.selectedThemes = Set(selectedThemes)

        // Save to Supabase and navigate to loading
        Task {
            do {
                try await onboardingViewModel.saveThemes()

                // Mark as completed in view model for resume logic
                await MainActor.run {
                    onboardingViewModel.hasThemes = true
                }

                // Navigate to loading state
                await MainActor.run {
                    navigationPath.append(OnboardingRoute.loading)
                }
            } catch {
                // Handle error
                AppLogger.log("Error saving themes: \(error.localizedDescription)",
                             category: AppLogger.general,
                             type: .error)
            }
        }
    }

    /// Handle onboarding completion (Step 4)
    private func handleOnboardingComplete() {
        // Mark onboarding as complete in Supabase
        Task {
            do {
                try await onboardingViewModel.completeOnboarding()

                // Update local state immediately for instant UI update
                await MainActor.run {
                    authViewModel.hasCompletedOnboarding = true
                }

                // MeetMementoApp will automatically show ContentView
                AppLogger.log("✅ Onboarding flow completed",
                             category: AppLogger.general)
            } catch {
                AppLogger.log("Error completing onboarding: \(error.localizedDescription)",
                             category: AppLogger.general,
                             type: .error)
            }
        }
    }
}

// MARK: - Previews

#Preview("Onboarding Flow") {
    OnboardingCoordinatorView()
        .environmentObject(AuthViewModel())
}
