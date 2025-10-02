//
//  SettingsView.swift
//  MeetMemento
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.theme) private var theme
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showLogoutConfirmation = false
    @State private var isLoggingOut = false
    
    var body: some View {
        NavigationView {
            Form {
                // Account Section
                Section("Account") {
                    if let user = authViewModel.currentUser {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Signed in as")
                                .font(.caption)
                                .foregroundStyle(theme.mutedForeground)
                            Text(user.email ?? "Unknown")
                                .font(.body)
                                .foregroundStyle(theme.foreground)
                        }
                        .padding(.vertical, 4)
                        
                        Button(role: .destructive) {
                            showLogoutConfirmation = true
                        } label: {
                            HStack {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                Text("Sign Out")
                            }
                        }
                        .disabled(isLoggingOut)
                    }
                }
                
                // Development / Testing
                Section("Development") {
                    NavigationLink {
                        SupabaseTestView()
                            .useTheme()
                            .useTypography()
                    } label: {
                        HStack {
                            Image(systemName: "network")
                                .foregroundStyle(theme.primary)
                            Text("Test Supabase Connection")
                        }
                    }
                }
                
                // Add your settings sections here
                Section("General") {
                    Text("Settings coming soon")
                }
            }
            .navigationTitle("Settings")
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
        }
    }
    
    private func signOut() {
        isLoggingOut = true
        
        Task {
            await authViewModel.signOut()
            
            await MainActor.run {
                isLoggingOut = false
            }
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(AuthViewModel())
}

