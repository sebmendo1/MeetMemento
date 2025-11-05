//
//  AuthService.swift
//  MeetMemento
//
//  Handles OAuth (Google/Apple), native Apple ID token sign-in, redirect handling, and auth state observation.
//

import Foundation
import AuthenticationServices
import UIKit
import Supabase
import os.log

/// Centralized authentication service bridging Supabase auth to SwiftUI layer.
final class AuthService: NSObject {
    static let shared = AuthService()

    /// Update this in one place to control the callback URL scheme used by OAuth providers.
    /// ✅ URL scheme configured in Info.plist: "memento" for OAuth redirect
    struct Constants {
        static let callbackURL: URL = {
            // Safe unwrap - this URL format is guaranteed to be valid
            URL(string: "memento://auth-callback")!
        }()
    }

    private let logger = os.Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.meetmemento", category: "auth")

    private override init() {}

    // MARK: - Helpers

    private var supabase: SupabaseClient? { SupabaseService.shared.supabase }

    // MARK: - OAuth (ASWebAuthenticationSession)

    /// Starts Google OAuth via ASWebAuthenticationSession and Supabase OAuth URL.
    func signInWithGoogle() async throws {
        guard let supabase else { throw AuthServiceError.clientUnavailable }
        let authURL = try await supabase.auth.getOAuthSignInURL(
            provider: .google,
            redirectTo: Constants.callbackURL
        )
        try await startWebAuthSession(authURL: authURL)
    }

    /// Starts Apple OAuth via ASWebAuthenticationSession and Supabase OAuth URL (web, not native).
    func signInWithApple_OAuth(ephemeral: Bool = true) async throws {
        guard let supabase else { throw AuthServiceError.clientUnavailable }
        let authURL = try await supabase.auth.getOAuthSignInURL(
            provider: .apple,
            redirectTo: Constants.callbackURL
        )
        try await startWebAuthSession(authURL: authURL, ephemeral: ephemeral)
    }

    private func startWebAuthSession(authURL: URL, ephemeral: Bool = true) async throws {
        let callbackScheme = AuthService.Constants.callbackURL.scheme
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            let session = ASWebAuthenticationSession(url: authURL, callbackURLScheme: callbackScheme) { [weak self] callbackURL, error in
                if let error {
                    self?.logger.error("WebAuthSession error: \(error.localizedDescription)")
                    // Map common OAuth errors to user-friendly messages
                    let mappedError = self?.mapOAuthError(error) ?? error
                    continuation.resume(throwing: mappedError)
                    return
                }
                guard let callbackURL else {
                    continuation.resume(throwing: AuthServiceError.invalidCallback)
                    return
                }
                Task {
                    do {
                        try await self?.handleRedirectURL(callbackURL)
                        continuation.resume()
                    } catch {
                        continuation.resume(throwing: error)
                    }
                }
            }
            session.presentationContextProvider = self
            session.prefersEphemeralWebBrowserSession = ephemeral
            if !session.start() {
                continuation.resume(throwing: AuthServiceError.unableToStartWebAuth)
            }
        }
    }

    /// Maps common Supabase OAuth errors to user-friendly messages.
    private func mapOAuthError(_ error: Error) -> Error {
        let description = error.localizedDescription.lowercased()

        if description.contains("missing oauth secret") {
            return NSError(domain: "AuthService", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "Apple provider is not fully configured in Supabase. Please ensure Client ID (Services ID), Team ID, Key ID, and the full .p8 Private Key are set in Dashboard → Authentication → Providers → Apple."])
        }

        if description.contains("invalid_client") || description.contains("invalid redirect") {
            return NSError(domain: "AuthService", code: -2,
                          userInfo: [NSLocalizedDescriptionKey: "Apple Services ID configuration issue. Please verify the Return URL is set to https://fhsgvlbedqwxwpubtlls.supabase.co/auth/v1/callback in your Apple Developer Services ID configuration."])
        }

        if description.contains("provider is not enabled") {
            return NSError(domain: "AuthService", code: -3,
                          userInfo: [NSLocalizedDescriptionKey: "Apple provider is not enabled in Supabase. Please enable it in Dashboard → Authentication → Providers → Apple."])
        }

        if description.contains("secret key should be a jwt") {
            return NSError(domain: "AuthService", code: -4,
                          userInfo: [NSLocalizedDescriptionKey: "Supabase expects a JWT token in the 'Private Key' field for Apple. You need to generate a JWT using your .p8 file, Team ID, Key ID, and Services ID. See the JWT generation code below."])
        }

        return error
    }

    // MARK: - Native Apple (Sign in with Apple → ID Token)

    /// Signs in using an Apple OpenID Connect idToken + nonce (native flow).
    /// Use this when you implement ASAuthorizationController to obtain the credentials.
    func signInWithApple_Native(idToken: String, nonce: String) async throws {
        guard let supabase else { throw AuthServiceError.clientUnavailable }
        logger.log("Signing in with Apple native - idToken length: \(idToken.count), nonce: \(nonce.prefix(10))...")
        
        let creds = OpenIDConnectCredentials(provider: .apple, idToken: idToken, nonce: nonce)
        
        do {
            let session = try await supabase.auth.signInWithIdToken(credentials: creds)
            logger.log("✅ Supabase session created for Apple sign-in: user = \(session.user.email ?? "unknown")")
        } catch {
            logger.error("❌ Supabase Apple sign-in failed: \(error.localizedDescription)")
            throw error
        }
    }

    // MARK: - Redirect handling

    /// Handles OAuth redirect from ASWebAuthenticationSession or app openURL callbacks.
    func handleRedirectURL(_ url: URL) async throws {
        guard let supabase else { throw AuthServiceError.clientUnavailable }
        do {
            _ = try await supabase.auth.session(from: url)
            logger.log("Auth redirect handled successfully")
        } catch {
            logger.error("Auth redirect error: \(error.localizedDescription)")
            throw error
        }
    }

    // MARK: - Auth change observation

    /// Observe auth state changes and notify via callback on main actor.
    /// The callback receives string events: SIGNED_IN, SIGNED_OUT, TOKEN_REFRESHED, USER_UPDATED
    func observeAuthChanges(onChange: @escaping (String) -> Void) {
        Task {
            guard let supabase else { return }
            for await (event, _) in supabase.auth.authStateChanges {
                await MainActor.run { onChange(event.rawValue) }
            }
        }
    }
}

// MARK: - ASWebAuthenticationPresentationContextProviding

extension AuthService: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        // Best-effort: return the keyWindow if available
        return UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow } ?? UIWindow()
    }
}

// MARK: - Errors

enum AuthServiceError: LocalizedError {
    case clientUnavailable
    case invalidCallback
    case unableToStartWebAuth

    var errorDescription: String? {
        switch self {
        case .clientUnavailable: return "Supabase client unavailable"
        case .invalidCallback: return "Invalid OAuth callback URL"
        case .unableToStartWebAuth: return "Unable to start web authentication session"
        }
    }
}
