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
                        AppleSignInButton(style: .black) {
                            signUpWithAppleNative()
                        }
                        .disabled(isLoadingAppleNative)
                        
                        // Google Sign In
                        GoogleSignInButton(title: "Continue with Google") {
                            Task { try? await AuthService.shared.signInWithGoogle() }
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
    }
    
    
    // MARK: - Actions
    
    private func createAccountWithEmail() {
        guard !email.isEmpty else { return }
        
        isLoading = true
        status = ""
        
        Task {
            do {
                // For now, just show success message
                // TODO: Implement actual email sign up
                await MainActor.run {
                    status = "✅ Account creation coming soon!"
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    status = "❌ Account creation failed: \(error.localizedDescription)"
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
        let delegate = AppleAuthDelegate(nonce: nonce) { [self] errorMessage in
            DispatchQueue.main.async {
                self.isLoadingAppleNative = false
                if let error = errorMessage {
                    self.appleNativeError = error
                } else {
                    // Success - dismiss sheet
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
