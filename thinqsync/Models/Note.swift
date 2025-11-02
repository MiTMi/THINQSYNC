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
    private var contentWrapper: AttributedStringWrapper
    var color: NoteColor
    var isFavorite: Bool
    var folder: String?
    var createdAt: Date
    var modifiedAt: Date

    // Computed property for easy access to attributed string
    var attributedContent: NSAttributedString {
        get { contentWrapper.attributedString }
        set { contentWrapper = AttributedStringWrapper(newValue) }
    }

    // Convenience property for plain text
    var content: String {
        get { contentWrapper.attributedString.string }
        set {
            // Only set font, let the view handle text color based on note.color
            let attributes: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: 16)
            ]
            contentWrapper = AttributedStringWrapper(NSAttributedString(string: newValue, attributes: attributes))
        }
    }

    init(
        id: UUID = UUID(),
        title: String = "NewDemo",
        content: String = "Demo",
        color: NoteColor = .green,
        isFavorite: Bool = false,
        folder: String? = nil,
        createdAt: Date = Date(),
        modifiedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        // Only set font, let the view handle text color based on note.color
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 16)
        ]
        self.contentWrapper = AttributedStringWrapper(NSAttributedString(string: content, attributes: attributes))
        self.color = color
        self.isFavorite = isFavorite
        self.folder = folder
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
    }

    // Custom coding keys
    enum CodingKeys: String, CodingKey {
        case id, title, contentWrapper, color, isFavorite, folder, createdAt, modifiedAt
    }
}
