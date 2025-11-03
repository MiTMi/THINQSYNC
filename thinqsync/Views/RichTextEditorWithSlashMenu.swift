//
//  RichTextEditorWithSlashMenu.swift
//  thinqsync
//
//  Created by Claude on 03/11/2025.
//

import SwiftUI
import AppKit

@MainActor
class TextViewCoordinator {
    var textView: NSTextView?
    var coordinator: RichTextEditor.Coordinator?
}

struct RichTextEditorWithSlashMenu: View {
    @Binding var attributedText: NSAttributedString
    var textColor: Color
    var onTextChange: (NSAttributedString) -> Void
    var containerHeight: CGFloat? = nil  // Optional explicit height for proper positioning

    @State private var showSlashMenu = false
    @State private var slashMenuPosition = CGPoint.zero
    @State private var slashSearchText = ""
    @State private var tvCoordinator = TextViewCoordinator()
    @State private var viewHeight: CGFloat = 0

    var body: some View {
        ZStack(alignment: .topLeading) {
            GeometryReader { geometry in
                RichTextEditor(
                    attributedText: $attributedText,
                    textColor: textColor,
                    onTextChange: onTextChange,
                    onTextViewCreated: { tv in
                        tvCoordinator.textView = tv
                        tvCoordinator.coordinator = tv.delegate as? RichTextEditor.Coordinator
                    },
                    showSlashMenu: $showSlashMenu,
                    slashMenuPosition: $slashMenuPosition,
                    slashSearchText: $slashSearchText
                )
                .onAppear {
                    viewHeight = containerHeight ?? geometry.size.height
                }
                .onChange(of: geometry.size) { _, newSize in
                    if containerHeight == nil {
                        viewHeight = newSize.height
                    }
                }
                .onChange(of: containerHeight) { _, newHeight in
                    if let height = newHeight {
                        viewHeight = height
                    }
                }
            }

            // Slash command menu overlay with smart positioning - OUTSIDE GeometryReader
            if showSlashMenu {
                SlashCommandMenu(
                    isPresented: $showSlashMenu,
                    searchText: $slashSearchText,
                    onCommandSelected: { command in
                        executeCommand(command)
                    }
                )
                .offset(x: slashMenuPosition.x, y: calculateMenuYPosition())
                .zIndex(1000)
            }
        }
    }

    private func calculateMenuYPosition() -> CGFloat {
        let menuHeight: CGFloat = 250 // Max height of menu
        let spaceBelow = viewHeight - slashMenuPosition.y

        print("📍 Menu Position Debug:")
        print("   Cursor Y: \(slashMenuPosition.y)")
        print("   View Height: \(viewHeight)")
        print("   Space Below: \(spaceBelow)")
        print("   Menu Height Needed: \(menuHeight + 40)")

        // Check if there's enough space below the cursor
        if spaceBelow < menuHeight + 40 {
            // Not enough space below - show menu above the cursor
            let abovePosition = slashMenuPosition.y - menuHeight - 10
            print("   ⬆️ Showing ABOVE at Y: \(abovePosition)")
            return abovePosition
        } else {
            // Enough space below - show menu below the cursor (default)
            let belowPosition = slashMenuPosition.y + 20
            print("   ⬇️ Showing BELOW at Y: \(belowPosition)")
            return belowPosition
        }
    }

    private func executeCommand(_ command: SlashCommand) {
        guard let textView = tvCoordinator.textView,
              let coordinator = tvCoordinator.coordinator else {
            print("❌ No textView or coordinator")
            return
        }

        print("✅ Executing command: \(command.title)")

        // Remove the slash and search text
        coordinator.replaceSlashWithCommand(textView)

        // Execute the command
        switch command {
        case .heading1:
            applyHeading(size: 24, textView: textView)
        case .heading2:
            applyHeading(size: 20, textView: textView)
        case .heading3:
            applyHeading(size: 18, textView: textView)
        case .bold:
            applyBold(textView: textView)
        case .italic:
            applyItalic(textView: textView)
        case .underline:
            applyUnderline(textView: textView)
        case .bulletList:
            insertText("• ", textView: textView)
        case .numberList:
            insertText("1. ", textView: textView)
        case .divider:
            insertText("\n───────────────────\n", textView: textView)
        case .clearFormatting:
            clearFormatting(textView: textView)
        }

        // Mark command execution as complete
        coordinator.finishSlashCommand()

        showSlashMenu = false

        // Trigger text change to update the binding
        onTextChange(textView.attributedString())
    }

    private func applyHeading(size: CGFloat, textView: NSTextView) {
        let font = NSFont.boldSystemFont(ofSize: size)
        textView.typingAttributes[.font] = font
        textView.insertText("", replacementRange: textView.selectedRange())
        print("Applied heading with size: \(size)")
    }

    private func applyBold(textView: NSTextView) {
        let font = NSFont.boldSystemFont(ofSize: 16)
        textView.typingAttributes[.font] = font
        textView.insertText("", replacementRange: textView.selectedRange())
        print("Applied bold")
    }

    private func applyItalic(textView: NSTextView) {
        let font = NSFont.systemFont(ofSize: 16).italic
        textView.typingAttributes[.font] = font
        textView.insertText("", replacementRange: textView.selectedRange())
        print("Applied italic")
    }

    private func applyUnderline(textView: NSTextView) {
        var attributes = textView.typingAttributes
        attributes[.underlineStyle] = NSUnderlineStyle.single.rawValue
        textView.typingAttributes = attributes
        textView.insertText("", replacementRange: textView.selectedRange())
        print("Applied underline")
    }

    private func insertText(_ text: String, textView: NSTextView) {
        textView.insertText(text, replacementRange: textView.selectedRange())
        print("Inserted text: \(text)")
    }

    private func clearFormatting(textView: NSTextView) {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 16),
            .foregroundColor: NSColor(textColor)
        ]
        textView.typingAttributes = attributes
        textView.insertText("", replacementRange: textView.selectedRange())
        print("Cleared formatting")
    }
}

extension NSFont {
    var italic: NSFont {
        let descriptor = fontDescriptor.withSymbolicTraits(.italic)
        return NSFont(descriptor: descriptor, size: pointSize) ?? self
    }
}
