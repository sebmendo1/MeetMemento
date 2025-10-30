//
//  InsightViewModel.swift
//  MeetMemento
//
//  ViewModel for managing AI-generated journal insights with intelligent caching
//  Communicates with generate-insights edge function
//

import Foundation
import SwiftUI
import Supabase

@MainActor
class InsightViewModel: ObservableObject {
    // MARK: - Published Properties

    /// Current insights (nil if not loaded yet)
    @Published var insights: JournalInsights?

    /// Loading state
    @Published var isLoading = false

    /// Error message (nil if no error)
    @Published var errorMessage: String?

    /// Whether insights are from cache
    @Published var isFromCache = false

    // MARK: - Private Properties

    private let supabaseService = SupabaseService.shared
    private let insightsService = InsightsService.shared
    private let migratedFlagKey = "insightsMigratedToDatabase"

    /// Tracks the entry count for which insights were last loaded
    /// Used to prevent redundant reloads when switching tabs
    private var lastAnalyzedEntryCount: Int = 0

    // Helper function to generate user-specific cache key
    private func cacheKey(for userId: UUID) -> String {
        return "insights_\(userId.uuidString)"
    }

    // Real-time subscription
    private var realtimeChannel: RealtimeChannelV2?
    private var isRealtimeSyncEnabled = false

    // MARK: - Initialization

    init() {
        // NOTE: Don't load insights in init - requires async user ID fetch
        // Insights will be loaded in generateInsights() which is async
        // NOTE: Don't set up real-time sync here - Supabase client may not be configured yet
        // It will be set up lazily on first generateInsights() call
        AppLogger.log("🔵 InsightViewModel initialized", category: AppLogger.network)
    }

    deinit {
        // Note: Real-time cleanup should be called explicitly via cleanup() method
        // before view is destroyed to ensure proper unsubscription
        AppLogger.log("🔵 InsightViewModel deinitialized", category: AppLogger.network)
    }

    /// Explicitly cleanup real-time subscription
    /// Call this method when the view is about to disappear
    func cleanup() async {
        if let channel = realtimeChannel {
            await channel.unsubscribe()
            realtimeChannel = nil
            AppLogger.log("🔌 Real-time subscription cleaned up", category: AppLogger.network)
        }
    }

    // MARK: - Public Methods

