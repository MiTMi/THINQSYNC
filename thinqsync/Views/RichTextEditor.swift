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
    var textViewRef: TextViewReference? = nil

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

        // Enable real-time grammar and spelling checking
        textView.isContinuousSpellCheckingEnabled = true
        textView.isGrammarCheckingEnabled = true
        textView.isAutomaticSpellingCorrectionEnabled = true
        textView.isAutomaticTextReplacementEnabled = true

        // Enable RTL (Right-to-Left) language support for Hebrew, Arabic, etc.
        textView.baseWritingDirection = .natural  // Automatically detects text direction
        textView.usesFontPanel = true
        textView.usesRuler = true

        // Set default typing attributes
        textView.typingAttributes = [
            .font: NSFont.systemFont(ofSize: 16),
            .foregroundColor: NSColor(textColor)
        ]

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

        // Skip ALL updates if we're actively formatting
        // This prevents the binding from overwriting user's formatting changes
        if let ref = textViewRef, ref.isFormatting {
            return
        }

        // Only reset typing attributes when NOT formatting
        // This preserves formatting set by slash commands
        textView.typingAttributes[.foregroundColor] = NSColor(textColor)

        // Only update if the text is different to avoid cursor jumping
        if textView.attributedString() != attributedText {
            let selectedRange = textView.selectedRange()
            textView.textStorage?.setAttributedString(attributedText)
            if selectedRange.location <= textView.string.count {
                textView.setSelectedRange(selectedRange)
            }
        }

        // CRITICAL: Update default color for ALL existing text AFTER setting attributed text
        // This fixes the issue where notes created in dark mode show white text in light mode
        // Must run AFTER setAttributedString to override any stored colors from the binding
        if let textStorage = textView.textStorage {
            let fullRange = NSRange(location: 0, length: textStorage.length)
            let targetColor = NSColor(textColor)

            textStorage.beginEditing()
            textStorage.enumerateAttribute(.foregroundColor, in: fullRange) { value, range, _ in
                if let existingColor = value as? NSColor {
                    // Check if this is a default text color (white or black with full opacity)
                    // by comparing against common system text colors
                    let isWhite = existingColor.isClose(to: .white)
                    let isBlack = existingColor.isClose(to: .black)
                    let isLabelColor = existingColor.isClose(to: .labelColor)

                    // Update if it's a default system text color (white, black, or labelColor)
                    if isWhite || isBlack || isLabelColor {
                        textStorage.addAttribute(.foregroundColor, value: targetColor, range: range)
                    }
                } else {
                    // No color set - apply the current text color
                    textStorage.addAttribute(.foregroundColor, value: targetColor, range: range)
                }
            }
            textStorage.endEditing()
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

            // Skip binding updates if we're executing a slash command or formatting
            // This prevents binding updates that would restore old text
            let isFormatting = parent.textViewRef?.isFormatting ?? false
            let shouldSkipUpdate = isExecutingSlashCommand || isFormatting

            // Detect and auto-adjust text direction for RTL languages (Hebrew, Arabic, etc.)
            detectAndAdjustTextDirection(in: textView)

            // ALWAYS detect slash commands, regardless of formatting state
            // This ensures "/" is detected even during formatting operations
            detectSlashCommand(in: textView)

            // Only skip binding updates and format reset when formatting
            if !shouldSkipUpdate {
                // Check if user just entered a newline, and reset formatting if so
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

                // Update the binding
                parent.onTextChange(textView.attributedString())
            }
        }

        private func detectSlashCommand(in textView: NSTextView) {
            let text = textView.string
            let cursorPosition = textView.selectedRange().location

            // Look backwards from cursor to find "/"
            if cursorPosition > 0 {
                var searchIndex = cursorPosition - 1

                while searchIndex >= 0 {
                    let char = text[text.index(text.startIndex, offsetBy: searchIndex)]

                    if char == "/" {
                        // Found slash, get the text after it
                        let slashLocation = searchIndex
                        let searchText = String(text[text.index(text.startIndex, offsetBy: slashLocation + 1)..<text.index(text.startIndex, offsetBy: cursorPosition)])

                        // Store range for later
                        slashRange = NSRange(location: slashLocation, length: cursorPosition - slashLocation)

                        // Get cursor position for menu placement
                        let menuPosition: CGPoint
                        if let rect = textView.layoutManager?.boundingRect(
                            forGlyphRange: NSRange(location: slashLocation, length: 1),
                            in: textView.textContainer!
                        ) {
                            menuPosition = CGPoint(
                                x: rect.origin.x,
                                y: rect.origin.y + rect.height
                            )
                        } else {
                            menuPosition = .zero
                        }

                        // CRITICAL FIX: Update SwiftUI state OUTSIDE the view update cycle
                        // This prevents "Modifying state during view update" error
                        DispatchQueue.main.async { [parent] in
                            parent.slashSearchText = searchText
                            parent.slashMenuPosition = menuPosition
                            parent.showSlashMenu = true
                        }
                        return
                    } else if char.isWhitespace || char.isNewline {
                        // Stop searching if we hit whitespace before finding "/"
                        break
                    }

                    searchIndex -= 1
                }
            }

            // No slash found or invalid context, hide menu (async to avoid state modification warning)
            DispatchQueue.main.async { [parent] in
                parent.showSlashMenu = false
            }
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

        // Detect RTL characters and auto-adjust text alignment
        private func detectAndAdjustTextDirection(in textView: NSTextView) {
            let text = textView.string

            // Check if text contains RTL characters (Hebrew: 0x0590-0x05FF, Arabic: 0x0600-0x06FF)
            let hasRTLCharacters = text.unicodeScalars.contains { scalar in
                // Hebrew range
                (scalar.value >= 0x0590 && scalar.value <= 0x05FF) ||
                // Arabic range
                (scalar.value >= 0x0600 && scalar.value <= 0x06FF) ||
                // Hebrew Extended range
                (scalar.value >= 0xFB1D && scalar.value <= 0xFB4F) ||
                // Arabic Presentation Forms
                (scalar.value >= 0xFB50 && scalar.value <= 0xFDFF) ||
                (scalar.value >= 0xFE70 && scalar.value <= 0xFEFF)
            }

            // Get the current paragraph style
            let currentParagraphStyle = textView.defaultParagraphStyle ?? NSParagraphStyle.default
            let mutableParagraphStyle = currentParagraphStyle.mutableCopy() as! NSMutableParagraphStyle

            // Set alignment based on text content
            if hasRTLCharacters {
                // RTL text detected - align right
                if mutableParagraphStyle.alignment != .right {
                    mutableParagraphStyle.alignment = .right
                    mutableParagraphStyle.baseWritingDirection = .rightToLeft
                    textView.defaultParagraphStyle = mutableParagraphStyle
                    textView.alignment = .right

                    // Update existing text alignment
                    if let textStorage = textView.textStorage {
                        let fullRange = NSRange(location: 0, length: textStorage.length)
                        textStorage.addAttribute(.paragraphStyle, value: mutableParagraphStyle, range: fullRange)
                    }
                }
            } else if !text.isEmpty {
                // LTR text or empty - align left
                if mutableParagraphStyle.alignment != .left {
                    mutableParagraphStyle.alignment = .left
                    mutableParagraphStyle.baseWritingDirection = .leftToRight
                    textView.defaultParagraphStyle = mutableParagraphStyle
                    textView.alignment = .left

                    // Update existing text alignment
                    if let textStorage = textView.textStorage {
                        let fullRange = NSRange(location: 0, length: textStorage.length)
                        textStorage.addAttribute(.paragraphStyle, value: mutableParagraphStyle, range: fullRange)
                    }
                }
            }
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

// Extension to compare NSColors with tolerance for color space differences
extension NSColor {
    func isClose(to otherColor: NSColor, tolerance: CGFloat = 0.1) -> Bool {
        // Convert both colors to RGB color space for comparison
        guard let selfRGB = self.usingColorSpace(.deviceRGB),
              let otherRGB = otherColor.usingColorSpace(.deviceRGB) else {
            return false
        }

        let redDiff = abs(selfRGB.redComponent - otherRGB.redComponent)
        let greenDiff = abs(selfRGB.greenComponent - otherRGB.greenComponent)
        let blueDiff = abs(selfRGB.blueComponent - otherRGB.blueComponent)

        return redDiff < tolerance && greenDiff < tolerance && blueDiff < tolerance
    }
}
