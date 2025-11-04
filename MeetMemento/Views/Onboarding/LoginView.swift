//
//  LoginView.swift
//  MeetMemento
//
//  Minimal login surface for social auth via Supabase.
//

import SwiftUI
import AuthenticationServices

public struct LoginView: View {
    @Environment(\.theme) private var theme
    @Environment(\.typography) private var type

    @State private var status: String = ""
    @State private var isLoading: Bool = false
    
    public init() {}

    public var body: some View {
        VStack(spacing: 16) {
            Spacer()

            Text("Sign in to MeetMemento")
                .font(type.h3)
                .fontWeight(.semibold)
                .headerGradient()
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            VStack(spacing: 12) {
                GoogleSignInButton() { signInWithGoogle() }
                AppleSignInButton(style: .black) { signInWithApple_OAuth() }

                // Optional: Native Apple path using ASAuthorizationController
                Button(action: signInWithAppleNative) {
                    Text("Use Apple (Native)")
                        .font(type.button)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                        .foregroundStyle(theme.primary)
                        .overlay(
                            RoundedRectangle(cornerRadius: theme.radius.lg)
                                .stroke(theme.primary, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
                .padding(.top, 4)
            }
            .disabled(isLoading)
            .opacity(isLoading ? 0.7 : 1)

            if !status.isEmpty {
                Text(status)
                    .font(type.body)
                    .foregroundStyle(status.hasPrefix("Error") ? .red : .green)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }

            Spacer()
        }
        .padding(24)
        .background(theme.background)
    }

    private func signInWithGoogle() {
        isLoading = true
        status = ""
        Task {
            do {
                try await AuthService.shared.signInWithGoogle()
                await MainActor.run { status = "Signed in"; isLoading = false }
            } catch {
                await MainActor.run { status = "Error: \(error.localizedDescription)"; isLoading = false }
            }
        }
    }

    private func signInWithApple_OAuth() {
        isLoading = true
        status = ""
        Task {
            do {
                try await AuthService.shared.signInWithApple_OAuth()
                await MainActor.run { status = "Signed in"; isLoading = false }
            } catch {
                await MainActor.run { status = "Error: \(error.localizedDescription)"; isLoading = false }
            }
        }
    }

    /// Demonstration of native Apple flow: obtain idToken + nonce and pass to AuthService.
    /// Use OAuth if you don't need native Account scope data; native allows more granular control.
    private func signInWithAppleNative() {
        let nonce: String
        do {
            nonce = try NonceGenerator.randomNonce()
        } catch {
            self.status = "Failed to generate secure authentication nonce"
            return
        }
        let hashed = NonceGenerator.sha256(nonce)

        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = hashed

        let controller = ASAuthorizationController(authorizationRequests: [request])
        let delegate = AppleAuthDelegate(nonce: nonce) { errorMessage, firstName, lastName in
            self.status = errorMessage ?? "Signed in"
            // Note: firstName and lastName are available here if needed
            // For this simple demo view, we just show the status
        }
        controller.delegate = delegate
        controller.presentationContextProvider = delegate
        controller.performRequests()
    }
}

// AppleAuthDelegate is now in Services/Auth/AppleAuthDelegate.swift

#Preview("Light") {
    LoginView()
        .useTheme()
        .useTypography()
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    LoginView()
        .useTheme()
        .useTypography()
        .preferredColorScheme(.dark)
}
