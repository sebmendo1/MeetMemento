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

    // MARK: - Public Methods

    /// Generates insights from journal entries
    /// - Parameter entries: Array of journal entries to analyze (max 20)
    /// - Note: The edge function handles caching automatically
    /// - Note: Only generates when entry count is a multiple of 3 (3, 6, 9, etc.) to reduce costs
    func generateInsights(from entries: [Entry]) async {
        guard !entries.isEmpty else {
            errorMessage = "No entries to analyze"
            AppLogger.log("⚠️ Cannot generate insights: no entries provided", category: AppLogger.network, type: .error)
            return
        }

        // COST OPTIMIZATION: Only generate insights at entry milestones (multiples of 3)
        // This reduces API costs by ~67% while ensuring insights are meaningful
        let entryCount = entries.count
        if entryCount < 3 {
            errorMessage = "Write \(3 - entryCount) more \(entryCount == 2 ? "entry" : "entries") to unlock insights"
            AppLogger.log("⚠️ Not enough entries: \(entryCount)/3 required", category: AppLogger.network)
            return
        }

        if entryCount % 3 != 0 {
            let nextMilestone = ((entryCount / 3) + 1) * 3
            let entriesNeeded = nextMilestone - entryCount
            errorMessage = "Write \(entriesNeeded) more \(entriesNeeded == 1 ? "entry" : "entries") for updated insights (\(entryCount)/\(nextMilestone))"
            AppLogger.log("⚠️ Waiting for milestone: \(entryCount) entries (next at \(nextMilestone))", category: AppLogger.network)

            // If we have cached insights, show those instead of error
            if insights != nil {
                errorMessage = nil
                AppLogger.log("✅ Using cached insights while waiting for milestone", category: AppLogger.network)
                return
            }
            return
        }

        AppLogger.log("✅ Entry milestone reached: \(entryCount) entries (multiple of 3)", category: AppLogger.network)

        // Validate entry count (edge function limits to 20)
        let entriesToAnalyze = Array(entries.prefix(20))
        if entries.count > 20 {
            AppLogger.log("⚠️ Too many entries (\(entries.count)). Using first 20 only.", category: AppLogger.network)
        }

        isLoading = true
        errorMessage = nil

        do {
            // Call edge function
            let response = try await callGenerateInsightsFunction(entries: entriesToAnalyze)

            // Update state
            self.insights = response
            self.isFromCache = response.fromCache

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
    func clearInsights() {
        insights = nil
        errorMessage = nil
        isFromCache = false
        AppLogger.log("🗑️ Insights cleared", category: AppLogger.network)
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
    private func callGenerateInsightsFunction(entries: [Entry]) async throws -> JournalInsights {
        guard let client = supabaseService.client else {
            throw InsightsError.clientNotConfigured
        }

        // STEP 1: Verify authentication first
        print("🔐 Checking authentication...")
        do {
            let session = try await client.auth.session
            print("✅ Authenticated as user: \(session.user.id.uuidString.prefix(8))...")
            print("   Access token length: \(session.accessToken.count) chars")
            print("   Token expires at: \(session.expiresAt ?? 0)")
        } catch {
            print("❌ Authentication check failed: \(error)")
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

        let requestBody = GenerateInsightsRequest(entries: journalEntries)

        print("🔄 Calling generate-insights function with \(entries.count) entries")
        AppLogger.log("🔄 Calling generate-insights function with \(entries.count) entries", category: AppLogger.network)

        // Call edge function
        print("🌐 About to call edge function...")

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

        print("   Request URL: \(functionUrl)")
        print("   Request headers: Authorization=Bearer \(accessToken.prefix(20))..., apikey=\(SupabaseConfig.anonKey.prefix(20))...")
        print("   Request body size: \(request.httpBody?.count ?? 0) bytes")

        let responseData: Data
        let httpResponse: HTTPURLResponse
        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResp = response as? HTTPURLResponse else {
                print("❌ Response is not HTTPURLResponse")
                throw InsightsError.networkError("Invalid response type")
            }

            httpResponse = httpResp
            responseData = data

            print("✅ HTTP Response received:")
            print("   Status code: \(httpResponse.statusCode)")
            print("   Headers: \(httpResponse.allHeaderFields)")
            print("   Response data size: \(data.count) bytes")

            // Print raw response
            if let rawString = String(data: data, encoding: .utf8) {
                print("   Raw response: \(rawString.prefix(1000))")
            }

            // Check if it's an error status code
            if httpResponse.statusCode >= 400 {
                print("❌ HTTP error status code: \(httpResponse.statusCode)")
                if let errorString = String(data: data, encoding: .utf8) {
                    print("   Error response: \(errorString)")
                }
                throw InsightsError.serverError("HTTP \(httpResponse.statusCode)", code: "\(httpResponse.statusCode)")
            }
        } catch {
            print("❌ HTTP request failed with error: \(error)")
            print("❌ Error type: \(type(of: error))")
            print("❌ Error description: \(error.localizedDescription)")
            throw InsightsError.networkError("Failed to call edge function: \(error.localizedDescription)")
        }

        // Response data is already logged above, now decode it
        var data: Data = responseData
        print("📦 Processing response data...")
        AppLogger.log("📦 Processing response data", category: AppLogger.network)

        // Check if response is double-encoded (string containing JSON)
        if let rawJSON = String(data: data, encoding: .utf8) {
            print("📦 Raw JSON type check...")

            // Check if response is DOUBLE-ENCODED (string containing JSON)
            if rawJSON.hasPrefix("\"") && rawJSON.hasSuffix("\"") {
                print("⚠️ Response appears to be string-encoded JSON - unwrapping...")
                AppLogger.log("⚠️ Response appears to be string-encoded JSON - unwrapping...", category: AppLogger.network)

                // Remove outer quotes and unescape
                var unescaped = rawJSON
                unescaped.removeFirst()  // Remove leading "
                unescaped.removeLast()   // Remove trailing "
                unescaped = unescaped.replacingOccurrences(of: "\\\"", with: "\"")
                unescaped = unescaped.replacingOccurrences(of: "\\n", with: "\n")
                unescaped = unescaped.replacingOccurrences(of: "\\t", with: "\t")
                unescaped = unescaped.replacingOccurrences(of: "\\\\", with: "\\")

                print("📦 Unwrapped JSON (first 500 chars): \(unescaped.prefix(500))")
                AppLogger.log("📦 Unwrapped JSON: \(unescaped.prefix(500))", category: AppLogger.network)

                // Replace data with unwrapped version
                if let unwrappedData = unescaped.data(using: .utf8) {
                    data = unwrappedData
                    print("✅ Successfully created unwrapped data: \(data.count) bytes")
                }
            } else {
                print("ℹ️ Response is NOT double-encoded, using as-is")
            }
        } else {
            print("❌ Could not convert response data to UTF-8 string")
        }

        // Decode response
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        print("🔄 Attempting to decode JSON with \(data.count) bytes...")
        AppLogger.log("🔄 Attempting to decode JSON...", category: AppLogger.network)

        do {
            let insights = try decoder.decode(JournalInsights.self, from: data)
            print("✅ Successfully decoded insights: \(insights.themes.count) themes")
            AppLogger.log("✅ Successfully decoded insights", category: AppLogger.network)
            return insights
        } catch {
            print("❌ Decoding error: \(error)")
            print("❌ Error localized description: \(error.localizedDescription)")
            AppLogger.log("❌ Decoding error: \(error)", category: AppLogger.network, type: .error)

            // Try to decode error response
            if let errorResponse = try? decoder.decode(InsightsErrorResponse.self, from: data) {
                print("🔴 Server error response: \(errorResponse.error)")
                throw InsightsError.serverError(errorResponse.error, code: errorResponse.code)
            }

            // Log detailed decoding error
            if let decodingError = error as? DecodingError {
                print("❌ DecodingError details: \(decodingError)")
                AppLogger.log("❌ Decoding error details: \(decodingError)", category: AppLogger.network, type: .error)

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
}

// MARK: - Request Models

/// Request body for generate-insights edge function
private struct GenerateInsightsRequest: Encodable {
    let entries: [JournalEntryRequest]
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

    enum CodingKeys: String, CodingKey {
        case error
        case code
        case retryAfter = "retryAfter"
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