    /// Generates insights from journal entries
    /// - Parameter entries: Array of journal entries to analyze (max 20)
    /// - Note: The edge function handles caching automatically
    /// - Note: Only generates new insights when count == 3 OR (count >= 6 AND count % 3 == 0)
    func generateInsights(from entries: [Entry]) async {
        // GUARD: Prevent duplicate calls while loading
        guard !isLoading else {
            AppLogger.log("⏭️ Already generating insights, skipping duplicate call", category: AppLogger.network)
            return
        }

        // Set up real-time sync lazily on first call (after auth is likely ready)
        setupRealtimeSyncIfNeeded()

        // Perform one-time migration lazily
        await migrateOldInsightsIfNeeded()

        guard !entries.isEmpty else {
            errorMessage = "No entries to analyze"
            AppLogger.log("⚠️ Cannot generate insights: no entries provided", category: AppLogger.network, type: .error)
            return
        }

        let entryCount = entries.count

        // OPTIMIZATION: Skip if we already have insights for this exact entry count
        // This prevents redundant reloads when switching tabs
        if entryCount == lastAnalyzedEntryCount && insights != nil {
            AppLogger.log("⏭️ Insights already loaded for \(entryCount) entries, skipping reload", category: AppLogger.network)
            return
        }

        // COST OPTIMIZATION: Smart insight generation strategy
        // 1. First try to load existing insights from cache/database
        // 2. Only generate fresh insights if none found AND at a milestone

        // Case 1: Less than 3 entries - show progress state
        if entryCount < 3 {
            errorMessage = "Write \(3 - entryCount) more \(entryCount == 2 ? "entry" : "entries") to unlock insights"
            AppLogger.log("⚠️ Not enough entries: \(entryCount)/3 required", category: AppLogger.network)
            return
        }

        // Case 2: Try to load existing insights from memory/cache/database FIRST
        // This prevents unnecessary API calls on app restart
        if insights == nil {
            AppLogger.log("🔍 Attempting to load insights from cache/database (count: \(entryCount))...", category: AppLogger.network)

            // Try UserDefaults cache (fast, offline)
            let cachedInsights = await loadPersistedInsights()

            // Try database (cloud, cross-device)
            let dbInsights = await loadInsightsFromDatabase(forEntryCount: entryCount)

            // Calculate the current milestone to validate cached data
            let currentMilestone = calculateMilestone(for: entryCount)

            // Validate cached insights match current milestone
            let validCached = cachedInsights.flatMap { insights in
                insights.entryCountMilestone == currentMilestone ? insights : nil
            }

            let validDb = dbInsights.flatMap { insights in
                insights.entryCountMilestone == currentMilestone ? insights : nil
            }

            // Use whichever is most recent (and valid for current milestone)
            if let cached = validCached, let db = validDb {
                // Both exist and match milestone - use the newest
                insights = cached.generatedAt > db.generatedAt ? cached : db
                AppLogger.log("💾 Using \(insights?.generatedAt == cached.generatedAt ? "cached" : "database") insights (milestone \(currentMilestone), newer)", category: AppLogger.network)

                // Update cache if database was newer
                if insights?.generatedAt == db.generatedAt {
                    await saveInsightsToCache(db)
                }
            } else if let cached = validCached {
                // Only valid cache exists for current milestone
                insights = cached
                AppLogger.log("💾 Using cached insights for milestone \(currentMilestone)", category: AppLogger.network)
            } else if let db = validDb {
                // Only valid database insights exist for current milestone
                insights = db
                await saveInsightsToCache(db)
                AppLogger.log("☁️ Using database insights for milestone \(currentMilestone)", category: AppLogger.network)
            } else {
                // No valid insights found for current milestone (may be stale data)
                if cachedInsights != nil || dbInsights != nil {
                    AppLogger.log("⚠️ Found cached insights but milestone doesn't match (current: \(currentMilestone))", category: AppLogger.network)
                }
            }
        }

        // If we successfully loaded insights, use them and return
        if insights != nil {
            errorMessage = nil
            self.lastAnalyzedEntryCount = entryCount
            AppLogger.log("💾 Using existing insights (count: \(entryCount), no new generation needed)", category: AppLogger.network)
            return
        }

        // Case 3: No existing insights found - determine if we should generate fresh ones
        let isAtMilestone = (entryCount == 3) || (entryCount >= 6 && entryCount % 3 == 0)

        if !isAtMilestone {
            // Not at a milestone - show progress message
            let nextMilestone = ((entryCount / 3) + 1) * 3
            let entriesNeeded = nextMilestone - entryCount
            errorMessage = "Write \(entriesNeeded) more \(entriesNeeded == 1 ? "entry" : "entries") for new insights"
            AppLogger.log("ℹ️ Not at milestone (\(entryCount) entries) - waiting for next milestone", category: AppLogger.network)
            return
        }

        // We are at a milestone and no insights exist - generate fresh ones
        let milestone = calculateMilestone(for: entryCount)
        AppLogger.log("✅ At milestone \(milestone) with no existing insights - generating fresh insights", category: AppLogger.network)

        // If we reach here, we ARE at a milestone and SHOULD generate fresh insights
        // Clear any existing insights from memory to ensure fresh generation
        if insights != nil {
            AppLogger.log("🔄 Clearing existing insights from memory to force fresh generation at milestone \(entryCount)", category: AppLogger.network)
            insights = nil
        }

        // Validate entry count (edge function limits to 20)
        let entriesToAnalyze = Array(entries.prefix(20))
        if entries.count > 20 {
            AppLogger.log("⚠️ Too many entries (\(entries.count)). Using first 20 only.", category: AppLogger.network)
        }

        isLoading = true
        errorMessage = nil

        do {
            // Call edge function with force refresh at milestones
            // This ensures fresh insights are generated at each milestone (3, 6, 9, 12...)
            // and bypasses the edge function's 7-day cache
            let response = try await callGenerateInsightsFunction(entries: entriesToAnalyze, forceRefresh: true)

            // Calculate the milestone this insight represents
            let milestone = calculateMilestone(for: entryCount)

            // Create insights with milestone
            let insightsWithMilestone = JournalInsights(
                summary: response.summary,
                description: response.description,
                annotations: response.annotations,
                themes: response.themes,
                entriesAnalyzed: response.entriesAnalyzed,
                entryCountMilestone: milestone,
                generatedAt: response.generatedAt,
                fromCache: response.fromCache,
                cacheExpiresAt: response.cacheExpiresAt
            )

            // Update state
            self.insights = insightsWithMilestone
            self.isFromCache = response.fromCache
            self.lastAnalyzedEntryCount = entryCount  // Track that we've loaded insights for this count

            // Save to UserDefaults for local cache (fast offline access)
            await saveInsightsToCache(insightsWithMilestone)

            // Save to Supabase database (cloud sync) - synchronously for reliability
            do {
                try await insightsService.saveInsights(insightsWithMilestone, for: milestone)
                AppLogger.log("☁️ Insights synced to cloud for milestone \(milestone)", category: AppLogger.network)
            } catch {
                // Don't fail the whole operation if database save fails - cache still works
                AppLogger.log("⚠️ Failed to sync insights to cloud: \(error.localizedDescription) - Using cache only", category: AppLogger.network, type: .error)
            }

            // Log success
            let cacheStatus = response.fromCache ? "from cache" : "freshly generated"
            AppLogger.log("✅ Insights loaded (\(cacheStatus)): \(response.themes.count) themes", category: AppLogger.network)

            if response.fromCache {
                AppLogger.log("💾 Cache expires at: \(response.cacheExpiresAt?.formatted() ?? "unknown")", category: AppLogger.network)
            }

        } catch let error as InsightsError {
            // Handle known errors
            handleInsightsError(error)
        } catch {
            // Handle unknown errors
            errorMessage = "Failed to generate insights: \(error.localizedDescription)"
            AppLogger.log("❌ Insights generation failed: \(error.localizedDescription)", category: AppLogger.network, type: .error)
        }

        isLoading = false
    }

