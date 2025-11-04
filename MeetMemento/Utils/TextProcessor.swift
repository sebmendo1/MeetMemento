//
//  TextProcessor.swift
//  MeetMemento
//
//  Utility for processing and normalizing transcribed text from speech-to-text.
//  Handles whitespace cleanup, capitalization, and punctuation formatting.
//

import Foundation

struct TextProcessor {

    /// Normalizes transcribed text by cleaning whitespace, fixing capitalization, and formatting punctuation
    /// - Parameter text: Raw transcribed text
    /// - Returns: Cleaned and normalized text
    static func normalize(_ text: String) -> String {
        guard !text.isEmpty else { return text }

        var processed = text

        // 1. Trim leading/trailing whitespace
        processed = processed.trimmingCharacters(in: .whitespacesAndNewlines)

        // 2. Normalize multiple spaces to single space
        processed = trimExcessiveWhitespace(processed)

        // 3. Clean punctuation spacing
        processed = cleanPunctuation(processed)

        // 4. Fix capitalization (first letter)
        processed = fixCapitalization(processed)

        // 5. Add final punctuation if missing
        processed = addFinalPunctuation(processed)

        return processed
    }

    /// Removes excessive whitespace (multiple spaces and newlines)
    /// - Parameter text: Input text
    /// - Returns: Text with normalized whitespace
    private static func trimExcessiveWhitespace(_ text: String) -> String {
        // Replace multiple spaces with single space
        var result = text.replacingOccurrences(of: "  +", with: " ", options: .regularExpression)

        // Replace multiple newlines with maximum of 2 (paragraph break)
        result = result.replacingOccurrences(of: "\n{3,}", with: "\n\n", options: .regularExpression)

        return result
    }

    /// Cleans punctuation spacing (removes spaces before, adds after if needed)
    /// - Parameter text: Input text
    /// - Returns: Text with clean punctuation spacing
    private static func cleanPunctuation(_ text: String) -> String {
        var result = text

        // Remove spaces before punctuation
        let punctuation = [".", ",", "!", "?", ";", ":"]
        for mark in punctuation {
            result = result.replacingOccurrences(of: " \(mark)", with: mark)
        }

        // Add space after punctuation if missing (except at end of string or before newline)
        for mark in punctuation {
            let pattern = "\(mark)(?=[^\\s\\n])"
            result = result.replacingOccurrences(of: pattern, with: "\(mark) ", options: .regularExpression)
        }

        return result
    }

    /// Capitalizes the first letter of the text
    /// - Parameter text: Input text
    /// - Returns: Text with capitalized first letter
    private static func fixCapitalization(_ text: String) -> String {
        guard !text.isEmpty else { return text }

        // Capitalize first letter
        let firstChar = text.prefix(1).uppercased()
        let remainder = text.dropFirst()

        return firstChar + remainder
    }

    /// Adds a period at the end if no punctuation exists
    /// - Parameter text: Input text
    /// - Returns: Text with final punctuation
    private static func addFinalPunctuation(_ text: String) -> String {
        guard !text.isEmpty else { return text }

        let endingPunctuation: Set<Character> = [".", "!", "?", ":", ";"]
        let lastChar = text.last

        // Add period if no ending punctuation exists
        if let lastChar = lastChar, !endingPunctuation.contains(lastChar) {
            return text + "."
        }

        return text
    }
}
