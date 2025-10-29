//
//  MarkdownParser.swift
//  MeetMemento
//
//  Created by Sebastian Mendo on 10/26/25.
//

import Foundation

/// Represents a block of markdown content (heading or paragraph)
enum MarkdownBlock: Equatable {
    case heading(level: Int, text: String)
    case paragraph(text: String)
}

/// Lightweight markdown parser for headings and descriptions
struct MarkdownParser {

    /// Parse markdown text into an array of blocks
    /// Supports: # Heading 1, ## Heading 2, ### Heading 3, and regular paragraphs
    static func parse(_ text: String) -> [MarkdownBlock] {
        var blocks: [MarkdownBlock] = []

        // Split into lines and process each
        let lines = text.components(separatedBy: .newlines)
        var currentParagraph: [String] = []

        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)

            // Check if it's a heading
            if let headingBlock = parseHeading(trimmedLine) {
                // Flush any accumulated paragraph
                if !currentParagraph.isEmpty {
                    let paragraphText = currentParagraph.joined(separator: " ").trimmingCharacters(in: .whitespaces)
                    if !paragraphText.isEmpty {
                        blocks.append(.paragraph(text: paragraphText))
                    }
                    currentParagraph.removeAll()
                }

                // Add heading block
                blocks.append(headingBlock)
            } else if trimmedLine.isEmpty {
                // Empty line - flush current paragraph if exists
                if !currentParagraph.isEmpty {
                    let paragraphText = currentParagraph.joined(separator: " ").trimmingCharacters(in: .whitespaces)
                    if !paragraphText.isEmpty {
                        blocks.append(.paragraph(text: paragraphText))
                    }
                    currentParagraph.removeAll()
                }
            } else {
                // Regular text line - add to current paragraph
                currentParagraph.append(trimmedLine)
            }
        }

        // Flush any remaining paragraph
        if !currentParagraph.isEmpty {
            let paragraphText = currentParagraph.joined(separator: " ").trimmingCharacters(in: .whitespaces)
            if !paragraphText.isEmpty {
                blocks.append(.paragraph(text: paragraphText))
            }
        }

        return blocks
    }

    /// Parse a line as a heading if it starts with #, ##, or ###
    private static func parseHeading(_ line: String) -> MarkdownBlock? {
        // Check for heading markers
        if line.hasPrefix("### ") {
            let text = String(line.dropFirst(4)).trimmingCharacters(in: .whitespaces)
            return .heading(level: 3, text: text)
        } else if line.hasPrefix("## ") {
            let text = String(line.dropFirst(3)).trimmingCharacters(in: .whitespaces)
            return .heading(level: 2, text: text)
        } else if line.hasPrefix("# ") {
            let text = String(line.dropFirst(2)).trimmingCharacters(in: .whitespaces)
            return .heading(level: 1, text: text)
        }

        return nil
    }
}
