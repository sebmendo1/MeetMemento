//
//  AppleAuthDelegate.swift
//  MeetMemento
//
//  Handles ASAuthorizationControllerDelegate for native Apple Sign-In
//

import Foundation
import AuthenticationServices
import UIKit
import os.log

final class AppleAuthDelegate: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    private let nonce: String
    // Updated completion: (error, firstName, lastName)
    private let completion: (String?, String?, String?) -> Void
    private let logger = os.Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.meetmemento", category: "AppleAuth")

    // Strong reference to self to prevent deallocation during async flow
    private var strongSelf: AppleAuthDelegate?

    init(nonce: String, completion: @escaping (String?, String?, String?) -> Void) {
        self.nonce = nonce
        self.completion = completion
        super.init()
        // Keep strong reference to prevent deallocation
        self.strongSelf = self
        logger.log("AppleAuthDelegate initialized")
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        logger.log("Apple authorization completed")
        
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            logger.error("Invalid authorization credential")
            completion("Invalid authorization credential", nil, nil)
            strongSelf = nil
            return
        }

        guard let idTokenData = appleIDCredential.identityToken,
              let idToken = String(data: idTokenData, encoding: .utf8) else {
            logger.error("Missing identity token")
            completion("Missing identity token", nil, nil)
            strongSelf = nil
            return
        }

        logger.log("ID Token received, signing in with Supabase...")

        // Extract name from credential (only available on first sign-in)
        var firstName: String? = nil
        var lastName: String? = nil

        if let fullName = appleIDCredential.fullName {
            firstName = fullName.givenName
            lastName = fullName.familyName

            if let first = firstName, let last = lastName {
                logger.log("Extracted name from Apple credential: \(first) \(last)")
            }
        }

        Task {
            do {
                try await AuthService.shared.signInWithApple_Native(idToken: idToken, nonce: nonce)
                logger.log("✅ Apple sign-in successful")

                // Do NOT auto-save profile data anymore
                // Instead, pass the names back to the caller to handle
                // This ensures consistent UX with OTP flow (shows CreateAccountView for all new users)
                if let first = firstName, let last = lastName, !first.isEmpty, !last.isEmpty {
                    logger.log("✅ Apple provided profile data - passing to caller: \(first) \(last)")
                } else {
                    logger.log("⚠️ No profile data from Apple (likely returning user)")
                }

                await MainActor.run {
                    // Success - pass error=nil and the names (may be nil for returning users)
                    completion(nil, firstName, lastName)
                    strongSelf = nil
                }
            } catch {
                logger.error("❌ Apple sign-in failed: \(error.localizedDescription)")
                await MainActor.run {
                    completion(error.localizedDescription, nil, nil)
                    strongSelf = nil
                }
            }
        }
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        logger.error("Apple authorization error: \(error.localizedDescription)")
        
        // Map ASAuthorizationError codes to user-friendly messages
        let errorMessage: String
        
        if let authError = error as? ASAuthorizationError {
            switch authError.code {
            case .canceled:
                errorMessage = "Sign in was canceled"
                logger.log("User canceled Apple Sign-In")
            case .failed:
                errorMessage = "Apple Sign-In failed. Please try again."
                logger.error("Apple Sign-In failed with underlying error")
            case .invalidResponse:
                errorMessage = "Invalid response from Apple. Please try again."
                logger.error("Invalid response from Apple servers")
            case .notHandled:
                errorMessage = "Sign in request was not handled. Please try again."
                logger.error("Sign in request not handled")
            case .unknown:
                errorMessage = "An unknown error occurred. Please try again."
                logger.error("Unknown Apple Sign-In error")
            case .notInteractive:
                errorMessage = "Sign in requires user interaction"
                logger.error("Non-interactive sign-in attempted")
            @unknown default:
                errorMessage = "Error: \(error.localizedDescription)"
                logger.error("Unknown ASAuthorizationError code: \(authError.code.rawValue)")
            }
        } else {
            errorMessage = "Error: \(error.localizedDescription)"
        }
        
        completion(errorMessage, nil, nil)
        strongSelf = nil
    }

    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        let window = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow } ?? UIWindow()
        logger.log("Presentation anchor: \(window.description)")
        return window
    }
}
