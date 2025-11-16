//
//  Note.swift
//  thinqsync
//
//  Created by Michael   on 31/10/2025.
//

import Foundation
import SwiftUI
import AppKit

struct Note: Identifiable, Codable, Sendable {
    var id: UUID
    var title: String
    var contentWrapper: AttributedStringWrapper  // Internal access for CloudKit sync
    var color: NoteColor
    var isFavorite: Bool
    var folder: String?
    var createdAt: Date
    var modifiedAt: Date
    var deletedAt: Date?
    var windowFrame: CGRect?  // Saved window position and size

    // Computed property for easy access to attributed string
    var attributedContent: NSAttributedString {
        get { contentWrapper.attributedString }
        set { contentWrapper = AttributedStringWrapper(newValue) }
    }

    // Convenience property for plain text
    var content: String {
        get { contentWrapper.attributedString.string }
        set {
            // Set both font and foreground color attributes
            let attributes: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: 16),
                .foregroundColor: NSColor.labelColor
            ]
            contentWrapper = AttributedStringWrapper(NSAttributedString(string: newValue, attributes: attributes))
        }
    }

    init(
        id: UUID = UUID(),
        title: String = "",
        content: String = "",
        color: NoteColor = .green,
        isFavorite: Bool = false,
        folder: String? = nil,
        createdAt: Date = Date(),
        modifiedAt: Date = Date(),
        deletedAt: Date? = nil,
        windowFrame: CGRect? = nil
    ) {
        self.id = id
        self.title = title
        // Set both font and foreground color attributes
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 16),
            .foregroundColor: NSColor.labelColor
        ]
        self.contentWrapper = AttributedStringWrapper(NSAttributedString(string: content, attributes: attributes))
        self.color = color
        self.isFavorite = isFavorite
        self.folder = folder
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
        self.deletedAt = deletedAt
        self.windowFrame = windowFrame
    }

    // Initializer for CloudKit deserialization (with contentWrapper directly)
    init(
        id: UUID,
        title: String,
        contentWrapper: AttributedStringWrapper,
        color: NoteColor,
        isFavorite: Bool,
        folder: String?,
        createdAt: Date,
        modifiedAt: Date,
        deletedAt: Date? = nil,
        windowFrame: CGRect? = nil
    ) {
        self.id = id
        self.title = title
        self.contentWrapper = contentWrapper
        self.color = color
        self.isFavorite = isFavorite
        self.folder = folder
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
        self.deletedAt = deletedAt
        self.windowFrame = windowFrame
    }

    // Custom coding keys
    enum CodingKeys: String, CodingKey {
        case id, title, contentWrapper, color, isFavorite, folder, createdAt, modifiedAt, deletedAt, windowFrame
    }
}
