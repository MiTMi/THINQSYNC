//
//  RichTextEditor.swift
//  thinqsync
//
//  Created by Michael   on 31/10/2025.
//

import SwiftUI
import AppKit

struct RichTextEditor: NSViewRepresentable {
    @Binding var attributedText: NSAttributedString
    var textColor: Color
    var onTextChange: (NSAttributedString) -> Void
    var onTextViewCreated: ((NSTextView) -> Void)?
    @Binding var showSlashMenu: Bool
    @Binding var slashMenuPosition: CGPoint
    @Binding var slashSearchText: String

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSTextView.scrollableTextView()
        let textView = scrollView.documentView as! NSTextView

        textView.delegate = context.coordinator
        textView.isRichText = true
        textView.allowsUndo = true
        textView.font = .systemFont(ofSize: 16)
        textView.textColor = NSColor(textColor)
        textView.backgroundColor = .clear
        textView.drawsBackground = false
        textView.textContainerInset = NSSize(width: 16, height: 14)

        // Set initial text
        textView.textStorage?.setAttributedString(attributedText)

        // Notify parent of textView creation
        onTextViewCreated?(textView)

        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? NSTextView else { return }

        // Update text color based on current note color
        textView.textColor = NSColor(textColor)

        // Only update if the text is different to avoid cursor jumping
        if textView.attributedString() != attributedText {
            let selectedRange = textView.selectedRange()
            textView.textStorage?.setAttributedString(attributedText)
            if selectedRange.location <= textView.string.count {
                textView.setSelectedRange(selectedRange)
            }
        }
    }

    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: RichTextEditor
        var slashRange: NSRange?
        var isExecutingSlashCommand = false

        init(_ parent: RichTextEditor) {
            self.parent = parent
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }

            // Check if user just entered a newline, and reset formatting if so
            // Skip if we're executing a slash command
            if !isExecutingSlashCommand {
                let cursorPosition = textView.selectedRange().location
                if cursorPosition > 0 {
                    let text = textView.string
                    let previousCharIndex = text.index(text.startIndex, offsetBy: cursorPosition - 1)
                    let previousChar = text[previousCharIndex]

                    if previousChar.isNewline {
                        // Reset typing attributes to default
                        textView.typingAttributes = [
                            .font: NSFont.systemFont(ofSize: 16),
                            .foregroundColor: NSColor(parent.textColor)
                        ]
                    }
                }
            }

            // Check for slash command
            detectSlashCommand(in: textView)

            parent.onTextChange(textView.attributedString())
        }

        private func detectSlashCommand(in textView: NSTextView) {
            let text = textView.string
            let cursorPosition = textView.selectedRange().location

            // Look backwards from cursor to find "/"
            if cursorPosition > 0 {
                var searchIndex = cursorPosition - 1
                var foundSpace = false

                while searchIndex >= 0 {
                    let char = text[text.index(text.startIndex, offsetBy: searchIndex)]

                    if char == "/" {
                        // Found slash, get the text after it
                        let slashLocation = searchIndex
                        let searchText = String(text[text.index(text.startIndex, offsetBy: slashLocation + 1)..<text.index(text.startIndex, offsetBy: cursorPosition)])

                        // Show slash menu
                        slashRange = NSRange(location: slashLocation, length: cursorPosition - slashLocation)
                        parent.slashSearchText = searchText
                        parent.showSlashMenu = true

                        // Get cursor position for menu placement
                        if let rect = textView.layoutManager?.boundingRect(
                            forGlyphRange: NSRange(location: slashLocation, length: 1),
                            in: textView.textContainer!
                        ) {
                            parent.slashMenuPosition = CGPoint(
                                x: rect.origin.x,
                                y: rect.origin.y + rect.height
                            )
                        }
                        return
                    } else if char.isWhitespace || char.isNewline {
                        foundSpace = true
                        break
                    }

                    searchIndex -= 1
                }
            }

            // No slash found or invalid context, hide menu
            parent.showSlashMenu = false
            slashRange = nil
        }

        func replaceSlashWithCommand(_ textView: NSTextView) {
            guard let range = slashRange else { return }
            // Set flag to skip format reset during command execution
            isExecutingSlashCommand = true
            textView.setSelectedRange(range)
            textView.delete(nil)
            slashRange = nil
        }

        func finishSlashCommand() {
            // Reset flag after command execution is complete
            isExecutingSlashCommand = false
        }
    }
}

// Extension to create attributed string with default attributes
extension NSAttributedString {
    convenience init(string: String, color: NSColor) {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 16),
            .foregroundColor: color  // Use the provided color
        ]
        self.init(string: string, attributes: attributes)
    }
}
