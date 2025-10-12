//
//  SignInView.swift
//  MeetMemento
//
//  Sign in view with Supabase authentication
//

import SwiftUI

public struct SignInView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.theme) private var theme
    @Environment(\.typography) private var type
    @EnvironmentObject var authViewModel: AuthViewModel
    
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var status: String = ""
    @State private var isLoading: Bool = false
    @State private var showSuccess: Bool = false
    
    public var onSignInSuccess: (() -> Void)?
    
    public init(onSignInSuccess: (() -> Void)? = nil) {
        self.onSignInSuccess = onSignInSuccess
    }
    
    public var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer(minLength: 60)
                
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 56))
                        .foregroundStyle(theme.primary)
                    
                    Text("Welcome Back")
                        .font(type.h1)
                        .headerGradient()
                    
                    Text("Sign in to continue your journey")
                        .font(type.body)
                        .foregroundStyle(theme.mutedForeground)
                        .multilineTextAlignment(.center)
                }
                .padding(.bottom, 16)
                
                // Input fields
                VStack(spacing: 16) {
                    AppTextField(
                        placeholder: "Email",
                        text: $email,
                        keyboardType: .emailAddress,
                        textInputAutocapitalization: .never,
                        icon: "envelope"
                    )
                    
                    AppTextField(
                        placeholder: "Password",
                        text: $password,
                        isSecure: true,
                        icon: "lock"
                    )
                }
                
                // Forgot password (placeholder)
                HStack {
                    Spacer()
                    Button {
                        // TODO: Implement forgot password
                    } label: {
                        Text("Forgot Password?")
                            .font(type.body)
                            .foregroundStyle(theme.primary)
                    }
                }
                .padding(.top, -8)
                
                // Status message
                if !status.isEmpty {
                    Text(status)
                        .font(type.body)
                        .foregroundStyle(showSuccess ? .green : .red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                }
                
                // Sign In button
                PrimaryButton(
                    title: "Sign In",
                    systemImage: "arrow.right",
                    isLoading: isLoading
                ) {
                    signIn()
                }
                .padding(.top, 8)
                
                // Don't have account
                Button {
                    dismiss()
                } label: {
                    HStack(spacing: 4) {
                        Text("Don't have an account?")
                            .foregroundStyle(theme.mutedForeground)
                        Text("Sign Up")
                            .foregroundStyle(theme.primary)
                            .fontWeight(.semibold)
                    }
                    .font(type.body)
                }
                .buttonStyle(.plain)
                
                Spacer()
            }
            .padding(.horizontal, 32)
        }
        .background(theme.background.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func signIn() {
        // Validation
        guard !email.isEmpty else {
            status = "Error: Please enter your email"
            showSuccess = false
            return
        }
        
        guard !password.isEmpty else {
            status = "Error: Please enter your password"
            showSuccess = false
            return
        }
        
        isLoading = true
        status = ""
        
        Task {
            do {
                // Use AuthViewModel instead of SupabaseService directly
                try await authViewModel.signIn(email: email, password: password)
                
                await MainActor.run {
                    isLoading = false
                    showSuccess = true
                    status = "✅ Signed in successfully!"
                    
                    // Clear password
                    password = ""
                }
                
                // Call success callback
                onSignInSuccess?()
                
                // Note: No need to dismiss - app will automatically navigate to ContentView
                // because authViewModel.isAuthenticated will become true
                
            } catch {
                await MainActor.run {
                    isLoading = false
                    showSuccess = false
                    status = "Error: \(error.localizedDescription)"
                }
            }
        }
    }
}

#Preview("Light") {
    NavigationStack {
        SignInView()
            .useTheme()
            .useTypography()
            .environmentObject(AuthViewModel())
    }
    .preferredColorScheme(.light)
}

#Preview("Dark") {
    NavigationStack {
        SignInView()
            .useTheme()
            .useTypography()
            .environmentObject(AuthViewModel())
    }
    .preferredColorScheme(.dark)
}
