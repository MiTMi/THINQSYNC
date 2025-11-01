//
//  FormattingToolbar.swift
//  thinqsync
//
//  Created by Michael   on 31/10/2025.
//

import SwiftUI
import AppKit

struct FormattingToolbar: View {
    let textView: NSTextView?
    var textColor: Color

    var body: some View {
        HStack(spacing: 16) {
            // Bold
            Button(action: {
                toggleBold()
            }) {
                Image(systemName: "bold")
                    .font(.system(size: 14))
            }
            .buttonStyle(.plain)
            .foregroundColor(textColor)

            // Italic
            Button(action: {
                toggleItalic()
            }) {
                Image(systemName: "italic")
                    .font(.system(size: 14))
            }
            .buttonStyle(.plain)
            .foregroundColor(textColor)

            // Underline
            Button(action: {
                toggleUnderline()
            }) {
                Image(systemName: "underline")
                    .font(.system(size: 14))
            }
            .buttonStyle(.plain)
            .foregroundColor(textColor)

            Divider()
                .frame(height: 20)

            // Font size
            Menu {
                ForEach([10, 12, 14, 16, 18, 20, 24], id: \.self) { size in
                    Button("\(size) pt") {
                        setFontSize(CGFloat(size))
                    }
                }
            } label: {
                Text("aA")
                    .font(.system(size: 14, weight: .medium))
            }
            .menuStyle(.borderlessButton)
            .foregroundColor(textColor)

            Divider()
                .frame(height: 20)

            // Alignment
            Button(action: {
                setAlignment(.left)
            }) {
                Image(systemName: "text.alignleft")
                    .font(.system(size: 14))
            }
            .buttonStyle(.plain)
            .foregroundColor(textColor)

            Button(action: {
                setAlignment(.center)
            }) {
                Image(systemName: "text.aligncenter")
                    .font(.system(size: 14))
            }
            .buttonStyle(.plain)
            .foregroundColor(textColor)

            Button(action: {
                setAlignment(.right)
            }) {
                Image(systemName: "text.alignright")
                    .font(.system(size: 14))
            }
            .buttonStyle(.plain)
            .foregroundColor(textColor)

            Divider()
                .frame(height: 20)

            // Lists
            Button(action: {
                insertBulletList()
            }) {
                Image(systemName: "list.bullet")
                    .font(.system(size: 14))
            }
            .buttonStyle(.plain)
            .foregroundColor(textColor)

            Button(action: {
                insertNumberedList()
            }) {
                Image(systemName: "list.number")
                    .font(.system(size: 14))
            }
            .buttonStyle(.plain)
            .foregroundColor(textColor)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Formatting Actions

    private func toggleBold() {
        guard let textView = textView,
              let textStorage = textView.textStorage else {
            print("⚠️ textView or textStorage is nil")
            return
        }

        // Make textView first responder
        textView.window?.makeFirstResponder(textView)

        let selectedRange = textView.selectedRange()
        guard selectedRange.length > 0 else {
            print("⚠️ No text selected. Selected range: \(selectedRange)")
            return
        }

        print("✓ Applying bold to range: \(selectedRange)")
        textStorage.beginEditing()
        textStorage.enumerateAttribute(.font, in: selectedRange) { value, range, _ in
            if let font = value as? NSFont {
                let isBold = font.fontDescriptor.symbolicTraits.contains(.bold)
                let newFont: NSFont
                if isBold {
                    newFont = NSFontManager.shared.convert(font, toNotHaveTrait: .boldFontMask)
                } else {
                    newFont = NSFontManager.shared.convert(font, toHaveTrait: .boldFontMask)
                }
                textStorage.addAttribute(.font, value: newFont, range: range)
                print("✓ Applied bold font: \(newFont.fontName)")
            }
        }
        textStorage.endEditing()
    }

    private func toggleItalic() {
        guard let textView = textView,
              let textStorage = textView.textStorage else { return }

        textView.window?.makeFirstResponder(textView)

        let selectedRange = textView.selectedRange()
        guard selectedRange.length > 0 else { return }

        textStorage.beginEditing()
        textStorage.enumerateAttribute(.font, in: selectedRange) { value, range, _ in
            if let font = value as? NSFont {
                let isItalic = font.fontDescriptor.symbolicTraits.contains(.italic)
                let newFont: NSFont
                if isItalic {
                    newFont = NSFontManager.shared.convert(font, toNotHaveTrait: .italicFontMask)
                } else {
                    newFont = NSFontManager.shared.convert(font, toHaveTrait: .italicFontMask)
                }
                textStorage.addAttribute(.font, value: newFont, range: range)
            }
        }
        textStorage.endEditing()
    }

    private func toggleUnderline() {
        guard let textView = textView,
              let textStorage = textView.textStorage else {
            print("⚠️ textView or textStorage is nil")
            return
        }

        textView.window?.makeFirstResponder(textView)

        let selectedRange = textView.selectedRange()
        guard selectedRange.length > 0 else {
            print("⚠️ No text selected. Selected range: \(selectedRange)")
            return
        }

        print("✓ Applying underline to range: \(selectedRange)")
        textStorage.beginEditing()
        textStorage.enumerateAttribute(.underlineStyle, in: selectedRange) { value, range, _ in
            let currentStyle = value as? Int ?? 0
            let newStyle = currentStyle == 0 ? NSUnderlineStyle.single.rawValue : 0
            textStorage.addAttribute(.underlineStyle, value: newStyle, range: range)
            print("✓ Applied underline style: \(newStyle)")
        }
        textStorage.endEditing()
    }

    private func setFontSize(_ size: CGFloat) {
        guard let textView = textView,
              let textStorage = textView.textStorage else {
            print("⚠️ textView or textStorage is nil")
            return
        }

        textView.window?.makeFirstResponder(textView)

        let selectedRange = textView.selectedRange()
        guard selectedRange.length > 0 else {
            print("⚠️ No text selected. Selected range: \(selectedRange)")
            return
        }

        print("✓ Setting font size to \(size) for range: \(selectedRange)")
        textStorage.beginEditing()
        textStorage.enumerateAttribute(.font, in: selectedRange) { value, range, _ in
            if let font = value as? NSFont {
                let newFont = NSFont(name: font.fontName, size: size) ?? NSFont.systemFont(ofSize: size)
                textStorage.addAttribute(.font, value: newFont, range: range)
                print("✓ Applied font size: \(size)")
            }
        }
        textStorage.endEditing()
    }

    private func setAlignment(_ alignment: NSTextAlignment) {
        guard let textView = textView else {
            print("⚠️ textView is nil")
            return
        }

        textView.window?.makeFirstResponder(textView)
        textView.alignment = alignment
        print("✓ Set alignment to: \(alignment.rawValue)")
    }

    private func insertBulletList() {
        guard let textView = textView else {
            print("⚠️ textView is nil")
            return
        }

        textView.window?.makeFirstResponder(textView)

        let selectedRange = textView.selectedRange()
        let currentText = textView.string

        if selectedRange.location < currentText.count {
            let lineRange = (currentText as NSString).lineRange(for: selectedRange)
            let line = (currentText as NSString).substring(with: lineRange)

            if !line.trimmingCharacters(in: .whitespacesAndNewlines).hasPrefix("•") {
                textView.insertText("• ", replacementRange: NSRange(location: lineRange.location, length: 0))
                print("✓ Inserted bullet point")
            }
        }
    }

    private func insertNumberedList() {
        guard let textView = textView else {
            print("⚠️ textView is nil")
            return
        }

        textView.window?.makeFirstResponder(textView)

        let selectedRange = textView.selectedRange()
        let currentText = textView.string

        if selectedRange.location < currentText.count {
            let lineRange = (currentText as NSString).lineRange(for: selectedRange)
            textView.insertText("1. ", replacementRange: NSRange(location: lineRange.location, length: 0))
            print("✓ Inserted numbered list")
        }
    }
}