    /// Clears current insights and error state
    /// - Parameter deleteFromDatabase: If true, also deletes from Supabase database (default: false)
    func clearInsights(deleteFromDatabase: Bool = false) {
        insights = nil
        errorMessage = nil
        isFromCache = false

        // Clear user-specific cache
        Task {
            if let client = supabaseService.client,
               let session = try? await client.auth.session {
                let userId = session.user.id
                let key = cacheKey(for: userId)
                UserDefaults.standard.removeObject(forKey: key)
                AppLogger.log("🗑️ Cleared cache for user: \(userId.uuidString.prefix(8))...", category: AppLogger.network)
            }

            // Also clear old global cache key (migration cleanup)
            UserDefaults.standard.removeObject(forKey: "lastGeneratedInsights")

            // Optionally delete from database (for complete reset)
            if deleteFromDatabase {
                do {
                    try await insightsService.deleteAllInsights()
                    AppLogger.log("☁️ Insights deleted from cloud database", category: AppLogger.network)
                } catch {
                    AppLogger.log("⚠️ Failed to delete insights from cloud: \(error.localizedDescription)", category: AppLogger.network, type: .error)
                }
            }
        }
    }

    /// Checks if insights need refresh (cache older than 24 hours)
    var shouldRefreshInsights: Bool {
        guard let insights = insights, insights.fromCache else {
            return false
        }

        let hoursSinceGeneration = Date().timeIntervalSince(insights.generatedAt) / 3600
        return hoursSinceGeneration > 24
    }

    // MARK: - Private Methods

