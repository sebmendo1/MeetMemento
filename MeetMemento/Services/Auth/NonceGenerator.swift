//
//  NonceGenerator.swift
//  MeetMemento
//
//  Generates cryptographically secure random nonces and SHA256 hashes.
//

import Foundation
import CryptoKit

/// Utility to create random nonce strings and their SHA256 hash for Sign in with Apple (native) flows.
enum NonceGenerator {
    enum NonceGenerationError: Error {
        case randomBytesGenerationFailed(OSStatus)

        var localizedDescription: String {
            switch self {
            case .randomBytesGenerationFailed(let status):
                return "Failed to generate secure random bytes (status: \(status))"
            }
        }
    }

    static func randomNonce(length: Int = 32) throws -> String {
        precondition(length > 0)
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length

        while remainingLength > 0 {
            var randoms = [UInt8](repeating: 0, count: 16)
            let errorCode = SecRandomCopyBytes(kSecRandomDefault, randoms.count, &randoms)

            // Proper error handling instead of fatalError
            guard errorCode == errSecSuccess else {
                AppLogger.log("SecRandomCopyBytes failed with code: \(errorCode)",
                             category: AppLogger.general,
                             type: .error)
                throw NonceGenerationError.randomBytesGenerationFailed(errorCode)
            }

            randoms.forEach { random in
                if remainingLength == 0 { return }
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }
        return result
    }

    static func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashed = SHA256.hash(data: inputData)
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }
}
