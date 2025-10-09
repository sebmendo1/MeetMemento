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
    @State private var testResult = ""
    
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
                    
                    Button {
                        testEntryLoading()
                    } label: {
                        HStack {
                            Image(systemName: "doc.text")
                                .foregroundStyle(theme.primary)
                            Text("Test Entry Loading")
                        }
                    }
                    
                    if !testResult.isEmpty {
                        Text(testResult)
                            .font(.caption)
                            .foregroundStyle(theme.mutedForeground)
                            .padding(.vertical, 4)
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
}

#Preview {
    SettingsView()
        .environmentObject(AuthViewModel())
}

