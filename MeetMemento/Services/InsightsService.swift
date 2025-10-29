//
//  InsightsService.swift
//  MeetMemento
//
//  Service for managing AI-generated insights persistence in Supabase
//  Handles CRUD operations for journal_insights table with milestone-based versioning
//

import Foundation
import Supabase

/// Service for managing insights persistence in Supabase database
class InsightsService {
    static let shared = InsightsService()

    private let supabaseService = SupabaseService.shared
    private let tableName = "journal_insights"

    private init() {}

    // MARK: - Public Methods

    /// Saves insights to Supabase for a specific milestone
    /// - Parameters:
    ///   - insights: The JournalInsights to save
    ///   - milestone: The entry count milestone (3, 6, 9, 12, etc.)
    /// - Throws: InsightsServiceError if operation fails
    func saveInsights(_ insights: JournalInsights, for milestone: Int) async throws {
        guard let client = supabaseService.client else {
            throw InsightsServiceError.clientNotConfigured
        }

        // Get current user ID
        let session = try await client.auth.session
        let userId = session.user.id

        #if DEBUG
        print("💾 Saving insights for milestone \(milestone) to Supabase...")
        #endif
        AppLogger.log("💾 Saving insights for milestone \(milestone) to Supabase", category: AppLogger.network)

        // Create database row model
        let insightRow = InsightDatabaseRow(
            userId: userId,
            entryCountMilestone: milestone,
            summary: insights.summary,
            description: insights.description,
            annotations: insights.annotations,
            themes: insights.themes,
            entriesAnalyzed: insights.entriesAnalyzed,
            generatedAt: insights.generatedAt,
            fromCache: insights.fromCache,
            cacheExpiresAt: insights.cacheExpiresAt
        )

        do {
            // Try INSERT first
            do {
                try await client
                    .from(tableName)
                    .insert(insightRow)
                    .execute()

                #if DEBUG
                print("✅ Insights inserted for milestone \(milestone)")
                #endif
                AppLogger.log("✅ Insights inserted for milestone \(milestone)", category: AppLogger.network)

            } catch {
                // If insert fails with duplicate key, try UPDATE instead
                let errorMessage = error.localizedDescription
                if errorMessage.contains("duplicate key") || errorMessage.contains("23505") || errorMessage.contains("unique constraint") {
                    AppLogger.log("🔄 Milestone \(milestone) exists, updating instead...", category: AppLogger.network)

                    try await client
                        .from(tableName)
                        .update(insightRow)
                        .eq("user_id", value: userId.uuidString)
                        .eq("entry_count_milestone", value: milestone)
                        .execute()

                    #if DEBUG
                    print("✅ Insights updated for milestone \(milestone)")
                    #endif
                    AppLogger.log("✅ Insights updated for milestone \(milestone)", category: AppLogger.network)
                } else {
                    // Other error, rethrow
                    throw error
                }
            }

        } catch {
            #if DEBUG
            print("❌ Failed to save insights: \(error)")
            #endif
            AppLogger.log("❌ Failed to save insights: \(error.localizedDescription)", category: AppLogger.network, type: .error)
            throw InsightsServiceError.saveFailed(error.localizedDescription)
        }
    }

    /// Fetches insights for a specific milestone
    /// - Parameter milestone: The entry count milestone (3, 6, 9, 12, etc.)
    /// - Returns: JournalInsights if found, nil otherwise
    /// - Throws: InsightsServiceError if operation fails
    func fetchInsightsForMilestone(_ milestone: Int) async throws -> JournalInsights? {
        guard let client = supabaseService.client else {
            throw InsightsServiceError.clientNotConfigured
        }

        // Get current user ID
        let session = try await client.auth.session
        let userId = session.user.id

        #if DEBUG
        print("🔍 Fetching insights for milestone \(milestone) from Supabase...")
        #endif
        AppLogger.log("🔍 Fetching insights for milestone \(milestone)", category: AppLogger.network)

        do {
            let response = try await client
                .from(tableName)
                .select()
                .eq("user_id", value: userId.uuidString)
                .eq("entry_count_milestone", value: milestone)
                .single()
                .execute()

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let insightRow = try decoder.decode(InsightDatabaseRow.self, from: response.data)

            // Convert database row to JournalInsights
            let insights = JournalInsights(
                summary: insightRow.summary,
                description: insightRow.description,
                annotations: insightRow.annotations,
                themes: insightRow.themes,
                entriesAnalyzed: insightRow.entriesAnalyzed,
                entryCountMilestone: insightRow.entryCountMilestone,
                generatedAt: insightRow.generatedAt,
                fromCache: insightRow.fromCache,
                cacheExpiresAt: insightRow.cacheExpiresAt
            )

            #if DEBUG
            print("✅ Fetched insights for milestone \(milestone)")
            #endif
            AppLogger.log("✅ Fetched insights for milestone \(milestone)", category: AppLogger.network)

            return insights

        } catch {
            let errorDescription = error.localizedDescription.lowercased()

            // If not found, return nil instead of throwing
            if errorDescription.contains("not found") || errorDescription.contains("no rows") {
                #if DEBUG
                print("📭 No insights found for milestone \(milestone)")
                #endif
                AppLogger.log("📭 No insights found for milestone \(milestone)", category: AppLogger.network)
                return nil
            }

            // Other errors should be thrown
            #if DEBUG
            print("❌ Failed to fetch insights: \(error)")
            #endif
            AppLogger.log("❌ Failed to fetch insights: \(error.localizedDescription)", category: AppLogger.network, type: .error)
            throw InsightsServiceError.fetchFailed(error.localizedDescription)
        }
    }

