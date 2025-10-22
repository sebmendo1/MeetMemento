//
//  ThemeAnalysisService.swift
//  MeetMemento
//
//  Service for analyzing user self-reflection and managing theme selection
//

import Foundation
import Supabase

@MainActor
class ThemeAnalysisService {
    static let shared = ThemeAnalysisService()

    private let validThemeNames: Set<String> = [
        "stress-energy", "anxiety-worry", "career-purpose",
        "relationships-connection", "confidence-mindset", "habits-routine",
        "self-compassion", "meaning-values", "sleep-rest", "life-transitions"
    ]

    // Use public getter from SupabaseService
    private var supabase: SupabaseClient? {
        SupabaseService.shared.supabase
    }

    private init() {}

    /// Analyzes self-reflection text and returns personalized themes
    func analyzeSelfReflection(_ text: String) async throws -> ThemeAnalysisResponse {
        // Client-side validation (UX only, not security)
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)

        guard trimmed.count >= 20 && trimmed.count <= 2000 else {
            throw ThemeAnalysisError.invalidLength
        }

        let alphaCount = trimmed.filter { $0.isLetter }.count
        guard alphaCount >= 10 else {
            throw ThemeAnalysisError.insufficientContent
        }

        AppLogger.log("🔍 Analyzing self-reflection (\(trimmed.count) chars)",
                     category: AppLogger.network)

        // Ensure Supabase client is initialized
        guard let supabase = self.supabase else {
            print("❌ Supabase client is nil - service not initialized")
            NSLog("❌ Supabase client is nil")
            AppLogger.log("❌ Supabase client is nil", category: AppLogger.network, type: .error)
            throw ThemeAnalysisError.serverError
        }

        print("✅ Supabase client is available, calling edge function...")
        NSLog("✅ Supabase client available")

        // Prepare request
        let request = ThemeAnalysisRequest(selfReflectionText: trimmed)

