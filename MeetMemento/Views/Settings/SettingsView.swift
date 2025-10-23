//
//  SettingsView.swift
//  MeetMemento
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.theme) private var theme
    @Environment(\.typography) private var type
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authViewModel: AuthViewModel

    @State private var showLogoutConfirmation = false
    @State private var showDeleteAccountConfirmation = false
    @State private var isLoggingOut = false
    @State private var isDeletingAccount = false
    @State private var deleteAccountError: String?
    #if DEBUG
    @State private var testResult = ""
    @State private var showSupabaseTest = false
    #endif

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Account Section
                accountSection

                // Appearance Section
                appearanceSection

                // About Section
                aboutSection

                #if DEBUG
                // Development Section
                developmentSection
                #endif

                // Danger Zone Section
                dangerZoneSection

                Spacer(minLength: 40)
            }
            .padding(.horizontal, 20)
            .padding(.top, 24)
        }
        .background(BaseColors.white.ignoresSafeArea())
        .navigationTitle("Settings")
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
        .confirmationDialog(
            "Sign Out",
            isPresented: $showLogoutConfirmation,
            titleVisibility: .visible
        ) {
            Button("Sign Out", role: .destructive) {
                signOut()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to sign out?")
        }
        .alert(
            "Delete Account",
            isPresented: $showDeleteAccountConfirmation,
            actions: {
                Button("Cancel", role: .cancel) {}
                Button("Delete Account", role: .destructive) {
                    deleteAccount()
                }
            },
            message: {
                Text("⚠️ WARNING: This will permanently delete your account and all journal entries. This action cannot be undone.\n\nAre you absolutely sure you want to continue?")
            }
        )
        #if DEBUG
        .sheet(isPresented: $showSupabaseTest) {
            NavigationStack {
                SupabaseTestView()
                    .useTheme()
                    .useTypography()
            }
        }
        #endif
    }

    // MARK: - Sections

    private var accountSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section header
            Text("Account")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(theme.foreground)
                .padding(.bottom, 4)

            // Section content card
            VStack(spacing: 0) {
                if let user = authViewModel.currentUser {
                    // User info row
                    SettingsRow(
                        icon: "person.circle.fill",
                        title: "Signed in as",
                        subtitle: user.email ?? "Unknown",
                        showChevron: false
                    )

                    Divider()
                        .background(theme.border)
                        .padding(.horizontal, 16)

                    // Profile row
                    NavigationLink(value: SettingsRoute.profile) {
                        SettingsRow(
                            icon: "person.fill",
                            title: "Profile",
                            subtitle: "Edit your name and info",
                            showChevron: true,
                            action: nil
                        )
                    }
                    .buttonStyle(PlainButtonStyle())

                    Divider()
                        .background(theme.border)
                        .padding(.horizontal, 16)

                    // Sign out row
                    SettingsRow(
                        icon: "rectangle.portrait.and.arrow.right",
                        title: "Sign Out",
                        subtitle: nil,
                        showChevron: false,
                        isDestructive: true,
                        showProgress: isLoggingOut,
                        action: {
                            showLogoutConfirmation = true
                        }
                    )
                }
            }
            .background(theme.card)
            .cornerRadius(12)
        }
    }

    private var appearanceSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section header
            Text("Appearance")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(theme.foreground)
                .padding(.bottom, 4)

            // Section content card
            VStack(spacing: 0) {
                NavigationLink(value: SettingsRoute.appearance) {
                    SettingsRow(
                        icon: "paintbrush.fill",
                        title: "Theme & Display",
                        subtitle: "Customize colors and text size",
                        showChevron: true,
                        action: nil
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
            .background(theme.card)
            .cornerRadius(12)
        }
    }

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section header
            Text("About")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(theme.foreground)
                .padding(.bottom, 4)

            // Section content card
            VStack(spacing: 0) {
                NavigationLink(value: SettingsRoute.about) {
                    SettingsRow(
                        icon: "info.circle.fill",
                        title: "About MeetMemento",
                        subtitle: "Version, legal, and support",
                        showChevron: true,
                        action: nil
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
            .background(theme.card)
            .cornerRadius(12)
        }
    }

    #if DEBUG
    private var developmentSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section header
            Text("Development")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(theme.foreground)
                .padding(.bottom, 4)

            // Section content card
            VStack(spacing: 0) {
                SettingsRow(
                    icon: "network",
                    title: "Test Supabase Connection",
                    subtitle: nil,
                    showChevron: true,
                    action: {
                        showSupabaseTest = true
                    }
                )

                Divider()
                    .background(theme.border)
                    .padding(.horizontal, 16)

                SettingsRow(
                    icon: "doc.text",
                    title: "Test Entry Loading",
                    subtitle: testResult.isEmpty ? nil : testResult,
                    showChevron: false,
                    action: {
                        testEntryLoading()
                    }
                )
            }
            .background(theme.card)
            .cornerRadius(12)
        }
    }
    #endif

    private var dangerZoneSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section header
            Text("Danger Zone")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(theme.destructive)
                .padding(.bottom, 4)

            // Section content card
            VStack(spacing: 0) {
                SettingsRow(
                    icon: "trash.fill",
                    title: isDeletingAccount ? "Deleting Account..." : "Delete Account",
                    subtitle: "Permanently delete your account and all data",
                    showChevron: false,
                    isDestructive: true,
                    showProgress: isDeletingAccount,
                    action: {
                        showDeleteAccountConfirmation = true
                    }
                )

                // Error message if present
                if let error = deleteAccountError {
                    VStack(alignment: .leading, spacing: 8) {
                        Divider()
                            .background(theme.border)
                            .padding(.horizontal, 16)

                        Text(error)
                            .font(.system(size: 14))
                            .foregroundStyle(theme.destructive)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                    }
                }
            }
            .background(theme.card)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(theme.destructive.opacity(0.3), lineWidth: 1)
            )
        }
    }

    // MARK: - Actions

    private func signOut() {
        isLoggingOut = true

        Task {
            await authViewModel.signOut()

            await MainActor.run {
                isLoggingOut = false
            }
        }
    }

    private func deleteAccount() {
        isDeletingAccount = true
        deleteAccountError = nil

        Task {
            do {
                try await authViewModel.deleteAccount()

                await MainActor.run {
                    isDeletingAccount = false
                    // User will be automatically redirected to login by MeetMementoApp
                    // when isAuthenticated becomes false
                }
            } catch {
                await MainActor.run {
                    isDeletingAccount = false

                    // Check if it's a data deletion error (more serious)
                    let errorString = error.localizedDescription.lowercased()
                    if errorString.contains("entries") || errorString.contains("table") {
                        deleteAccountError = "Failed to delete your data: \(error.localizedDescription)"
                    } else {
                        // If it's just the auth deletion that failed, that's less critical
                        deleteAccountError = "Your data has been deleted but account removal failed: \(error.localizedDescription)"
                    }

                    // Log the error for debugging
                    AppLogger.log("Account deletion failed: \(error.localizedDescription)",
                                 category: AppLogger.general,
                                 type: .error)
                }
            }
        }
    }

    #if DEBUG
    private func testEntryLoading() {
        testResult = "Testing..."

        Task {
            do {
                // Test authentication first
                let user = try await SupabaseService.shared.getCurrentUser()
                print("✅ User authenticated: \(user?.email ?? "Unknown")")

                // Test fetching entries
                let entries = try await SupabaseService.shared.fetchEntries()
                print("✅ Fetched \(entries.count) entries")

                await MainActor.run {
                    if let user = user {
                        testResult = "✅ Success! User: \(user.email ?? "Unknown"), Found \(entries.count) entries"
                    } else {
                        testResult = "⚠️ No user authenticated, but connection works"
                    }
                }
            } catch {
                print("❌ Test failed: \(error)")
                await MainActor.run {
                    let errorDesc = error.localizedDescription
                    if errorDesc.contains("data couldn't be read") || errorDesc.contains("missing") {
                        testResult = "❌ Schema Error: \(errorDesc)\n\nCheck console for detailed logs"
                    } else {
                        testResult = "❌ Failed: \(errorDesc)"
                    }
                }
            }
        }
    }
    #endif
}

#Preview {
    NavigationStack {
        SettingsView()
            .environmentObject(AuthViewModel())
            .useTheme()
            .useTypography()
    }
}