    /// Fetches the latest insights (highest milestone)
    /// - Returns: JournalInsights if found, nil otherwise
    /// - Throws: InsightsServiceError if operation fails
    func fetchLatestInsights() async throws -> JournalInsights? {
        guard let client = supabaseService.client else {
            throw InsightsServiceError.clientNotConfigured
        }

        // Get current user ID
        let session = try await client.auth.session
        let userId = session.user.id

        #if DEBUG
        print("🔍 Fetching latest insights from Supabase...")
        #endif
        AppLogger.log("🔍 Fetching latest insights", category: AppLogger.network)

        do {
            let response = try await client
                .from(tableName)
                .select()
                .eq("user_id", value: userId.uuidString)
                .order("entry_count_milestone", ascending: false)
                .limit(1)
                .execute()

            // Check if we got any results
            guard let data = String(data: response.data, encoding: .utf8),
                  !data.contains("[]") else {
                #if DEBUG
                print("📭 No insights found")
                #endif
                return nil
            }

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let insightRows = try decoder.decode([InsightDatabaseRow].self, from: response.data)

            guard let insightRow = insightRows.first else {
                return nil
            }

            // Convert database row to JournalInsights
            let insights = JournalInsights(
                summary: insightRow.summary,
                description: insightRow.description,
                annotations: insightRow.annotations,
                themes: insightRow.themes,
                entriesAnalyzed: insightRow.entriesAnalyzed,
                entryCountMilestone: insightRow.entryCountMilestone,
                generatedAt: insightRow.generatedAt,
                fromCache: insightRow.fromCache,
                cacheExpiresAt: insightRow.cacheExpiresAt
            )

            #if DEBUG
            print("✅ Fetched latest insights (milestone \(insightRow.entryCountMilestone))")
            #endif
            AppLogger.log("✅ Fetched latest insights (milestone \(insightRow.entryCountMilestone))", category: AppLogger.network)

            return insights

        } catch {
            let errorDescription = error.localizedDescription.lowercased()

            // If not found, return nil instead of throwing
            if errorDescription.contains("not found") || errorDescription.contains("no rows") {
                #if DEBUG
                print("📭 No insights found")
                #endif
                return nil
            }

            // Other errors should be thrown
            #if DEBUG
            print("❌ Failed to fetch latest insights: \(error)")
            #endif
            AppLogger.log("❌ Failed to fetch latest insights: \(error.localizedDescription)", category: AppLogger.network, type: .error)
            throw InsightsServiceError.fetchFailed(error.localizedDescription)
        }
    }

    /// Fetches all insights for the current user (sorted by milestone descending)
    /// - Returns: Array of JournalInsights, empty if none found
    /// - Throws: InsightsServiceError if operation fails
    func fetchAllInsights() async throws -> [JournalInsights] {
        guard let client = supabaseService.client else {
            throw InsightsServiceError.clientNotConfigured
        }

        // Get current user ID
        let session = try await client.auth.session
        let userId = session.user.id

        #if DEBUG
        print("🔍 Fetching all insights from Supabase...")
        #endif
        AppLogger.log("🔍 Fetching all insights", category: AppLogger.network)

        do {
            let response = try await client
                .from(tableName)
                .select()
                .eq("user_id", value: userId.uuidString)
                .order("entry_count_milestone", ascending: false)
                .execute()

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let insightRows = try decoder.decode([InsightDatabaseRow].self, from: response.data)

            // Convert database rows to JournalInsights
            let insights = insightRows.map { row in
                JournalInsights(
                    summary: row.summary,
                    description: row.description,
                    annotations: row.annotations,
                    themes: row.themes,
                    entriesAnalyzed: row.entriesAnalyzed,
                    entryCountMilestone: row.entryCountMilestone,
                    generatedAt: row.generatedAt,
                    fromCache: row.fromCache,
                    cacheExpiresAt: row.cacheExpiresAt
                )
            }

            #if DEBUG
            print("✅ Fetched \(insights.count) insights")
            #endif
            AppLogger.log("✅ Fetched \(insights.count) insights", category: AppLogger.network)

            return insights

        } catch {
            #if DEBUG
            print("❌ Failed to fetch all insights: \(error)")
            #endif
            AppLogger.log("❌ Failed to fetch all insights: \(error.localizedDescription)", category: AppLogger.network, type: .error)
            throw InsightsServiceError.fetchFailed(error.localizedDescription)
        }
    }