    /// Calls the generate-insights edge function
    /// - Parameter forceRefresh: If true, bypasses edge function cache and generates fresh insights
    private func callGenerateInsightsFunction(entries: [Entry], forceRefresh: Bool = false) async throws -> JournalInsights {
        guard let client = supabaseService.client else {
            throw InsightsError.clientNotConfigured
        }

        // STEP 1: Verify authentication first
        #if DEBUG
        print("🔐 Checking authentication...")
        #endif
        do {
            let session = try await client.auth.session
            #if DEBUG
            print("✅ Authenticated as user: \(session.user.id.uuidString.prefix(8))...")
            print("   Access token length: \(session.accessToken.count) chars")
            print("   Token expires at: \(session.expiresAt ?? 0)")
            #endif
        } catch {
            #if DEBUG
            print("❌ Authentication check failed: \(error)")
            #endif
            throw InsightsError.authenticationFailed
        }

        // Format entries for edge function
        let journalEntries = entries.map { entry in
            JournalEntryRequest(
                date: ISO8601DateFormatter().string(from: entry.createdAt),
                title: entry.title,
                content: entry.text,
                wordCount: entry.text.split(separator: " ").count,
                mood: nil // Add mood support when available
            )
        }

        let requestBody = GenerateInsightsRequest(entries: journalEntries, forceRefresh: forceRefresh ? true : nil)

        #if DEBUG
        print("🔄 Calling generate-insights function with \(entries.count) entries\(forceRefresh ? " (FORCE REFRESH)" : "")")
        #endif
        AppLogger.log("🔄 Calling generate-insights function with \(entries.count) entries\(forceRefresh ? " (FORCE REFRESH)" : "")", category: AppLogger.network)

        // Call edge function
        #if DEBUG
        print("🌐 About to call edge function...")
        #endif

        // Get the session for authentication
        let session = try await client.auth.session
        let accessToken = session.accessToken

        // ALTERNATIVE APPROACH: Use URLSession directly for better debugging
        let functionUrl = URL(string: "https://fhsgvlbedqwxwpubtlls.supabase.co/functions/v1/generate-insights")!

        var request = URLRequest(url: functionUrl)
        request.httpMethod = "POST"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")

        // Encode request body
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        request.httpBody = try encoder.encode(requestBody)

        #if DEBUG
        print("   Request URL: \(functionUrl)")
        print("   Request headers: Authorization=Bearer \(accessToken.prefix(20))..., apikey=\(SupabaseConfig.anonKey.prefix(20))...")
        print("   Request body size: \(request.httpBody?.count ?? 0) bytes")
        #endif

        let responseData: Data
        let httpResponse: HTTPURLResponse
        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResp = response as? HTTPURLResponse else {
                #if DEBUG
                print("❌ Response is not HTTPURLResponse")
                #endif
                throw InsightsError.networkError("Invalid response type")
            }

            httpResponse = httpResp
            responseData = data

            #if DEBUG
            print("✅ HTTP Response received:")
            print("   Status code: \(httpResponse.statusCode)")
            print("   Headers: \(httpResponse.allHeaderFields)")
            print("   Response data size: \(data.count) bytes")

            // Print raw response
            if let rawString = String(data: data, encoding: .utf8) {
                print("   Raw response: \(rawString.prefix(1000))")
            }
            #endif

            // Check if it's an error status code
            if httpResponse.statusCode >= 400 {
                #if DEBUG
                print("❌ HTTP error status code: \(httpResponse.statusCode)")
                if let errorString = String(data: data, encoding: .utf8) {
                    print("   Error response: \(errorString)")
                }
                #endif
                throw InsightsError.serverError("HTTP \(httpResponse.statusCode)", code: "\(httpResponse.statusCode)")
            }
        } catch {
            #if DEBUG
            print("❌ HTTP request failed with error: \(error)")
            print("❌ Error type: \(type(of: error))")
            print("❌ Error description: \(error.localizedDescription)")
            #endif
            throw InsightsError.networkError("Failed to call edge function: \(error.localizedDescription)")
        }

