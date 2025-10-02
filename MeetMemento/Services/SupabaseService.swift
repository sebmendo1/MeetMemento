//
//  SupabaseService.swift
//  MeetMemento
//

import Foundation
import Supabase

class SupabaseService {
    static let shared = SupabaseService()
    
    private var client: SupabaseClient?
    var supabase: SupabaseClient? { client }
    
    private init() {
        // Configure your Supabase client
        // Make sure to update SupabaseConfig.swift with your actual credentials
        guard let url = URL(string: SupabaseConfig.url),
              !SupabaseConfig.anonKey.isEmpty,
              SupabaseConfig.anonKey != "YOUR_SUPABASE_ANON_KEY" else {
            AppLogger.log("⚠️ Supabase not configured. Please update SupabaseConfig.swift", 
                         category: AppLogger.network,
                         type: .error)
            return
        }
        
        client = SupabaseClient(
            supabaseURL: url,
            supabaseKey: SupabaseConfig.anonKey
        )
        
        AppLogger.log("✅ Supabase client initialized", category: AppLogger.network)
    }
    
    // MARK: - Authentication
    
    func signIn(email: String, password: String) async throws {
        guard let client = client else {
            throw SupabaseServiceError.clientNotConfigured
        }
        try await client.auth.signIn(email: email, password: password)
    }
    
    func signUp(email: String, password: String) async throws {
        guard let client = client else {
            throw SupabaseServiceError.clientNotConfigured
        }
        try await client.auth.signUp(email: email, password: password)
    }
    
    func signOut() async throws {
        guard let client = client else {
            throw SupabaseServiceError.clientNotConfigured
        }
        try await client.auth.signOut()
    }
    
    func getCurrentUser() async throws -> Supabase.User? {
        guard let client = client else {
            throw SupabaseServiceError.clientNotConfigured
        }
        return try? await client.auth.session.user
    }
    
    // MARK: - Database Operations
    
    // Add your database methods here
    
    // MARK: - Storage Operations
    
    // Add your storage methods here
}

// MARK: - Errors

enum SupabaseServiceError: LocalizedError {
    case clientNotConfigured
    
    var errorDescription: String? {
        switch self {
        case .clientNotConfigured:
            return "Supabase client is not configured. Please set your Supabase URL and anon key."
        }
    }
}