        do {
            // Encode request to Data
            let requestData = try JSONEncoder().encode(request)
            print("✅ Request encoded successfully - \(requestData.count) bytes")
            NSLog("✅ Request encoded: %ld bytes", requestData.count)

            // Log request payload (first 100 chars of text)
            let preview = String(trimmed.prefix(100))
            print("📤 Sending text preview: \(preview)...")
            NSLog("📤 Sending text preview")

            // Call edge function (same pattern as working generate-follow-up function)
            print("🌐 Calling edge function new-user-insights...")
            NSLog("🌐 Calling new-user-insights")

            let responseData: Data = try await supabase.functions.invoke(
                "new-user-insights",
                options: FunctionInvokeOptions(body: requestData)
            )
            var data: Data = responseData
            print("✅ Edge function returned data: \(data.count) bytes")
            NSLog("✅ Edge function returned %ld bytes", data.count)

            // Log raw response for debugging - use multiple methods to ensure visibility
            if let rawJSON = String(data: data, encoding: .utf8) {
                print("📦 Raw response from edge function:")
                print(rawJSON)
                NSLog("📦 RAW JSON: %@", rawJSON)  // NSLog is more reliable than print()

                // Save to UserDefaults as fallback
                UserDefaults.standard.set(rawJSON, forKey: "last_theme_analysis_response")

                // Check if response is DOUBLE-ENCODED (string containing JSON)
                if rawJSON.hasPrefix("\"") && rawJSON.hasSuffix("\"") {
                    print("⚠️ Response appears to be string-encoded JSON - unwrapping...")
                    NSLog("⚠️ Response is string-encoded, unwrapping...")

                    // Remove outer quotes and unescape
                    var unescaped = rawJSON
                    unescaped.removeFirst()  // Remove leading "
                    unescaped.removeLast()   // Remove trailing "
                    unescaped = unescaped.replacingOccurrences(of: "\\\"", with: "\"")
                    unescaped = unescaped.replacingOccurrences(of: "\\n", with: "\n")
                    unescaped = unescaped.replacingOccurrences(of: "\\t", with: "\t")

                    print("📦 Unwrapped JSON:")
                    print(unescaped)
                    NSLog("📦 Unwrapped JSON: %@", unescaped)

                    // Replace data with unwrapped version
                    if let unwrappedData = unescaped.data(using: .utf8) {
                        data = unwrappedData
                    }
                }
            } else {
                print("❌ Could not convert response to UTF-8 string")
                NSLog("❌ Could not convert response to UTF-8 string")
            }

            print("🔄 Attempting to decode JSON...")
            NSLog("🔄 Attempting to decode JSON with %ld bytes", data.count)

            // Use default decoder (camelCase) to match edge function response format
            // Same pattern as working generate-follow-up function
            let decoder = JSONDecoder()

            let response = try decoder.decode(ThemeAnalysisResponse.self, from: data)
            print("✅ Successfully decoded response")

            // Validate required fields are present
            guard let themes = response.themes else {
                AppLogger.log("❌ Missing themes in response",
                             category: AppLogger.network,
                             type: .error)
                throw ThemeAnalysisError.invalidResponse
            }

            NSLog("✅ Successfully decoded %ld themes", themes.count)

            // Validate theme count
            guard themes.count >= 3 && themes.count <= 6 else {
                AppLogger.log("❌ Invalid theme count: \(themes.count)",
                             category: AppLogger.network,
                             type: .error)
                throw ThemeAnalysisError.invalidResponse
            }

            // Validate all themes are recognized
            for theme in themes {
                guard validThemeNames.contains(theme.name) else {
                    AppLogger.log("❌ Unknown theme: \(theme.name)",
                                 category: AppLogger.network,
                                 type: .error)
                    throw ThemeAnalysisError.invalidResponse
                }
            }

            AppLogger.log("✅ Received \(themes.count) themes",
                         category: AppLogger.network)

            return response

        } catch let error as FunctionsError {
            // Parse edge function errors with detailed logging
            print("❌ FunctionsError details:")
            print("   Description: \(error.localizedDescription)")
            NSLog("❌ FunctionsError: %@", error.localizedDescription)

            // Log the full error
            AppLogger.log("❌ Edge function error: \(error)",
                         category: AppLogger.network,
                         type: .error)

            // Try to extract more info from the error
            let errorString = String(describing: error)
            print("   Full error: \(errorString)")
            NSLog("   Full error: %@", errorString)

            // Check if this is a 429 rate limit error
            if error.localizedDescription.contains("429") {
                // Rate limited - default message since we can't parse the response easily
                throw ThemeAnalysisError.rateLimited(retryAfter: "24 hours")
            }

            throw ThemeAnalysisError.serverError

        } catch let decodingError as DecodingError {
            // JSON parsing errors - show detailed info with multiple logging methods
            print("❌ DecodingError details:")
            NSLog("❌ DecodingError occurred")

            var errorDetails = ""
            switch decodingError {
            case .keyNotFound(let key, let context):
                errorDetails = "Missing key: \(key.stringValue), Path: \(context.codingPath.map { $0.stringValue }.joined(separator: "."))"
                print("   \(errorDetails)")
                NSLog("   %@", errorDetails)
            case .typeMismatch(let type, let context):
                errorDetails = "Type mismatch: expected \(type), Path: \(context.codingPath.map { $0.stringValue }.joined(separator: "."))"
                print("   \(errorDetails)")
                NSLog("   %@", errorDetails)
            case .valueNotFound(let type, let context):
                errorDetails = "Value not found: \(type), Path: \(context.codingPath.map { $0.stringValue }.joined(separator: "."))"
                print("   \(errorDetails)")
                NSLog("   %@", errorDetails)
            case .dataCorrupted(let context):
                errorDetails = "Data corrupted: \(context.debugDescription)"
                print("   \(errorDetails)")
                NSLog("   %@", errorDetails)
            @unknown default:
                errorDetails = "Unknown decoding error"
                print("   \(errorDetails)")
                NSLog("   %@", errorDetails)
            }

            // Save error details to UserDefaults
            UserDefaults.standard.set(errorDetails, forKey: "last_theme_analysis_error")

            AppLogger.log("❌ Failed to parse response: \(decodingError.localizedDescription)",
                         category: AppLogger.network,
                         type: .error)
            throw ThemeAnalysisError.invalidResponse

        } catch {
            // Other errors (network, etc.)
            AppLogger.log("❌ Network error: \(error.localizedDescription)",
                         category: AppLogger.network,
                         type: .error)
            throw ThemeAnalysisError.networkError(error)
        }
    }

    /// Saves theme selection to user profile
    func saveThemeSelection(
        selectedThemes: [String],
        analyzedAt: Date
    ) async throws {
        guard let supabase = supabase else {
            throw ThemeAnalysisError.serverError
        }

        guard let userId = try? await SupabaseService.shared.getCurrentUser()?.id else {
            throw ThemeAnalysisError.serverError
        }

        // ISO8601 formatter with fractional seconds (iOS 15+ only)
        let formatter = ISO8601DateFormatter()
        if #available(iOS 15.0, *) {
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        } else {
            formatter.formatOptions = [.withInternetDateTime]
        }

        AppLogger.log("💾 Saving theme selection: \(selectedThemes.count) themes",
                     category: AppLogger.network)

        // Create encodable update payload
        struct ThemeSelectionUpdate: Encodable {
            let identified_themes: [String]
            let theme_selection_count: Int
            let themes_analyzed_at: String
        }

        let updateData = ThemeSelectionUpdate(
            identified_themes: selectedThemes,
            theme_selection_count: selectedThemes.count,
            themes_analyzed_at: formatter.string(from: analyzedAt)
        )

        try await supabase
            .from("user_profiles")
            .update(updateData)
            .eq("user_id", value: userId.uuidString)
            .execute()

        AppLogger.log("✅ Theme selection saved", category: AppLogger.network)
    }
}
