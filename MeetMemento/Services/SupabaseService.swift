//
//  SupabaseService.swift
//  MeetMemento
//

import Foundation
import Supabase

class SupabaseService {
    static let shared = SupabaseService()

    internal var client: SupabaseClient?
    private var cachedUserId: UUID? // Cache user ID to avoid repeated calls
    private var isInitialized = false
    var supabase: SupabaseClient? { client }

    private init() {
        // Don't initialize client here - do it lazily on first use
        print("🔵 SupabaseService init() called")
    }

    /// Lazily initialize the Supabase client on first use
    private func ensureClientInitialized() {
        guard !isInitialized else {
            print("🔵 SupabaseService: Already initialized")
            return
        }
        isInitialized = true

        print("🔵 SupabaseService: Initializing client...")

        // Configure your Supabase client
        // Make sure to update SupabaseConfig.swift with your actual credentials
        print("🔵 SupabaseService: Checking config...")
        print("   URL: \(SupabaseConfig.url)")
        print("   Has anon key: \(!SupabaseConfig.anonKey.isEmpty)")

        guard let url = URL(string: SupabaseConfig.url),
              !SupabaseConfig.anonKey.isEmpty,
              SupabaseConfig.anonKey != "YOUR_SUPABASE_ANON_KEY" else {
            print("❌ Supabase not configured properly")
            AppLogger.log("⚠️ Supabase not configured. Please update SupabaseConfig.swift",
                         category: AppLogger.network,
                         type: .error)
            return
        }

        print("🔵 SupabaseService: Config valid, creating SupabaseClient...")
        do {
            client = SupabaseClient(
                supabaseURL: url,
                supabaseKey: SupabaseConfig.anonKey
            )
            print("✅ Supabase client created successfully")
            AppLogger.log("✅ Supabase client initialized", category: AppLogger.network)
        } catch {
            print("❌ SupabaseClient creation failed: \(error)")
            AppLogger.log("❌ SupabaseClient creation failed: \(error.localizedDescription)",
                         category: AppLogger.network,
                         type: .error)
        }
    }
    
    // MARK: - Authentication
    // Note: App uses 3 authentication methods only:
    // 1. Google Sign In (OAuth)
    // 2. Apple Sign In (Native)
    // 3. Email OTP (Passwordless)

    func signOut() async throws {
        ensureClientInitialized()
        guard let client = client else {
            throw SupabaseServiceError.clientNotConfigured
        }
        try await client.auth.signOut()
        cachedUserId = nil // Clear cached user ID on sign out
    }
    
    func getCurrentUser() async throws -> Supabase.User? {
        print("🔵 SupabaseService.getCurrentUser() called")

        do {
            ensureClientInitialized()
            print("🔵 getCurrentUser: Client initialized")
        } catch {
            print("❌ getCurrentUser: Client initialization failed - \(error)")
            throw SupabaseServiceError.clientNotConfigured
        }

        guard let client = client else {
            print("⚠️ getCurrentUser: Client is nil after initialization")
            throw SupabaseServiceError.clientNotConfigured
        }

        print("🔵 getCurrentUser: Fetching session...")
        // Use proper async API instead of potentially synchronous .session property
        do {
            print("🔵 getCurrentUser: About to call client.auth.session...")
            let session = try await client.auth.session
            print("✅ getCurrentUser: Got session, user = \(session.user.email ?? "unknown")")
            return session.user
        } catch let error as NSError {
            print("⚠️ getCurrentUser: Session fetch error")
            print("   Domain: \(error.domain)")
            print("   Code: \(error.code)")
            print("   Description: \(error.localizedDescription)")
            print("   User Info: \(error.userInfo)")
            // Don't throw - return nil for "no session" case
            return nil
        } catch {
            print("⚠️ getCurrentUser: Unknown error type - \(type(of: error))")
            print("   Error: \(error)")
            return nil
        }
    }

    // MARK: - Passwordless Authentication (OTP)

