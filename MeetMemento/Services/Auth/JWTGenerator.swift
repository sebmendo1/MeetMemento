//
//  JWTGenerator.swift
//  MeetMemento
//
//  Generates JWT tokens for Apple Sign-In client secret
//

import Foundation
import CryptoKit

struct AppleJWTGenerator {

    /// Generates a JWT token for Apple's client secret using your .p8 private key
    /// - Parameters:
    ///   - teamID: Your Apple Developer Team ID (10 characters)
    ///   - keyID: Your Sign in with Apple Key ID (10 characters)
    ///   - servicesID: Your Apple Services ID (e.g., "com.sebmendo.MeetMemento.web")
    ///   - privateKey: The content of your .p8 file (without BEGIN/END lines)
    ///   - expirationTime: Token expiration time in seconds (default: 15777000 ≈ 6 months)
    /// - Returns: The JWT token as a string
    static func generateJWT(
        teamID: String,
        keyID: String,
        servicesID: String,
        privateKey: String,
        expirationTime: TimeInterval = 15777000
    ) throws -> String {

        // Clean the private key (remove PEM headers if present)
        let cleanPrivateKey = cleanPrivateKey(privateKey)

        guard let privateKeyData = Data(base64Encoded: cleanPrivateKey) else {
            throw NSError(domain: "JWTGenerator", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid private key format"])
        }

        // Create JWT header
        let header = [
            "alg": "ES256",
            "kid": keyID,
            "typ": "JWT"
        ]

        // Create JWT payload
        let now = Int(Date().timeIntervalSince1970)
        let expiration = now + Int(expirationTime)

        let payload: [String: Any] = [
            "iss": teamID,
            "iat": now,
            "exp": expiration,
            "aud": "https://appleid.apple.com",
            "sub": servicesID
        ]

        // Encode header and payload to base64url
        let headerData = try JSONSerialization.data(withJSONObject: header as [String: Any])
        let payloadData = try JSONSerialization.data(withJSONObject: payload as [String: Any])

        let encodedHeader = base64urlEncode(headerData)
        let encodedPayload = base64urlEncode(payloadData)

        let message = "\(encodedHeader).\(encodedPayload)"

        // Sign the message
        let signature = try signMessage(message, with: privateKeyData)

        // Combine header.payload.signature
        let jwt = "\(message).\(signature)"

        return jwt
    }

    /// Cleans the private key by removing PEM headers and newlines
    private static func cleanPrivateKey(_ key: String) -> String {
        var cleaned = key
            .replacingOccurrences(of: "-----BEGIN PRIVATE KEY-----", with: "")
            .replacingOccurrences(of: "-----END PRIVATE KEY-----", with: "")
            .replacingOccurrences(of: "\n", with: "")
        return cleaned
    }

    /// Signs a message using ES256 (ECDSA with P-256 and SHA-256)
    private static func signMessage(_ message: String, with privateKeyData: Data) throws -> String {
        // Convert message to data
        guard let messageData = message.data(using: .utf8) else {
            throw NSError(domain: "JWTGenerator", code: -2, userInfo: [NSLocalizedDescriptionKey: "Failed to encode message"])
        }

        // Create EC key from private key data
        let privateKey = try P256.Signing.PrivateKey(rawRepresentation: privateKeyData)

        // Sign the message
        let signature = try privateKey.signature(for: messageData)

        // Return base64url encoded signature
        return base64urlEncode(signature.rawRepresentation)
    }

    /// Encodes data to base64url format (RFC 4648)
    private static func base64urlEncode(_ data: Data) -> String {
        let base64 = data.base64EncodedString()
        return base64
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}
