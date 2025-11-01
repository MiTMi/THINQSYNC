//
//  AttributedStringCodable.swift
//  thinqsync
//
//  Created by Michael   on 31/10/2025.
//

import Foundation
import AppKit

// Wrapper to make NSAttributedString Codable and Sendable
struct AttributedStringWrapper: Codable, Sendable {
    let data: Data

    init(_ attributedString: NSAttributedString) {
        // Convert to RTF data
        if let data = try? attributedString.data(
            from: NSRange(location: 0, length: attributedString.length),
            documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf]
        ) {
            self.data = data
        } else {
            // Fallback to plain text
            self.data = attributedString.string.data(using: .utf8) ?? Data()
        }
    }

    var attributedString: NSAttributedString {
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
