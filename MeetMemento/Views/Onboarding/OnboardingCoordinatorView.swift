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
                NSLog("🔵 OnboardingCoordinatorView: Starting to load state")

                // Start minimum display time enforcement
                let minimumLoadTask = Task {
                    // Reduced to 0.5 seconds for faster UX (still shows loader briefly)
                    try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                    await MainActor.run {
                        hasMetMinimumLoadTime = true
                        NSLog("✅ Minimum onboarding load time met")
                        AppLogger.log("✅ Minimum onboarding load time met", category: AppLogger.general)
                    }
                }

                // Load state concurrently
                await onboardingViewModel.loadCurrentState()
                hasLoadedState = true
                NSLog("✅ Onboarding state loaded")

                // Wait for minimum time if not already met
                await minimumLoadTask.value

                NSLog("✅ OnboardingCoordinatorView: Ready to show initial view")
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

    /// Handle personalization completion (Step 2) - Create first journal entry
    private func handlePersonalizationComplete(_ userInput: String) {
        // Store text for reference
        onboardingViewModel.personalizationText = userInput

        Task {
            do {
                // Create first journal entry
                try await onboardingViewModel.createFirstJournalEntry(text: userInput)

                await MainActor.run {
                    onboardingViewModel.hasPersonalization = true
                    navigationPath.append(OnboardingRoute.loading)
                }
            } catch {
                await MainActor.run {
                    onboardingViewModel.errorMessage = error.localizedDescription
                }
                AppLogger.log("❌ Failed to create first entry: \(error.localizedDescription)",
                             category: AppLogger.general,
                             type: .error)
            }
        }
    }

    /// Handle onboarding completion (Step 3)
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
