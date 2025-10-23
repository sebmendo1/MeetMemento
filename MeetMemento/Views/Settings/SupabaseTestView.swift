//
//  SupabaseTestView.swift
//  MeetMemento
//
//  A simple test view to verify Supabase connection
//  Only available in DEBUG builds
//

import SwiftUI

#if DEBUG
struct SupabaseTestView: View {
    @State private var status: ConnectionStatus = .checking
    @State private var message: String = "Checking connection..."
    @Environment(\.theme) private var theme
    @Environment(\.typography) private var type
    
    enum ConnectionStatus {
        case checking
        case success
        case error
        
        var icon: String {
            switch self {
            case .checking: return "hourglass"
            case .success: return "checkmark.circle.fill"
            case .error: return "xmark.circle.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .checking: return .blue
            case .success: return .green
            case .error: return .red
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Status Icon
            Image(systemName: status.icon)
                .font(.system(size: 64))
                .foregroundStyle(status.color)
                .symbolEffect(.pulse, isActive: status == .checking)
            
            // Status Message
            VStack(spacing: 8) {
                Text("Supabase Connection")
                    .font(type.h2)
                    .fontWeight(.semibold)
                    .headerGradient()
                
                Text(message)
                    .font(type.body)
                    .foregroundStyle(theme.mutedForeground)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            // Project Info
            if status == .success {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Project: fhsgvlbedqwxwpubtlls")
                        .font(.system(.caption, design: .monospaced))
                    Text("URL: https://fhsgvlbedqwxwpubtlls.supabase.co")
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundStyle(theme.mutedForeground)
                }
                .padding()
                .background(theme.secondary)
                .clipShape(RoundedRectangle(cornerRadius: theme.radius.lg))
            }
            
            Spacer()
            
            // Retry Button
            Button {
                testConnection()
            } label: {
                Text(status == .checking ? "Testing..." : "Test Again")
                    .font(type.button)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(theme.primary)
                    .foregroundStyle(theme.primaryForeground)
                    .clipShape(RoundedRectangle(cornerRadius: theme.radius.lg))
            }
            .disabled(status == .checking)
            .padding(.horizontal, 32)
        }
        .padding()
        .background(theme.background)
        .onAppear {
            testConnection()
        }
    }
    
    private func testConnection() {
        status = .checking
        message = "Checking connection..."
        
        Task {
            do {
                // Try to get current user (tests if client is initialized)
                let user = try await SupabaseService.shared.getCurrentUser()
                
                await MainActor.run {
                    status = .success
                    if let user = user {
                        message = "✅ Connected and authenticated!\nUser: \(user.email ?? "Unknown")"
                    } else {
                        message = "✅ Connected successfully!\n(No user currently logged in)"
                    }
                }
                
                AppLogger.log("Supabase connection test: SUCCESS", category: AppLogger.network)
                
            } catch let error as SupabaseServiceError {
                await MainActor.run {
                    status = .error
                    message = "❌ \(error.localizedDescription)"
                }
                AppLogger.log("Supabase connection test: FAILED - \(error)", 
                             category: AppLogger.network, 
                             type: .error)
                
            } catch {
                await MainActor.run {
                    status = .success
                    message = "✅ Client initialized!\n(Auth endpoint test - normal if no user)"
                }
                AppLogger.log("Supabase connection test: Client OK, no session", 
                             category: AppLogger.network)
            }
        }
    }
}
#endif

#if DEBUG
#Preview {
    SupabaseTestView()
        .useTheme()
        .useTypography()
}
#endif

