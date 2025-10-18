//
//  CreateAccountBottomSheet.swift
//  MeetMemento
//
//  Bottom sheet component for user account creation
//

import SwiftUI
import AuthenticationServices

public struct CreateAccountBottomSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) private var theme
    @Environment(\.typography) private var type
    @EnvironmentObject var authViewModel: AuthViewModel
    
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var status: String = ""
    @State private var isLoading: Bool = false
    @State private var appleNativeError: String = ""
    @State private var isLoadingAppleNative = false
    @State private var navigateToOTP: Bool = false

    public var onSignUpSuccess: (() -> Void)?
    
    public init(onSignUpSuccess: (() -> Void)? = nil) {
        self.onSignUpSuccess = onSignUpSuccess
    }
    
    public var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Handle bar
                RoundedRectangle(cornerRadius: 2.5)
                    .fill(theme.mutedForeground.opacity(0.3))
                    .frame(width: 36, height: 5)
                    .padding(.top, 8)
                    .padding(.bottom, 20)
                
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Create account")
                        .font(type.h3)
                        .headerGradient()
                    
                    Text("Let's learn about you and we'll help you get started")
                        .font(type.bodySmall)
                        .foregroundStyle(theme.mutedForeground)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.top, 32)
                .padding(.bottom, 24)
                
                // Content
                VStack(spacing: 24) {
                    // Email input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Email")
                            .font(type.bodyBold)
                            .foregroundStyle(theme.foreground)
                        
                        AppTextField(
                            placeholder: "Enter your email",
                            text: $email,
                            keyboardType: .emailAddress,
                            textInputAutocapitalization: .never
                        )
                    }
                    
                    // Continue button
                    Button(action: createAccountWithEmail) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .tint(.white)
                                    .scaleEffect(0.8)
                            } else {
                                Text("Continue")
                                    .font(type.button)
                                    .fontWeight(.bold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(theme.primary)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: theme.radius.lg, style: .continuous))
                    }
                    .disabled(isLoading || email.isEmpty)
                    .opacity((isLoading || email.isEmpty) ? 0.6 : 1.0)
                    
                    // Divider
                    HStack {
                        Rectangle()
                            .fill(theme.border)
                            .frame(height: 1)
                        
                        Text("or")
                            .font(type.body)
                            .foregroundStyle(theme.mutedForeground)
                            .padding(.horizontal, 16)
                        
                        Rectangle()
                            .fill(theme.border)
                            .frame(height: 1)
                    }
                    .padding(.vertical, 8)
                    
                    // Social auth buttons
                    VStack(spacing: 12) {
                        // Apple Sign In
                        AppleSignInButton(title: "Continue with Apple", style: .black) {
                            signUpWithAppleNative()
                        }
                        .disabled(isLoadingAppleNative)
                        
                        // Google Sign In
                        GoogleSignInButton(title: "Continue with Google") {
                            Task {
                                do {
                                    try await AuthService.shared.signInWithGoogle()
                                    // Check auth state after OAuth completes
                                    await authViewModel.checkAuthState()
                                    await authViewModel.checkOnboardingStatus()

                                    // OAuth success - dismiss sheet and let WelcomeView handle onboarding
                                    await MainActor.run {
                                        dismiss()
                                        onSignUpSuccess?()
                                    }
                                } catch {
                                    await MainActor.run {
                                        status = "❌ Google sign-in failed: \(error.localizedDescription)"
                                    }
                                }
                            }
                        }
                    }
                    .padding(.vertical, 24)

                    
                    // Status message
                    if !status.isEmpty {
                        Text(status)
                            .font(type.body)
                            .foregroundStyle(status.contains("✅") ? .green : .red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }
                    
                    // Apple Sign In error
                    if !appleNativeError.isEmpty {
                        Text(appleNativeError)
                            .font(type.body)
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
            .background(theme.background)
            .navigationBarHidden(true)
        }
        .presentationDetents([.height(540)])
        .presentationDragIndicator(.hidden)
        .fullScreenCover(isPresented: $navigateToOTP) {
            NavigationStack {
                OTPVerificationView(email: email, isSignUp: true)
                    .environmentObject(authViewModel)
                    .useTheme()
                    .useTypography()
            }
            .onChange(of: authViewModel.authState) { oldState, newState in
                // When user becomes authenticated (OTP verified), dismiss OTP view and sheet
                AppLogger.log("CreateAccountBottomSheet: authState changed from \(oldState) to \(newState)", category: AppLogger.general)

                if newState.isAuthenticated {
                    navigateToOTP = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        dismiss()
                        onSignUpSuccess?()
                    }
                }
            }
        }
    }
    
    
    // MARK: - Actions
    
    private func createAccountWithEmail() {
        guard !email.isEmpty else { return }

        isLoading = true
        status = ""

        Task {
            do {
                try await authViewModel.sendOTP(email: email)
                await MainActor.run {
                    status = "✅ Code sent to \(email)"
                    isLoading = false
                    // Navigate to OTP entry screen as full page
                    navigateToOTP = true
                }
            } catch {
                await MainActor.run {
                    status = "❌ Failed to send code: \(error.localizedDescription)"
                    isLoading = false
                }
            }
        }
    }
    
    private func signUpWithAppleNative() {
        isLoadingAppleNative = true
        appleNativeError = ""

        let nonce = NonceGenerator.randomNonce()
        let hashedNonce = NonceGenerator.sha256(nonce)

        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = hashedNonce

        let controller = ASAuthorizationController(authorizationRequests: [request])
        // Updated delegate with new completion signature
        let delegate = AppleAuthDelegate(nonce: nonce) { [self] errorMessage, firstName, lastName in
            DispatchQueue.main.async {
                self.isLoadingAppleNative = false
                if let error = errorMessage {
                    self.appleNativeError = error
                } else {
                    // Store pending names in AuthViewModel (if provided by Apple)
                    if let first = firstName, let last = lastName, !first.isEmpty, !last.isEmpty {
                        self.authViewModel.storePendingAppleProfile(firstName: first, lastName: last)
                        AppLogger.log("✅ Stored Apple names for CreateAccountView", category: AppLogger.general)
                    } else {
                        AppLogger.log("⚠️ No Apple names provided (returning user)", category: AppLogger.general)
                    }

                    // Check auth state to ensure proper onboarding flow trigger
                    Task {
                        await self.authViewModel.checkAuthState()
                    }

                    // Success - dismiss sheet and let WelcomeView handle onboarding
                    self.dismiss()
                    self.onSignUpSuccess?()
                }
            }
        }
        controller.delegate = delegate
        controller.presentationContextProvider = delegate
        controller.performRequests()
    }
}

// MARK: - Preview
#Preview("Create Account Bottom Sheet") {
    CreateAccountBottomSheet()
        .useTheme()
        .useTypography()
        .environmentObject(AuthViewModel())
}
