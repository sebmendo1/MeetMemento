//
//  ProfileSettingsView.swift
//  MeetMemento
//
//  Edit user profile information (name)
//

import SwiftUI

public struct ProfileSettingsView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.theme) private var theme
    @Environment(\.typography) private var type
    @EnvironmentObject var authViewModel: AuthViewModel

    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var isSaving: Bool = false
    @State private var errorMessage: String = ""
    @State private var showSuccessMessage: Bool = false

    public init() {}

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Spacer(minLength: 16)

                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Edit Profile")
                        .font(type.h3)
                        .headerGradient()

                    Text("Update your personal information")
                        .font(type.body)
                        .foregroundStyle(theme.mutedForeground)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 8)

                // Form section
                VStack(alignment: .leading, spacing: 20) {
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

                    // Save button
                    Button {
                        saveProfile()
                    } label: {
                        HStack {
                            if isSaving {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("Save Changes")
                                    .font(type.bodyBold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(canSave ? theme.primary : theme.mutedForeground.opacity(0.3))
                        .foregroundStyle(.white)
                        .cornerRadius(theme.radius.md)
                    }
                    .disabled(!canSave || isSaving)
                    .padding(.top, 8)

                    // Success message
                    if showSuccessMessage {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                                .font(.system(size: 14))
                            Text("Profile updated successfully")
                                .font(type.bodySmall)
                                .foregroundStyle(.green)
                        }
                        .padding(12)
                        .background(Color.green.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: theme.radius.md))
                    }

                    // Error message
                    if !errorMessage.isEmpty {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.red)
                                .font(.system(size: 14))
                            Text(errorMessage)
                                .font(type.bodySmall)
                                .foregroundStyle(.red)
                        }
                        .padding(12)
                        .background(Color.red.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: theme.radius.md))
                    }
                }
                .padding(.horizontal, 16)

                Spacer(minLength: 40)
            }
            .padding(.top, 8)
        }
        .background(theme.background.ignoresSafeArea())
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
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
        .onAppear {
            loadCurrentProfile()
        }
    }

    // MARK: - Computed Properties

    private var canSave: Bool {
        !firstName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !lastName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        firstName.count <= 50 &&
        lastName.count <= 50 &&
        !isSaving
    }

    // MARK: - Actions

    private func loadCurrentProfile() {
        guard let user = authViewModel.currentUser else { return }

        // Pre-fill with current user data using pattern matching for AnyJSON
        if case .string(let firstNameValue) = user.userMetadata["first_name"] {
            firstName = firstNameValue
        }

        if case .string(let lastNameValue) = user.userMetadata["last_name"] {
            lastName = lastNameValue
        }
    }

    private func saveProfile() {
        guard canSave else { return }

        isSaving = true
        errorMessage = ""
        showSuccessMessage = false

        let trimmedFirstName = firstName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedLastName = lastName.trimmingCharacters(in: .whitespacesAndNewlines)

        Task {
            do {
                try await authViewModel.updateProfile(
                    firstName: trimmedFirstName,
                    lastName: trimmedLastName
                )

                await MainActor.run {
                    isSaving = false
                    showSuccessMessage = true

                    // Haptic feedback
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()

                    // Dismiss after short delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        dismiss()
                    }
                }
            } catch {
                await MainActor.run {
                    isSaving = false
                    errorMessage = "Failed to update profile. Please try again."
                }
            }
        }
    }
}

#Preview("Light") {
    NavigationStack {
        ProfileSettingsView()
            .useTheme()
            .useTypography()
            .environmentObject(AuthViewModel())
    }
    .preferredColorScheme(.light)
}

#Preview("Dark") {
    NavigationStack {
        ProfileSettingsView()
            .useTheme()
            .useTypography()
            .environmentObject(AuthViewModel())
    }
    .preferredColorScheme(.dark)
}