    /// Sends a 6-digit OTP code to the user's email
    /// Note: OTP vs Magic Link is determined by Supabase email template configuration
    /// Make sure your email template uses {{ .Token }} not {{ .ConfirmationURL }}
    func signInWithOTP(email: String) async throws {
        guard let client = client else {
            throw SupabaseServiceError.clientNotConfigured
        }
        // Send OTP - no redirectTo parameter means email template controls the format
        try await client.auth.signInWithOTP(email: email)
        AppLogger.log("✅ OTP sent to \(email)", category: AppLogger.network)
    }

    /// Verifies the OTP code entered by user
    func verifyOTP(email: String, token: String) async throws {
        guard let client = client else {
            throw SupabaseServiceError.clientNotConfigured
        }
        try await client.auth.verifyOTP(
            email: email,
            token: token,
            type: .email
        )
        AppLogger.log("✅ OTP verified for \(email)", category: AppLogger.network)
    }

    /// Updates user metadata (name, profile info, etc.)
    func updateUserMetadata(firstName: String, lastName: String) async throws {
        guard let client = client else {
            throw SupabaseServiceError.clientNotConfigured
        }

        let attributes = UserAttributes(
            data: [
                "first_name": .string(firstName),
                "last_name": .string(lastName)
            ]
        )

        try await client.auth.update(user: attributes)
        AppLogger.log("✅ User metadata updated", category: AppLogger.network)
    }

    // MARK: - Onboarding Methods

    /// Saves user's personalization text for AI prompt customization
    func updateUserPersonalization(_ text: String) async throws {
        guard let client = client else {
            throw SupabaseServiceError.clientNotConfigured
        }

        let attributes = UserAttributes(
            data: ["user_personalization_node": .string(text)]
        )

        try await client.auth.update(user: attributes)
        AppLogger.log("✅ User personalization saved", category: AppLogger.network)
    }

    /// Saves user's selected themes from onboarding
    func updateUserThemes(_ themes: [String]) async throws {
        guard let client = client else {
            throw SupabaseServiceError.clientNotConfigured
        }

        let themesJSON = themes.joined(separator: ",")
        let attributes = UserAttributes(
            data: ["selected_themes": .string(themesJSON)]
        )

        try await client.auth.update(user: attributes)
        AppLogger.log("✅ User themes saved: \(themes.count) themes", category: AppLogger.network)
    }

    /// Marks onboarding as complete for the user
    func completeUserOnboarding() async throws {
        guard let client = client else {
            throw SupabaseServiceError.clientNotConfigured
        }

        let attributes = UserAttributes(
            data: ["onboarding_completed": .bool(true)]
        )

        try await client.auth.update(user: attributes)
        AppLogger.log("✅ Onboarding marked as complete", category: AppLogger.network)
    }

