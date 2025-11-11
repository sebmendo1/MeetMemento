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
    @EnvironmentObject var entryViewModel: EntryViewModel

    @State private var showLogoutConfirmation = false
    @State private var showDeleteAccountConfirmation = false
    @State private var isLoggingOut = false
    @State private var isDeletingAccount = false
    @State private var deleteAccountError: String?
    @State private var showDataUsageInfo = false
    @State private var showPaywall = false

    @StateObject private var subscriptionManager = SubscriptionManager()
    @StateObject private var subscriptionService = SubscriptionService.shared

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Subscription Section (at top)
                subscriptionSection

                // Account Section
                accountSection

                // Appearance Section
                appearanceSection

                // About Section
                aboutSection

                // Data & Privacy Section
                dataPrivacySection

                // Danger Zone Section
                dangerZoneSection

                Spacer(minLength: 40)
            }
            .padding(.horizontal, 20)
            .padding(.top, 24)
        }
        .background(theme.background.ignoresSafeArea())
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
        .sheet(isPresented: $showDataUsageInfo) {
            NavigationStack {
                DataUsageInfoView()
                    .useTheme()
                    .useTypography()
            }
        }
        .fullScreenCover(isPresented: $showPaywall) {
            PaywallView(isDismissible: true) {
                Task {
                    await subscriptionManager.checkSubscriptionStatus()
                }
            }
            .environmentObject(subscriptionManager)
        }
        .task {
            await subscriptionManager.checkSubscriptionStatus()
        }
    }

    // MARK: - Sections

    private var subscriptionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section header
            Text("Subscription")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(theme.foreground)
                .padding(.bottom, 4)

            // Section content card
            VStack(spacing: 0) {
                // Subscription status row
                HStack(spacing: 16) {
                    // Icon
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: subscriptionManager.isPremium ?
                                        [Color.blue.opacity(0.2), Color.purple.opacity(0.2)] :
                                        [Color.gray.opacity(0.2), Color.gray.opacity(0.2)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 48, height: 48)

                        Image(systemName: subscriptionManager.isPremium ? "crown.fill" : "crown")
                            .font(.system(size: 22))
                            .foregroundStyle(
                                subscriptionManager.isPremium ?
                                    LinearGradient(
                                        colors: [Color.blue, Color.purple],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ) :
                                    LinearGradient(
                                        colors: [Color.gray, Color.gray],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                            )
                    }
                    .padding(.leading, 16)

                    // Status text
                    VStack(alignment: .leading, spacing: 4) {
                        Text(subscriptionManager.isPremium ? "Premium" : "Free Plan")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(theme.foreground)

                        Text(subscriptionManager.statusMessage)
                            .font(.system(size: 14))
                            .foregroundStyle(theme.foreground.opacity(0.6))
                    }

                    Spacer()
                }
                .padding(.vertical, 16)

                // Manage subscription / Upgrade buttons
                if subscriptionManager.isPremium {
                    Divider()
                        .background(theme.border)
                        .padding(.horizontal, 16)

                    // Manage subscription button
                    Button {
                        openSubscriptionManagement()
                    } label: {
                        SettingsRow(
                            icon: "gearshape.fill",
                            title: "Manage Subscription",
                            subtitle: "View or cancel in App Store",
                            showChevron: true,
                            action: nil
                        )
                    }
                    .buttonStyle(PlainButtonStyle())

                    Divider()
                        .background(theme.border)
                        .padding(.horizontal, 16)

                    // Restore purchases button
                    SettingsRow(
                        icon: "arrow.clockwise.circle.fill",
                        title: "Restore Purchases",
                        subtitle: "Sync subscriptions across devices",
                        showChevron: false,
                        showProgress: subscriptionService.purchaseState.isProcessing,
                        action: {
                            Task {
                                await subscriptionService.restorePurchases()
                            }
                        }
                    )
                } else {
                    Divider()
                        .background(theme.border)
                        .padding(.horizontal, 16)

                    // Upgrade to premium button
                    Button {
                        showPaywall = true
                    } label: {
                        HStack {
                            Image(systemName: "sparkles")
                                .font(.system(size: 20))
                            Text("Upgrade to Premium")
                                .font(.system(size: 17, weight: .semibold))
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .medium))
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 16)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.blue, Color.purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    }
                    .buttonStyle(PlainButtonStyle())

                    Divider()
                        .background(theme.border)
                        .padding(.horizontal, 16)

                    // Restore purchases button
                    SettingsRow(
                        icon: "arrow.clockwise.circle.fill",
                        title: "Restore Purchases",
                        subtitle: "Already subscribed? Restore here",
                        showChevron: false,
                        showProgress: subscriptionService.purchaseState.isProcessing,
                        action: {
                            Task {
                                await subscriptionService.restorePurchases()
                            }
                        }
                    )
                }
            }
            .background(BaseColors.white)
            .cornerRadius(16)
        }
    }

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
            .background(BaseColors.white)
            .cornerRadius(16)
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
            .background(BaseColors.white)
            .cornerRadius(16)
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
            .background(BaseColors.white)
            .cornerRadius(16)
        }
    }

    private var dataPrivacySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section header
            Text("Data & Privacy")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(theme.foreground)
                .padding(.bottom, 4)

            // Section content card
            VStack(spacing: 0) {
                SettingsRow(
                    icon: "hand.raised",
                    title: "Privacy Policy",
                    subtitle: "How we protect your data",
                    showChevron: true,
                    action: {
                        if let url = URL(string: "https://sebmendo1.github.io/MeetMemento/privacy.html") {
                            UIApplication.shared.open(url)
                        }
                    }
                )

                Divider()
                    .background(theme.border)
                    .padding(.horizontal, 16)

                SettingsRow(
                    icon: "info.circle",
                    title: "What Data We Collect",
                    subtitle: "Learn about data usage",
                    showChevron: true,
                    action: {
                        showDataUsageInfo = true
                    }
                )
            }
            .background(BaseColors.white)
            .cornerRadius(16)
        }
    }

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
            .background(BaseColors.white)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
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

    private func openSubscriptionManagement() {
        // Open iOS Settings app subscription management
        if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
            UIApplication.shared.open(url)
        }
    }

}

// MARK: - ShareSheet Helper
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)

        // iPad popover configuration (required to prevent crash on iPad)
        if let popover = controller.popoverPresentationController {
            // Get the window scene to find a source view
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first,
               let rootView = window.rootViewController?.view {
                popover.sourceView = rootView
                popover.sourceRect = CGRect(x: rootView.bounds.midX, y: rootView.bounds.midY, width: 0, height: 0)
                popover.permittedArrowDirections = []
            }
        }

        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    NavigationStack {
        SettingsView()
            .environmentObject(AuthViewModel())
            .environmentObject(EntryViewModel())
            .useTheme()
            .useTypography()
    }
}