        // Response data is already logged above, now decode it
        var data: Data = responseData
        #if DEBUG
        print("📦 Processing response data...")
        #endif
        AppLogger.log("📦 Processing response data", category: AppLogger.network)

        // Check if response is double-encoded (string containing JSON)
        if let rawJSON = String(data: data, encoding: .utf8) {
            #if DEBUG
            print("📦 Raw JSON type check...")
            #endif

            // Check if response is DOUBLE-ENCODED (string containing JSON)
            if rawJSON.hasPrefix("\"") && rawJSON.hasSuffix("\"") {
                #if DEBUG
                print("⚠️ Response appears to be string-encoded JSON - unwrapping...")
                #endif
                AppLogger.log("⚠️ Response appears to be string-encoded JSON - unwrapping...", category: AppLogger.network)

                // Remove outer quotes and unescape
                var unescaped = rawJSON
                unescaped.removeFirst()  // Remove leading "
                unescaped.removeLast()   // Remove trailing "
                unescaped = unescaped.replacingOccurrences(of: "\\\"", with: "\"")
                unescaped = unescaped.replacingOccurrences(of: "\\n", with: "\n")
                unescaped = unescaped.replacingOccurrences(of: "\\t", with: "\t")
                unescaped = unescaped.replacingOccurrences(of: "\\\\", with: "\\")

                #if DEBUG
                print("📦 Unwrapped JSON (first 500 chars): \(unescaped.prefix(500))")
                #endif
                AppLogger.log("📦 Unwrapped JSON: \(unescaped.prefix(500))", category: AppLogger.network)

                // Replace data with unwrapped version
                if let unwrappedData = unescaped.data(using: .utf8) {
                    data = unwrappedData
                    #if DEBUG
                    print("✅ Successfully created unwrapped data: \(data.count) bytes")
                    #endif
                }
            } else {
                #if DEBUG
                print("ℹ️ Response is NOT double-encoded, using as-is")
                #endif
            }
        } else {
            #if DEBUG
            print("❌ Could not convert response data to UTF-8 string")
            #endif
        }

        // Decode response
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        #if DEBUG
        print("🔄 Attempting to decode JSON with \(data.count) bytes...")
        #endif
        AppLogger.log("🔄 Attempting to decode JSON...", category: AppLogger.network)

