//
//  SignUpView.swift
//  MeetMemento
//
//  Sign up view with Supabase authentication
//

import SwiftUI

public struct SignUpView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.theme) private var theme
    @Environment(\.typography) private var type
    @EnvironmentObject var authViewModel: AuthViewModel
    
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var status: String = ""
    @State private var isLoading: Bool = false
    @State private var showSuccess: Bool = false
    
    public init() {}
    
    public var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer(minLength: 40)
                
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "person.badge.plus")
                        .font(.system(size: 56))
                        .foregroundStyle(theme.primary)
                    
                    Text("Create Account")
                        .font(type.h1)
                        .headerGradient()
                    
                    Text("Sign up to start your journaling journey")
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
                    
                    AppTextField(
                        placeholder: "Confirm Password",
                        text: $confirmPassword,
                        isSecure: true,
                        icon: "lock.fill"
                    )
                }
                
                // Status message
                if !status.isEmpty {
                    Text(status)
                        .font(type.body)
                        .foregroundStyle(showSuccess ? .green : .red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                }
                
                // Sign Up button
                PrimaryButton(
                    title: "Sign Up",
                    systemImage: "arrow.right",
                    isLoading: isLoading
                ) {
                    signUp()
                }
                .padding(.top, 8)
                
                // Already have account
                Button {
                    dismiss()
                } label: {
                    HStack(spacing: 4) {
                        Text("Already have an account?")
                            .foregroundStyle(theme.mutedForeground)
                        Text("Sign In")
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
    
    private func signUp() {
        // Validation
        guard !email.isEmpty else {
            status = "Error: Please enter your email"
            showSuccess = false
            return
        }
        
        guard !password.isEmpty else {
            status = "Error: Please enter a password"
            showSuccess = false
            return
        }
        
        guard password.count >= 6 else {
            status = "Error: Password must be at least 6 characters"
            showSuccess = false
            return
        }
        
        guard password == confirmPassword else {
            status = "Error: Passwords do not match"
            showSuccess = false
            return
        }
        
        isLoading = true
        status = ""
        
        Task {
            do {
                // Use AuthViewModel instead of SupabaseService directly
                try await authViewModel.signUp(email: email, password: password)
                
                await MainActor.run {
                    isLoading = false
                    showSuccess = true
                    status = "✅ Signed up successfully! Check your email for verification."
                    
                    // Clear password fields
                    password = ""
                    confirmPassword = ""
                }
                
                // Note: App will automatically navigate to ContentView if Supabase
                // automatically signs in after signup (depends on email verification settings)
                
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
        SignUpView()
            .useTheme()
            .useTypography()
            .environmentObject(AuthViewModel())
    }
    .preferredColorScheme(.light)
}

#Preview("Dark") {
    NavigationStack {
        SignUpView()
            .useTheme()
            .useTypography()
            .environmentObject(AuthViewModel())
    }
    .preferredColorScheme(.dark)
}