    /// Deletes insights for a specific milestone
    /// - Parameter milestone: The entry count milestone to delete
    /// - Throws: InsightsServiceError if operation fails
    func deleteInsights(forMilestone milestone: Int) async throws {
        guard let client = supabaseService.client else {
            throw InsightsServiceError.clientNotConfigured
        }

        // Get current user ID
        let session = try await client.auth.session
        let userId = session.user.id

        #if DEBUG
        print("🗑️ Deleting insights for milestone \(milestone)...")
        #endif
        AppLogger.log("🗑️ Deleting insights for milestone \(milestone)", category: AppLogger.network)

        do {
            try await client
                .from(tableName)
                .delete()
                .eq("user_id", value: userId.uuidString)
                .eq("entry_count_milestone", value: milestone)
                .execute()

            #if DEBUG
            print("✅ Insights deleted for milestone \(milestone)")
            #endif
            AppLogger.log("✅ Insights deleted for milestone \(milestone)", category: AppLogger.network)

        } catch {
            #if DEBUG
            print("❌ Failed to delete insights: \(error)")
            #endif
            AppLogger.log("❌ Failed to delete insights: \(error.localizedDescription)", category: AppLogger.network, type: .error)
            throw InsightsServiceError.deleteFailed(error.localizedDescription)
        }
    }

    /// Deletes all insights for the current user
    /// - Throws: InsightsServiceError if operation fails
    func deleteAllInsights() async throws {
        guard let client = supabaseService.client else {
            throw InsightsServiceError.clientNotConfigured
        }

        // Get current user ID
        let session = try await client.auth.session
        let userId = session.user.id

        #if DEBUG
        print("🗑️ Deleting all insights...")
        #endif
        AppLogger.log("🗑️ Deleting all insights", category: AppLogger.network)

        do {
            try await client
                .from(tableName)
                .delete()
                .eq("user_id", value: userId.uuidString)
                .execute()

            #if DEBUG
            print("✅ All insights deleted")
            #endif
            AppLogger.log("✅ All insights deleted", category: AppLogger.network)

        } catch {
            #if DEBUG
            print("❌ Failed to delete all insights: \(error)")
            #endif
            AppLogger.log("❌ Failed to delete all insights: \(error.localizedDescription)", category: AppLogger.network, type: .error)
            throw InsightsServiceError.deleteFailed(error.localizedDescription)
        }
    }
}

// MARK: - Database Model

/// Database row model for journal_insights table
/// Maps to Supabase table structure with snake_case columns
private struct InsightDatabaseRow: Codable {
    let id: UUID?
    let userId: UUID
    let entryCountMilestone: Int
    let summary: String
    let description: String
    let annotations: [InsightAnnotation]
    let themes: [InsightTheme]
    let entriesAnalyzed: Int
    let generatedAt: Date
    let fromCache: Bool
    let cacheExpiresAt: Date?
    let createdAt: Date?
    let updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case entryCountMilestone = "entry_count_milestone"
        case summary
        case description
        case annotations
        case themes
        case entriesAnalyzed = "entries_analyzed"
        case generatedAt = "generated_at"
        case fromCache = "from_cache"
        case cacheExpiresAt = "cache_expires_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    init(
        id: UUID? = nil,
        userId: UUID,
        entryCountMilestone: Int,
        summary: String,
        description: String,
        annotations: [InsightAnnotation],
        themes: [InsightTheme],
        entriesAnalyzed: Int,
        generatedAt: Date,
        fromCache: Bool,
        cacheExpiresAt: Date?,
        createdAt: Date? = nil,
        updatedAt: Date? = nil
    ) {
        self.id = id
        self.userId = userId
        self.entryCountMilestone = entryCountMilestone
        self.summary = summary
        self.description = description
        self.annotations = annotations
        self.themes = themes
        self.entriesAnalyzed = entriesAnalyzed
        self.generatedAt = generatedAt
        self.fromCache = fromCache
        self.cacheExpiresAt = cacheExpiresAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Errors

enum InsightsServiceError: LocalizedError {
    case clientNotConfigured
    case saveFailed(String)
    case fetchFailed(String)
    case deleteFailed(String)

    var errorDescription: String? {
        switch self {
        case .clientNotConfigured:
            return "Supabase client is not configured"
        case .saveFailed(let message):
            return "Failed to save insights: \(message)"
        case .fetchFailed(let message):
            return "Failed to fetch insights: \(message)"
        case .deleteFailed(let message):
            return "Failed to delete insights: \(message)"
        }
    }
}