        do {
            let insights = try decoder.decode(JournalInsights.self, from: data)
            #if DEBUG
            print("✅ Successfully decoded insights: \(insights.themes.count) themes")
            #endif
            AppLogger.log("✅ Successfully decoded insights", category: AppLogger.network)
            return insights
        } catch {
            #if DEBUG
            print("❌ Decoding error: \(error)")
            print("❌ Error localized description: \(error.localizedDescription)")
            #endif
            AppLogger.log("❌ Decoding error: \(error)", category: AppLogger.network, type: .error)

            // Try to decode error response
            if let errorResponse = try? decoder.decode(InsightsErrorResponse.self, from: data) {
                #if DEBUG
                print("🔴 Server error response: \(errorResponse.error)")
                print("🔴 Error code: \(errorResponse.code)")
                if let debug = errorResponse.debug {
                    print("🔴 DEBUG INFO:")
                    print("   - Message: \(debug.message ?? "none")")
                    print("   - Type: \(debug.type ?? "none")")
                    print("   - Stack: \(debug.stack ?? "none")")
                }
                #endif
                throw InsightsError.serverError(errorResponse.error, code: errorResponse.code)
            }

            // Log detailed decoding error
            if let decodingError = error as? DecodingError {
                #if DEBUG
                print("❌ DecodingError details: \(decodingError)")
                #endif
                AppLogger.log("❌ Decoding error details: \(decodingError)", category: AppLogger.network, type: .error)

                #if DEBUG
                // Print more specific info
                switch decodingError {
                case .keyNotFound(let key, let context):
                    print("❌ Missing key: \(key.stringValue) - \(context.debugDescription)")
                case .typeMismatch(let type, let context):
                    print("❌ Type mismatch: expected \(type) - \(context.debugDescription)")
                case .valueNotFound(let type, let context):
                    print("❌ Value not found: \(type) - \(context.debugDescription)")
                case .dataCorrupted(let context):
                    print("❌ Data corrupted: \(context.debugDescription)")
                @unknown default:
                    print("❌ Unknown decoding error")
                }
                #endif
            }

            throw InsightsError.decodingFailed(error.localizedDescription)
        }
    }

    /// Handles insights-specific errors with appropriate messaging
    private func handleInsightsError(_ error: InsightsError) {
        switch error {
        case .clientNotConfigured:
            errorMessage = "App configuration error. Please restart the app."
            AppLogger.log("❌ Supabase client not configured", category: AppLogger.network, type: .error)

        case .authenticationFailed:
            errorMessage = "Please sign in to view insights."
            AppLogger.log("❌ User not authenticated", category: AppLogger.network, type: .error)

        case .tooFewEntries:
            errorMessage = "Write at least one journal entry to see insights."
            AppLogger.log("⚠️ Not enough entries for insights", category: AppLogger.network)

        case .tooManyEntries:
            errorMessage = "Too many entries provided. Maximum 20 entries."
            AppLogger.log("⚠️ Too many entries provided", category: AppLogger.network)

        case .emptyContent:
            errorMessage = "Some entries are empty. Please add content to your entries."
            AppLogger.log("⚠️ Empty entry content detected", category: AppLogger.network)

        case .rateLimitExceeded(let retryAfter):
            if let seconds = retryAfter {
                errorMessage = "Too many requests. Please wait \(seconds) seconds."
            } else {
                errorMessage = "Too many requests. Please try again in a few minutes."
            }
            AppLogger.log("⚠️ Rate limit exceeded", category: AppLogger.network)

        case .serverError(let message, let code):
            errorMessage = message
            AppLogger.log("❌ Server error [\(code)]: \(message)", category: AppLogger.network, type: .error)

        case .networkError(let message):
            errorMessage = "Network error: \(message)"
            AppLogger.log("❌ Network error: \(message)", category: AppLogger.network, type: .error)

        case .decodingFailed(let details):
            errorMessage = "Failed to process insights. Please try again."
            AppLogger.log("❌ Decoding failed: \(details)", category: AppLogger.network, type: .error)
        }
    }

    // MARK: - Persistence Methods

    /// Saves insights to UserDefaults local cache for fast offline access (user-specific)
    private func saveInsightsToCache(_ insights: JournalInsights) async {
        // Get current user ID
        guard let client = supabaseService.client else {
            AppLogger.log("⚠️ Cannot save to cache: Supabase client not configured", category: AppLogger.network)
            return
        }

        do {
            let session = try await client.auth.session
            let userId = session.user.id

            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(insights)

            let key = cacheKey(for: userId)
            UserDefaults.standard.set(data, forKey: key)
            AppLogger.log("💾 Insights saved to cache for user: \(userId.uuidString.prefix(8))...", category: AppLogger.network)
        } catch {
            AppLogger.log("❌ Failed to save insights to cache: \(error.localizedDescription)", category: AppLogger.network, type: .error)
        }
    }

    /// Loads persisted insights from UserDefaults local cache (user-specific)
    private func loadPersistedInsights() async -> JournalInsights? {
        // Get current user ID
        guard let client = supabaseService.client else {
            AppLogger.log("⚠️ Cannot load from cache: Supabase client not configured", category: AppLogger.network)
            return nil
        }

        do {
            let session = try await client.auth.session
            let userId = session.user.id

            let key = cacheKey(for: userId)
            guard let data = UserDefaults.standard.data(forKey: key) else {
                AppLogger.log("📭 No cached insights found for user: \(userId.uuidString.prefix(8))...", category: AppLogger.network)
                return nil
            }

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let insights = try decoder.decode(JournalInsights.self, from: data)
            AppLogger.log("✅ Loaded cached insights for user: \(userId.uuidString.prefix(8))...", category: AppLogger.network)
            return insights
        } catch {
            AppLogger.log("❌ Failed to load persisted insights from cache: \(error.localizedDescription)", category: AppLogger.network, type: .error)
            return nil
        }
    }

    /// Loads insights from Supabase database based on entry count
    /// Determines the correct milestone to fetch and returns insights (doesn't set self.insights)
    private func loadInsightsFromDatabase(forEntryCount entryCount: Int) async -> JournalInsights? {
        do {
            // If at an exact milestone, try to fetch insights for that specific milestone
            if entryCount >= 3 && entryCount % 3 == 0 {
                if let fetchedInsights = try await insightsService.fetchInsightsForMilestone(entryCount) {
                    AppLogger.log("☁️ Loaded insights from database for milestone \(entryCount)", category: AppLogger.network)
                    return fetchedInsights
                }
            }

            // Otherwise, fetch the latest insights regardless of milestone
            // This handles cases where:
            // - User deleted entries (had 18, now has 17)
            // - User is between milestones (has 4, last milestone was 3)
            // - Insights exist but not for exact current count
            if let latestInsights = try await insightsService.fetchLatestInsights() {
                AppLogger.log("☁️ Loaded latest insights from database (for entry count: \(entryCount))", category: AppLogger.network)
                return latestInsights
            } else {
                AppLogger.log("📭 No insights found in database", category: AppLogger.network)
                return nil
            }
        } catch {
            AppLogger.log("⚠️ Failed to load insights from database: \(error.localizedDescription)", category: AppLogger.network, type: .error)
            return nil
        }
    }

    /// Calculates which milestone the current entry count represents (for saving new insights)
    /// Returns 3, 6, 9, 12, etc.
    private func calculateMilestone(for entryCount: Int) -> Int {
        if entryCount < 3 {
            return 3
        } else if entryCount % 3 == 0 {
            return entryCount
        } else {
            // Round up to next milestone
            return ((entryCount / 3) + 1) * 3
        }
    }


    // MARK: - Real-time Sync

    /// Sets up real-time subscription for cross-device insights sync (called lazily, idempotent)
    private func setupRealtimeSyncIfNeeded() {
        // Only set up once
        guard !isRealtimeSyncEnabled else { return }

        // Check if Supabase client is configured
        guard let client = supabaseService.client else {
            // Silently skip - will retry next time generateInsights is called
            return
        }

        isRealtimeSyncEnabled = true

        Task { [weak self] in
            guard let self = self else { return }

            do {
                // Get user ID for filtering
                let session = try await client.auth.session
                let userId = session.user.id.uuidString

                // Create a channel for journal_insights table
                let channel = await client.realtimeV2.channel("insights-sync-\(UUID().uuidString)")

                // Subscribe to INSERT and UPDATE events for this user's insights
                await channel.onPostgresChange(
                    AnyAction.self,
                    schema: "public",
                    table: "journal_insights",
                    filter: "user_id=eq.\(userId)"
                ) { [weak self] change in
                    Task { @MainActor [weak self] in
                        await self?.handleRealtimeUpdate(change)
                    }
                }

                // Subscribe to the channel
                await channel.subscribe()

                // Store channel reference on main actor
                await MainActor.run { [weak self] in
                    self?.realtimeChannel = channel
                }

                AppLogger.log("🔄 Real-time sync enabled for insights", category: AppLogger.network)

            } catch {
                AppLogger.log("⚠️ Failed to setup realtime sync: \(error.localizedDescription)", category: AppLogger.network, type: .error)
                // Reset flag so we can retry
                await MainActor.run { [weak self] in
                    self?.isRealtimeSyncEnabled = false
                }
            }
        }
    }

    /// Handles real-time update from Supabase
    private func handleRealtimeUpdate(_ change: AnyAction) async {
        AppLogger.log("🔄 Received real-time insights update", category: AppLogger.network)

        // Reload insights from database
        if let latestInsights = try? await insightsService.fetchLatestInsights() {
            // Only update if the new insights are different
            if self.insights?.entryCountMilestone != latestInsights.entryCountMilestone ||
               self.insights?.generatedAt != latestInsights.generatedAt {
                self.insights = latestInsights
                await saveInsightsToCache(latestInsights)
                AppLogger.log("✅ Insights updated from real-time sync", category: AppLogger.network)
            }
        }
    }

    // MARK: - Migration

    /// Performs one-time migration of insights from old UserDefaults-only storage to database
    private func migrateOldInsightsIfNeeded() async {
        // Check if migration was already done
        guard !UserDefaults.standard.bool(forKey: migratedFlagKey) else {
            return
        }

        // Check if Supabase client is configured
        guard supabaseService.client != nil else {
            // Skip migration if Supabase isn't configured yet - will retry next time
            return
        }

        // Check if there are old insights to migrate (using old global key)
        guard let oldData = UserDefaults.standard.data(forKey: "lastGeneratedInsights") else {
            // No old insights, mark as migrated
            UserDefaults.standard.set(true, forKey: migratedFlagKey)
            return
        }

        AppLogger.log("🔄 Migrating old insights to database...", category: AppLogger.network)

        do {
            // Decode old insights
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let oldInsights = try decoder.decode(JournalInsights.self, from: oldData)

            // Determine milestone based on entries analyzed (best guess)
            let milestone = max(3, (oldInsights.entriesAnalyzed / 3) * 3)

            // Save to database
            try await insightsService.saveInsights(oldInsights, for: milestone)

            // Save to new user-specific cache
            await saveInsightsToCache(oldInsights)

            // Clear old global cache
            UserDefaults.standard.removeObject(forKey: "lastGeneratedInsights")

            // Mark migration as complete
            UserDefaults.standard.set(true, forKey: migratedFlagKey)

            AppLogger.log("✅ Migration complete: insights moved to database (milestone: \(milestone))", category: AppLogger.network)

        } catch {
            AppLogger.log("⚠️ Migration failed: \(error.localizedDescription)", category: AppLogger.network, type: .error)
            // Don't set the flag, so we retry next time
        }
    }
}

