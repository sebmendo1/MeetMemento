//
//  SupabaseService.swift
//  MeetMemento
//

import Foundation
import Supabase

class SupabaseService {
    static let shared = SupabaseService()
    
    private var client: SupabaseClient?
    private var cachedUserId: UUID? // Cache user ID to avoid repeated calls
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
        cachedUserId = nil // Clear cached user ID on sign out
    }
    
    func getCurrentUser() async throws -> Supabase.User? {
        guard let client = client else {
            throw SupabaseServiceError.clientNotConfigured
        }
        return try? await client.auth.session.user
    }
    
    /// Gets the current user ID with caching for better performance
    private func getCurrentUserId() async throws -> UUID {
        if let cachedUserId = cachedUserId {
            return cachedUserId
        }
        
        guard let user = try await getCurrentUser() else {
            throw SupabaseServiceError.userNotAuthenticated
        }
        
        cachedUserId = user.id
        return user.id
    }
    
    // MARK: - Database Operations
    
    /// Fetches entries for the current user, sorted by newest first
    /// - Parameter limit: Maximum number of entries to fetch (default: 50 for initial load)
    func fetchEntries(limit: Int = 50) async throws -> [Entry] {
        guard let client = client else {
            print("❌ Supabase client not configured")
            throw SupabaseServiceError.clientNotConfigured
        }
        
        // Check for cancellation before starting
        try Task.checkCancellation()
        
        print("🔄 Fetching entries from Supabase (limit: \(limit))")
        
        // First, let's test if the table exists and is accessible
        do {
            // Try to get raw data first to see what's actually in the table
            let rawResponse = try await client
                .from("entries")
                .select("*")
                .limit(5)
                .execute()
            
            print("✅ Raw Supabase response: \(rawResponse)")
            print("✅ Response data: \(rawResponse.data)")
            
            // Try to decode as JSON to see the structure
            do {
                let jsonObject = try JSONSerialization.jsonObject(with: rawResponse.data, options: [])
                print("✅ Parsed JSON: \(jsonObject)")
            } catch {
                print("❌ JSON parsing failed: \(error)")
            }
            
            // Now try to decode as Entry objects
            let response: [Entry] = try await withTimeout(seconds: 5) {
                try await client
                    .from("entries")
                    .select()
                    .order("created_at", ascending: false)
                    .limit(limit)
                    .execute()
                    .value
            }
            
            print("✅ Decoded entries: \(response)")
            
            AppLogger.log("✅ Fetched \(response.count) entries from Supabase (limit: \(limit))", 
                         category: AppLogger.network)
            return response
            
        } catch {
            print("❌ Detailed fetch error: \(error)")
            print("❌ Error type: \(type(of: error))")
            print("❌ Error description: \(error.localizedDescription)")
            
            // Check if it's a table not found error
            let errorString = error.localizedDescription.lowercased()
            if errorString.contains("relation") && errorString.contains("does not exist") {
                print("❌ Table 'entries' does not exist in Supabase")
                throw SupabaseServiceError.clientNotConfigured // Using this as a generic error for now
            }
            
            // Check if it's a decoding error
            if errorString.contains("data couldn't be read") || errorString.contains("missing") {
                print("❌ Data decoding error - likely schema mismatch")
                print("❌ Expected fields: id, user_id, title, text, created_at, updated_at, is_follow_up")
            }
            
            throw error
        }
    }
    
    // MARK: - Timeout Helper
    
    private func withTimeout<T>(
        seconds: TimeInterval,
        operation: @escaping () async throws -> T
    ) async throws -> T {
        try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask {
                try await operation()
            }
            
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                throw TimeoutError()
            }
            
            let result = try await group.next()!
            group.cancelAll()
            return result
        }
    }
    
    private struct TimeoutError: Error {
        var localizedDescription: String {
            "Request timed out"
        }
    }
    
    /// Creates a new entry in the database
    func createEntry(title: String, text: String) async throws -> Entry {
        guard let client = client else {
            throw SupabaseServiceError.clientNotConfigured
        }
        
        // Use cached user ID for better performance
        let userId = try await getCurrentUserId()
        
        // Create entry with user_id, but don't include is_follow_up if column doesn't exist
        let newEntry = Entry(
            userId: userId,
            title: title,
            text: text
        )
        
        // Try to insert with all fields first
        do {
            let response: Entry = try await client
                .from("entries")
                .insert(newEntry)
                .select()
                .single()
                .execute()
                .value
            
            AppLogger.log("✅ Created entry: \(response.id)", category: AppLogger.network)
            return response
        } catch {
            // If insertion fails due to missing column, try without is_follow_up
            let errorString = error.localizedDescription.lowercased()
            if errorString.contains("is_follow_up") && errorString.contains("column") {
                print("⚠️ is_follow_up column missing, creating entry without it")
                
                // Create entry without is_follow_up field
                let entryWithoutFollowUp = [
                    "id": newEntry.id.uuidString,
                    "user_id": userId.uuidString,
                    "title": title,
                    "text": text,
                    "created_at": ISO8601DateFormatter().string(from: newEntry.createdAt),
                    "updated_at": ISO8601DateFormatter().string(from: newEntry.updatedAt)
                ]
                
                let response: Entry = try await client
                    .from("entries")
                    .insert(entryWithoutFollowUp)
                    .select()
                    .single()
                    .execute()
                    .value
                
                AppLogger.log("✅ Created entry (without is_follow_up): \(response.id)", category: AppLogger.network)
                return response
            } else {
                throw error
            }
        }
    }
    
    /// Updates an existing entry
    func updateEntry(_ entry: Entry) async throws -> Entry {
        guard let client = client else {
            throw SupabaseServiceError.clientNotConfigured
        }
        
        var updatedEntry = entry
        updatedEntry.updatedAt = Date() // Will be overridden by trigger, but good practice
        
        // Try to update with all fields first
        do {
            let response: Entry = try await client
                .from("entries")
                .update(updatedEntry)
                .eq("id", value: entry.id.uuidString)
                .select()
                .single()
                .execute()
                .value
            
            AppLogger.log("✅ Updated entry: \(response.id)", category: AppLogger.network)
            return response
        } catch {
            // If update fails due to missing column, try without is_follow_up
            let errorString = error.localizedDescription.lowercased()
            if errorString.contains("is_follow_up") && errorString.contains("column") {
                print("⚠️ is_follow_up column missing, updating entry without it")
                
                // Update entry without is_follow_up field
                let entryWithoutFollowUp = [
                    "title": entry.title,
                    "text": entry.text,
                    "updated_at": ISO8601DateFormatter().string(from: updatedEntry.updatedAt)
                ]
                
                let response: Entry = try await client
                    .from("entries")
                    .update(entryWithoutFollowUp)
                    .eq("id", value: entry.id.uuidString)
                    .select()
                    .single()
                    .execute()
                    .value
                
                AppLogger.log("✅ Updated entry (without is_follow_up): \(response.id)", category: AppLogger.network)
                return response
            } else {
                throw error
            }
        }
    }
    
    /// Deletes an entry by ID
    func deleteEntry(id: UUID) async throws {
        guard let client = client else {
            throw SupabaseServiceError.clientNotConfigured
        }
        
        try await client
            .from("entries")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
        
        AppLogger.log("🗑️ Deleted entry: \(id)", category: AppLogger.network)
    }
    
    // MARK: - Storage Operations
    
    // Add your storage methods here
}

// MARK: - Errors

enum SupabaseServiceError: LocalizedError {
    case clientNotConfigured
    case userNotAuthenticated
    
    var errorDescription: String? {
        switch self {
        case .clientNotConfigured:
            return "Supabase client is not configured. Please set your Supabase URL and anon key."
        case .userNotAuthenticated:
            return "User must be authenticated to perform this action."
        }
    }
}
