
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
    
    @State private var showSignUp = false
    @State private var showSignIn = false
    @State private var showCreateAccountSheet = false
    @State private var showSignInSheet = false
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
                    // Social OAuth buttons (web)
                    GoogleSignInButton(title: "Sign in with Google") {
                        Task { try? await AuthService.shared.signInWithGoogle() }
                    }

                    // Native Apple Sign-In (using ASAuthorizationController)
                    AppleSignInButton(style: .black) {
                        signInWithAppleNative()
                    }
                    .disabled(isLoadingAppleNative)
                    
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
                onNext?()
            })
            .useTheme()
            .useTypography()
            .environmentObject(authStatus)
        }
        .sheet(isPresented: $showSignInSheet) {
            SignInBottomSheet(onSignInSuccess: {
                showSignInSheet = false
                onNext?()
            })
            .useTheme()
            .useTypography()
            .environmentObject(authStatus)
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
        let delegate = AppleAuthDelegate(nonce: nonce) { [self] errorMessage in
            DispatchQueue.main.async {
                self.isLoadingAppleNative = false
                if let error = errorMessage {
                    self.appleNativeError = error
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
        .preferredColorScheme(.light)
}

#Preview("Welcome • Dark") {
    WelcomeView()
        .useTheme()
        .useTypography()
        .preferredColorScheme(.dark)
}