// MARK: - Request Models

/// Request body for generate-insights edge function
private struct GenerateInsightsRequest: Encodable {
    let entries: [JournalEntryRequest]
    let forceRefresh: Bool?

    enum CodingKeys: String, CodingKey {
        case entries
        case forceRefresh = "force_refresh"
    }
}

/// Individual journal entry in request
private struct JournalEntryRequest: Encodable {
    let date: String          // ISO8601 format
    let title: String
    let content: String
    let wordCount: Int
    let mood: String?

    enum CodingKeys: String, CodingKey {
        case date
        case title
        case content
        case wordCount = "word_count"
        case mood
    }
}

/// Error response from edge function
private struct InsightsErrorResponse: Decodable {
    let error: String
    let code: String
    let retryAfter: Int?
    let debug: DebugInfo?

    struct DebugInfo: Decodable {
        let message: String?
        let type: String?
        let stack: String?
    }

    enum CodingKeys: String, CodingKey {
        case error
        case code
        case retryAfter = "retryAfter"
        case debug
    }
}

// MARK: - Errors

enum InsightsError: LocalizedError {
    case clientNotConfigured
    case authenticationFailed
    case tooFewEntries
    case tooManyEntries
    case emptyContent
    case rateLimitExceeded(retryAfter: Int?)
    case serverError(String, code: String)
    case networkError(String)
    case decodingFailed(String)

    var errorDescription: String? {
        switch self {
        case .clientNotConfigured:
            return "Supabase client is not configured"
        case .authenticationFailed:
            return "User must be authenticated"
        case .tooFewEntries:
            return "Need at least 1 entry to generate insights"
        case .tooManyEntries:
            return "Maximum 20 entries allowed"
        case .emptyContent:
            return "All entries must have content"
        case .rateLimitExceeded(let seconds):
            return "Rate limit exceeded. Retry after \(seconds ?? 60) seconds."
        case .serverError(let message, _):
            return message
        case .networkError(let message):
            return message
        case .decodingFailed(let details):
            return "Failed to decode response: \(details)"
        }
    }
}
