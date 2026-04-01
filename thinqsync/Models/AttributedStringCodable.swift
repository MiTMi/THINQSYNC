//
//  AttributedStringCodable.swift
//  thinqsync
//
//  Created by Michael   on 31/10/2025.
//

import Foundation
import AppKit

// Wrapper to make NSAttributedString Codable and Sendable
// Uses RTFD format to support embedded images and attachments
struct AttributedStringWrapper: Codable, Sendable {
    let data: Data

    init(_ attributedString: NSAttributedString) {
        // First try RTFD format (supports images and attachments)
        if let data = try? attributedString.data(
            from: NSRange(location: 0, length: attributedString.length),
            documentAttributes: [.documentType: NSAttributedString.DocumentType.rtfd]
        ) {
            self.data = data
        }
        // Fallback to RTF (for text-only content)
        else if let data = try? attributedString.data(
            from: NSRange(location: 0, length: attributedString.length),
            documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf]
        ) {
            self.data = data
        } else {
            // Last resort: plain text
            self.data = attributedString.string.data(using: .utf8) ?? Data()
        }
    }

    // Initialize directly from data (for CloudKit deserialization)
    init(data: Data) {
        self.data = data
    }

    var attributedString: NSAttributedString {
        // Try RTFD first (supports images)
        if let attributed = try? NSAttributedString(
            data: data,
            options: [.documentType: NSAttributedString.DocumentType.rtfd],
            documentAttributes: nil
        ) {
            return attributed
        }
        // Fallback to RTF
        if let attributed = try? NSAttributedString(
            data: data,
            options: [.documentType: NSAttributedString.DocumentType.rtf],
            documentAttributes: nil
        ) {
            return attributed
        }
        // Fallback to plain text
        let string = String(data: data, encoding: .utf8) ?? ""
        return NSAttributedString(string: string)
    }
}
