//
//  SignInBottomSheet.swift
//  MeetMemento
//
//  Bottom sheet component for user sign in
//

import SwiftUI
import AuthenticationServices

public struct SignInBottomSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) private var theme
    @Environment(\.typography) private var type
    @EnvironmentObject var authViewModel: AuthViewModel
    
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var status: String = ""
    @State private var isLoading: Bool = false
    @State private var appleNativeError: String = ""
    @State private var isLoadingAppleNative = false
    
    public var onSignInSuccess: (() -> Void)?
    
    public init(onSignInSuccess: (() -> Void)? = nil) {
        self.onSignInSuccess = onSignInSuccess
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
                    Text("Sign in")
                        .font(type.h3)
                        .headerGradient()
                    
                    Text("Make sure to use your same login credentials.")
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
                    Button(action: signInWithEmail) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .tint(.white)
                                    .scaleEffect(0.8)
                            } else {
                                Text("Continue")
                                    .font(type.button)
                                    .fontWeight(.semibold)
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
                            signInWithAppleNative()
                        }
                        .disabled(isLoadingAppleNative)
                        
                        // Google Sign In
                        GoogleSignInButton(title: "Continue with Google") {
                            Task { try? await AuthService.shared.signInWithGoogle() }
                        }
                    }
                    
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
    
    private func signInWithEmail() {
        guard !email.isEmpty else { return }
        
        isLoading = true
        status = ""
        
        Task {
            do {
                // For now, just show success message
                // TODO: Implement actual email sign in
                await MainActor.run {
                    status = "✅ Email sign in coming soon!"
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    status = "❌ Sign in failed: \(error.localizedDescription)"
                    isLoading = false
                }
            }
        }
    }
    
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
                } else {
                    // Success - dismiss sheet
                    self.dismiss()
                    self.onSignInSuccess?()
                }
            }
        }
        controller.delegate = delegate
        controller.presentationContextProvider = delegate
        controller.performRequests()
    }
}

// MARK: - Preview
#Preview("Sign In Bottom Sheet") {
    SignInBottomSheet()
        .useTheme()
        .useTypography()
        .environmentObject(AuthViewModel())
}
