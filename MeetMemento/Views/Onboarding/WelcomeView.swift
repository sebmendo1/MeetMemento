
//
//  WelcomeView.swift
//  MeetMemento
//
//  Created by Sebastian Mendo on 10/2/25.
//

import SwiftUI
import AuthenticationServices

public struct WelcomeView: View {
    public var onNext: (() -> Void)?

    @Environment(\.theme) private var theme
    @Environment(\.typography) private var type
    @StateObject private var authStatus = AuthStatusViewModel()
    @EnvironmentObject var authViewModel: AuthViewModel

    @State private var showSignUp = false
    @State private var showSignIn = false
    @State private var showCreateAccountSheet = false
    @State private var showSignInSheet = false
    @State private var showOnboardingFlow = false
    @State private var appleNativeError: String = ""
    @State private var isLoadingAppleNative = false

    public init(onNext: (() -> Void)? = nil) {
        self.onNext = onNext
    }

    public var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                Spacer()

                // App logo
                Image("LaunchLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 64, height: 64)

                // Headline
                Text("MeetMemento")
                    .font(type.h1)
                    .headerGradient()

                // Description
                Text("Your AI journalling partner.")
                    .font(type.body)
                    .foregroundStyle(theme.mutedForeground)
                    .multilineTextAlignment(.center)

                Spacer()
                
                // Authentication buttons
                VStack(spacing: 16) {
                    
                    // Sign In button (PrimaryButton)
                    PrimaryButton(title: "Sign In") {
                        showSignInSheet = true
                    }

                    // Create Account button (SecondaryButton)
                    SecondaryButton(title: "Create Account") {
                        showCreateAccountSheet = true
                    }
                }
                .padding(.horizontal, 16)

                // Apple Sign-In errors
                if !appleNativeError.isEmpty {
                    Text(appleNativeError)
                        .font(type.body)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                        .padding(.top, 4)
                }
            }
            .padding()
            .background(theme.background.ignoresSafeArea())
        }
        .sheet(isPresented: $showCreateAccountSheet) {
            CreateAccountBottomSheet(onSignUpSuccess: {
                showCreateAccountSheet = false
            })
            .useTheme()
            .useTypography()
            .environmentObject(authStatus)
        }
        .sheet(isPresented: $showSignInSheet) {
            SignInBottomSheet(onSignInSuccess: {
                showSignInSheet = false
            })
            .useTheme()
            .useTypography()
            .environmentObject(authStatus)
        }
        .fullScreenCover(isPresented: $showOnboardingFlow) {
            OnboardingCoordinatorView()
                .useTheme()
                .useTypography()
                .environmentObject(authViewModel)
        }
        .onChange(of: authViewModel.authState) { oldState, newState in
            // Watch combined auth state to prevent race conditions
            AppLogger.log("WelcomeView: authState changed from \(oldState) to \(newState)", category: AppLogger.general)

            // Show onboarding when user is authenticated but needs onboarding
            if case .authenticated(let needsOnboarding) = newState, needsOnboarding {
                // Add small delay to ensure any sheets are dismissed first
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    AppLogger.log("WelcomeView: Showing onboarding flow", category: AppLogger.general)
                    showOnboardingFlow = true
                }
            }
        }
    }

    // MARK: - Apple Sign-In Handler

    private func signInWithAppleNative() {
        isLoadingAppleNative = true
        appleNativeError = ""

        let nonce = NonceGenerator.randomNonce()
        let hashedNonce = NonceGenerator.sha256(nonce)

        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = hashedNonce

        let controller = ASAuthorizationController(authorizationRequests: [request])
        let delegate = AppleAuthDelegate(nonce: nonce) { [self]  errorMessage, firstName, lastName in
            DispatchQueue.main.async {
                self.isLoadingAppleNative = false
                if let error = errorMessage {
                    self.appleNativeError = error
                } else {
                    // Store pending names in AuthViewModel (if provided by Apple)
                    if let first = firstName, let last = lastName, !first.isEmpty, !last.isEmpty {
                        self.authViewModel.storePendingAppleProfile(firstName: first, lastName: last)
                        AppLogger.log("✅ Stored Apple names from WelcomeView", category: AppLogger.general)
                    }

                    // Check auth state to trigger onboarding flow
                    Task {
                        await self.authViewModel.checkAuthState()
                    }
                }
            }
        }
        controller.delegate = delegate
        controller.presentationContextProvider = delegate
        controller.performRequests()
    }
}

// MARK: - Previews
#Preview("Welcome • Light") {
    WelcomeView()
        .useTheme()
        .useTypography()
        .environmentObject(AuthViewModel())
        .preferredColorScheme(.light)
}

#Preview("Welcome • Dark") {
    WelcomeView()
        .useTheme()
        .useTypography()
        .environmentObject(AuthViewModel())
        .preferredColorScheme(.dark)
}
