
//
//  SignUpView.swift
//  MeetMemento
//
//  Sign up view with Supabase authentication
//

import SwiftUI

public struct CreateAccountView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.theme) private var theme
    @Environment(\.typography) private var type
    @EnvironmentObject var authViewModel: AuthViewModel

    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var status: String = ""
    @State private var isLoading: Bool = false

    public init() {}

    // NOTE: This view is deprecated and should not be used for authentication.
    // Use CreateAccountBottomSheet → OTPVerificationView instead.
    // This can be repurposed for profile completion after OTP auth if needed.
    
    public var body: some View {
        ZStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Spacer(minLength: 16)

                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Welcome to Memento")
                            .font(type.h2)
                            .headerGradient()

                        Text("Create your account to get started.")
                            .font(type.body)
                            .foregroundStyle(theme.mutedForeground)
                    }
                    .padding(.bottom, 16)
                
                // Input fields
                VStack(spacing: 16) {
                    // First name
                    VStack(alignment: .leading, spacing: 8) {
                        Text("First name")
                            .font(type.body)
                            .foregroundStyle(theme.foreground)
                            .fontWeight(.medium)

                        AppTextField(
                            placeholder: "Enter your first name",
                            text: $firstName,
                            textInputAutocapitalization: .words
                        )
                    }

                    // Last name
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Last name")
                            .font(type.body)
                            .foregroundStyle(theme.foreground)
                            .fontWeight(.medium)

                        AppTextField(
                            placeholder: "Enter your last name",
                            text: $lastName,
                            textInputAutocapitalization: .words
                        )
                    }
                }
                
                // Status message
                if !status.isEmpty {
                    Text(status)
                        .font(type.body)
                        .foregroundStyle(status.contains("✅") ? .green : .red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                }

                Spacer(minLength: 120)
            }
            .padding(.horizontal, 32)
            }
            .background(theme.background.ignoresSafeArea())

            // FAB positioned at bottom-right
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    IconButton(systemImage: "chevron.right", size: 64) {
                        signUp()
                    }
                    .padding(.trailing, 24)
                    .padding(.bottom, 32)
                    .opacity(isLoading ? 0.5 : 1.0)
                    .disabled(isLoading)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(theme.foreground)
                }
            }
        }
    }
    
    private func signUp() {
        // Validation
        guard !firstName.isEmpty else {
            status = "Error: Please enter your first name"
            return
        }

        guard !lastName.isEmpty else {
            status = "Error: Please enter your last name"
            return
        }

        isLoading = true
        status = ""

        // Update user profile metadata after OTP authentication
        Task {
            do {
                try await authViewModel.updateProfile(
                    firstName: firstName,
                    lastName: lastName
                )

                await MainActor.run {
                    isLoading = false
                    status = "✅ Profile saved!"

                    // Dismiss after successful profile update
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        dismiss()
                    }
                }

            } catch {
                await MainActor.run {
                    isLoading = false
                    status = "Error: \(error.localizedDescription)"
                }
            }
        }
    }
}

#Preview("Light") {
    NavigationStack {
        CreateAccountView()
            .useTheme()
            .useTypography()
            .environmentObject(AuthViewModel())
    }
    .preferredColorScheme(.light)
}

#Preview("Dark") {
    NavigationStack {
        CreateAccountView()
            .useTheme()
            .useTypography()
            .environmentObject(AuthViewModel())
    }
    .preferredColorScheme(.dark)
}