    /// Checks if user has completed onboarding
    /// - Parameter user: Optional user to check. If nil, fetches current user.
    func hasCompletedOnboarding(user: Supabase.User? = nil) async throws -> Bool {
        // Use provided user or fetch current user
        let userToCheck: Supabase.User?
        if let user = user {
            userToCheck = user
        } else {
            userToCheck = try await getCurrentUser()
        }

        guard let userToCheck = userToCheck else {
            return false
        }

        // Check for onboarding_completed flag in user metadata
        if case .bool(let completed) = userToCheck.userMetadata["onboarding_completed"] {
            return completed
        }

        return false
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

    // MARK: - Entry Statistics & Counting

    /// Gets the total number of journal entries for the current user
    /// Returns: Integer count of entries
    func getUserEntryCount() async throws -> Int {
        guard let client = client else {
            throw SupabaseServiceError.clientNotConfigured
        }

        // Call the get_user_entry_count() SQL function
        let count: Int = try await client
            .rpc("get_user_entry_count")
            .execute()
            .value

        AppLogger.log("📊 User has \(count) journal entries", category: AppLogger.network)
        return count
    }

    /// Gets detailed statistics about the user's journal entries
    /// Returns: EntryStats object with total, weekly, monthly counts and dates
    func getUserEntryStats() async throws -> EntryStats {
        guard let client = client else {
            throw SupabaseServiceError.clientNotConfigured
        }

        // Call the get_user_entry_stats() SQL function
        // Note: Function returns a single-row table, so we get first element
        let statsArray: [EntryStats] = try await client
            .rpc("get_user_entry_stats")
            .execute()
            .value

        guard let stats = statsArray.first else {
            // Return empty stats if no data
            return EntryStats(
                totalEntries: 0,
                entriesThisWeek: 0,
                entriesThisMonth: 0,
                firstEntryDate: nil,
                lastEntryDate: nil
            )
        }

        AppLogger.log("📊 Entry stats - Total: \(stats.totalEntries), Week: \(stats.entriesThisWeek), Month: \(stats.entriesThisMonth)",
                     category: AppLogger.network)
        return stats
    }

    // MARK: - Account Deletion

    /// Deletes the user's account and all associated data
    /// WARNING: This action is irreversible
    ///
    /// NOTE: For complete account deletion, a database function should be set up in Supabase.
    /// If the function is not set up, user data will be deleted but the auth account will remain
    /// (user will be signed out and can't access their data anymore).
    ///
    /// To set up the function, run this SQL in your Supabase SQL Editor:
    /// ```sql
    /// CREATE OR REPLACE FUNCTION delete_user()
    /// RETURNS void
    /// LANGUAGE plpgsql
    /// SECURITY DEFINER
    /// AS $$
    /// BEGIN
    ///   DELETE FROM auth.users WHERE id = auth.uid();
    /// END;
    /// $$;
    /// ```
    func deleteAccount() async throws {
        guard let client = client else {
            throw SupabaseServiceError.clientNotConfigured
        }

        // Get user ID before deleting
        let userId = try await getCurrentUserId()

        // Step 1: Delete all user entries from database
        do {
            try await client
                .from("entries")
                .delete()
                .eq("user_id", value: userId.uuidString)
                .execute()

            AppLogger.log("🗑️ Deleted all entries for user: \(userId)", category: AppLogger.network)
        } catch {
            AppLogger.log("❌ Failed to delete user entries: \(error.localizedDescription)",
                         category: AppLogger.network,
                         type: .error)
            throw error
        }

        // Step 2: Try to delete user account from auth (requires database function)
        // This will also delete user metadata automatically
        do {
            try await client.rpc("delete_user").execute()
            AppLogger.log("✅ User account fully deleted from auth: \(userId)", category: AppLogger.network)
        } catch {
            // If delete_user function doesn't exist, that's okay - user data is deleted
            // The user will be signed out and can't access their data anymore
            AppLogger.log("⚠️ Could not delete auth account (RPC function may not exist). User data has been deleted. User will be signed out.",
                         category: AppLogger.network,
                         type: .default)
            // Don't throw - allow the process to continue since data is deleted
        }

        // Clear cached user ID
        cachedUserId = nil
    }

    // MARK: - Storage Operations

    // Add your storage methods here
}

// MARK: - Data Models

/// Statistics about a user's journal entries
/// Returned by getUserEntryStats() function
struct EntryStats: Codable {
    let totalEntries: Int
    let entriesThisWeek: Int
    let entriesThisMonth: Int
    let firstEntryDate: String?
    let lastEntryDate: String?

    enum CodingKeys: String, CodingKey {
        case totalEntries = "total_entries"
        case entriesThisWeek = "entries_this_week"
        case entriesThisMonth = "entries_this_month"
        case firstEntryDate = "first_entry_date"
        case lastEntryDate = "last_entry_date"
    }

    /// Convenience computed property for first entry as Date
    var firstEntryAsDate: Date? {
        guard let dateString = firstEntryDate else { return nil }
        return ISO8601DateFormatter().date(from: dateString)
    }

    /// Convenience computed property for last entry as Date
    var lastEntryAsDate: Date? {
        guard let dateString = lastEntryDate else { return nil }
        return ISO8601DateFormatter().date(from: dateString)
    }
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
