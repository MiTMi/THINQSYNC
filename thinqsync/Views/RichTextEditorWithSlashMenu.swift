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
    var onTextViewCreated: ((NSTextView) -> Void)? = nil
    var textViewRef: TextViewReference? = nil
    var containerHeight: CGFloat? = nil  // Optional explicit height for proper positioning

    @State private var showSlashMenu = false
    @State private var slashMenuPosition = CGPoint.zero
    @State private var slashSearchText = ""
    @State private var tvCoordinator = TextViewCoordinator()
    @State private var viewHeight: CGFloat = 0
    @State private var showAIError = false
    @State private var aiErrorMessage = ""
    @StateObject private var aiService = DeepseekAIService.shared

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
                        // Also notify parent if callback provided
                        onTextViewCreated?(tv)
                    },
                    showSlashMenu: $showSlashMenu,
                    slashMenuPosition: $slashMenuPosition,
                    slashSearchText: $slashSearchText,
                    textViewRef: textViewRef
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

            // Invisible overlay to detect clicks outside the menu
            if showSlashMenu {
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        dismissSlashMenu()
                    }
                    .zIndex(999)
            }

            // Slash command menu overlay with smart positioning - OUTSIDE GeometryReader
            if showSlashMenu {
                SlashCommandMenu(
                    isPresented: $showSlashMenu,
                    searchText: $slashSearchText,
                    onCommandSelected: { command in
                        executeCommand(command)
                    },
                    availableHeight: calculateAvailableMenuHeight()
                )
                .offset(x: slashMenuPosition.x, y: calculateMenuYPosition())
                .zIndex(1000)
            }

            // AI processing indicator
            if aiService.isProcessing {
                VStack {
                    Spacer()
                    HStack {
                        ProgressView()
                            .scaleEffect(0.7)
                        Text("AI is processing...")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    .padding(12)
                    .background(Color(nsColor: .windowBackgroundColor).opacity(0.95))
                    .cornerRadius(8)
                    .shadow(radius: 10)
                    .padding()
                }
                .zIndex(2000)
            }
        }
        .alert("AI Error", isPresented: $showAIError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(aiErrorMessage)
        }
    }

    private func dismissSlashMenu() {
        guard let textView = tvCoordinator.textView,
              let coordinator = tvCoordinator.coordinator else {
            showSlashMenu = false
            return
        }

        // Remove the slash and any search text
        coordinator.replaceSlashWithCommand(textView)
        coordinator.finishSlashCommand()

        // Hide the menu
        showSlashMenu = false

        // Refocus the text view
        textView.window?.makeFirstResponder(textView)
    }

    private func calculateAvailableMenuHeight() -> CGFloat {
        let spaceBelow = viewHeight - slashMenuPosition.y
        let spaceAbove = slashMenuPosition.y

        // Use the larger of the two spaces, with some padding
        let maxAvailableSpace = max(spaceBelow - 40, spaceAbove - 40)

        // Return constrained height (min 100, max 300)
        return max(100, min(maxAvailableSpace, 300))
    }

    private func calculateMenuYPosition() -> CGFloat {
        let menuHeight = calculateAvailableMenuHeight()
        let spaceBelow = viewHeight - slashMenuPosition.y

        print("📍 Menu Position Debug:")
        print("   Cursor Y: \(slashMenuPosition.y)")
        print("   View Height: \(viewHeight)")
        print("   Space Below: \(spaceBelow)")
        print("   Menu Height: \(menuHeight)")

        // Check if there's enough space below the cursor
        if spaceBelow < menuHeight + 40 {
            // Not enough space below - show menu above the cursor
            let abovePosition = slashMenuPosition.y - menuHeight - 10
            print("   ⬆️ Showing ABOVE at Y: \(abovePosition)")
            return max(10, abovePosition)  // Ensure menu doesn't go above top edge
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
            return
        }

        // Set formatting flag BEFORE deleting slash text to prevent view updates
        if let ref = textViewRef {
            ref.isFormatting = true
        }

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
        case .strikethrough:
            applyStrikethrough(textView: textView)
        case .bulletList:
            insertText("• ", textView: textView)
        case .numberList:
            insertText("1. ", textView: textView)
        case .divider:
            insertText("\n───────────────────\n", textView: textView)
        case .clearFormatting:
            clearFormatting(textView: textView)
        case .aiImproveWriting:
            executeAICommand(.improveWriting, textView: textView)
            return  // Return early for async AI commands
        case .aiSummarize:
            executeAICommand(.summarize, textView: textView)
            return
        case .aiExpand:
            executeAICommand(.expand, textView: textView)
            return
        case .aiFixGrammar:
            executeAICommand(.fixGrammar, textView: textView)
            return
        }

        // Mark command execution as complete
        coordinator.finishSlashCommand()

        showSlashMenu = false

        // Trigger text change to update the binding FIRST
        onTextChange(textView.attributedString())

        // Clear formatting flag AFTER binding update has been queued
        // Use async dispatch to ensure binding has propagated through SwiftUI
        DispatchQueue.main.async { [weak textViewRef] in
            textViewRef?.isFormatting = false
        }
    }

    private func applyHeading(size: CGFloat, textView: NSTextView) {
        guard let textStorage = textView.textStorage else { return }

        textView.window?.makeFirstResponder(textView)
        let selectedRange = textView.selectedRange()

        // If no text is selected, just set typing attributes for future text
        if selectedRange.length == 0 {
            let font = NSFont.boldSystemFont(ofSize: size)
            textView.typingAttributes[.font] = font
            return
        }

        // Apply to selected text
        textStorage.beginEditing()
        textStorage.enumerateAttribute(.font, in: selectedRange) { value, range, _ in
            let newFont = NSFont.boldSystemFont(ofSize: size)
            textStorage.addAttribute(.font, value: newFont, range: range)
        }
        textStorage.endEditing()

        // Also update typing attributes
        textView.typingAttributes[.font] = NSFont.boldSystemFont(ofSize: size)
    }

    private func applyBold(textView: NSTextView) {
        guard let textStorage = textView.textStorage else { return }

        textView.window?.makeFirstResponder(textView)
        let selectedRange = textView.selectedRange()

        // If no text is selected, just set typing attributes for future text
        if selectedRange.length == 0 {
            let font = NSFont.boldSystemFont(ofSize: 16)
            textView.typingAttributes[.font] = font
            return
        }

        // Apply to selected text - toggle bold on/off
        textStorage.beginEditing()
        textStorage.enumerateAttribute(.font, in: selectedRange) { value, range, _ in
            let font = value as? NSFont ?? NSFont.systemFont(ofSize: 16)
            let isBold = font.fontDescriptor.symbolicTraits.contains(.bold)
            let newFont = isBold ?
                NSFontManager.shared.convert(font, toNotHaveTrait: .boldFontMask) :
                NSFontManager.shared.convert(font, toHaveTrait: .boldFontMask)
            textStorage.addAttribute(.font, value: newFont, range: range)
        }
        textStorage.endEditing()
    }

    private func applyItalic(textView: NSTextView) {
        guard let textStorage = textView.textStorage else { return }

        textView.window?.makeFirstResponder(textView)
        let selectedRange = textView.selectedRange()

        // If no text is selected, just set typing attributes for future text
        if selectedRange.length == 0 {
            let font = NSFont.systemFont(ofSize: 16).italic
            textView.typingAttributes[.font] = font
            return
        }

        // Apply to selected text - toggle italic on/off
        textStorage.beginEditing()
        textStorage.enumerateAttribute(.font, in: selectedRange) { value, range, _ in
            let font = value as? NSFont ?? NSFont.systemFont(ofSize: 16)
            let isItalic = font.fontDescriptor.symbolicTraits.contains(.italic)
            let newFont = isItalic ?
                NSFontManager.shared.convert(font, toNotHaveTrait: .italicFontMask) :
                NSFontManager.shared.convert(font, toHaveTrait: .italicFontMask)
            textStorage.addAttribute(.font, value: newFont, range: range)
        }
        textStorage.endEditing()
    }

    private func applyUnderline(textView: NSTextView) {
        guard let textStorage = textView.textStorage else { return }

        textView.window?.makeFirstResponder(textView)
        let selectedRange = textView.selectedRange()

        // If no text is selected, just set typing attributes for future text
        if selectedRange.length == 0 {
            var attributes = textView.typingAttributes
            attributes[.underlineStyle] = NSUnderlineStyle.single.rawValue
            textView.typingAttributes = attributes
            return
        }

        // Apply to selected text - toggle underline on/off
        textStorage.beginEditing()
        textStorage.enumerateAttribute(.underlineStyle, in: selectedRange) { value, range, _ in
            let currentStyle = value as? Int ?? 0
            let newStyle = currentStyle == 0 ? NSUnderlineStyle.single.rawValue : 0
            textStorage.addAttribute(.underlineStyle, value: newStyle, range: range)
        }
        textStorage.endEditing()
    }

    private func applyStrikethrough(textView: NSTextView) {
        guard let textStorage = textView.textStorage else { return }

        textView.window?.makeFirstResponder(textView)
        let selectedRange = textView.selectedRange()

        // If no text is selected, just set typing attributes for future text
        if selectedRange.length == 0 {
            var attributes = textView.typingAttributes
            attributes[.strikethroughStyle] = NSUnderlineStyle.single.rawValue
            textView.typingAttributes = attributes
            print("✅ Set strikethrough typing attributes")
            return
        }

        // Apply to selected text - toggle strikethrough on/off
        textStorage.beginEditing()
        textStorage.enumerateAttribute(.strikethroughStyle, in: selectedRange) { value, range, _ in
            let currentStyle = value as? Int ?? 0
            let newStyle = currentStyle == 0 ? NSUnderlineStyle.single.rawValue : 0
            textStorage.addAttribute(.strikethroughStyle, value: newStyle, range: range)
        }
        textStorage.endEditing()

        print("✅ Toggled strikethrough on selected text")
    }

    private func insertText(_ text: String, textView: NSTextView) {
        textView.insertText(text, replacementRange: textView.selectedRange())
        print("Inserted text: \(text)")
    }

    private func clearFormatting(textView: NSTextView) {
        guard let textStorage = textView.textStorage else {
            print("❌ No textStorage in clearFormatting")
            return
        }

        textView.window?.makeFirstResponder(textView)
        let selectedRange = textView.selectedRange()

        let defaultAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 16),
            .foregroundColor: NSColor(textColor)
        ]

        // If no text is selected, just set typing attributes for future text
        if selectedRange.length == 0 {
            textView.typingAttributes = defaultAttributes
            print("✅ Set default typing attributes")
            return
        }

        // Apply to selected text - remove all formatting
        textStorage.beginEditing()
        textStorage.setAttributes(defaultAttributes, range: selectedRange)
        textStorage.endEditing()

        // Also update typing attributes
        textView.typingAttributes = defaultAttributes

        print("✅ Cleared formatting on selected text")
    }

    // MARK: - AI Commands

    private func executeAICommand(_ operation: DeepseekAIService.AIOperation, textView: NSTextView) {
        guard let coordinator = tvCoordinator.coordinator else {
            print("❌ No coordinator")
            return
        }

        // Get selected text
        let selectedRange = textView.selectedRange()
        let selectedText: String

        if selectedRange.length > 0 {
            selectedText = (textView.string as NSString).substring(with: selectedRange)
        } else {
            // If no selection, use all text
            selectedText = textView.string
        }

        // Store the range for later replacement
        let rangeToReplace = selectedRange.length > 0 ? selectedRange : NSRange(location: 0, length: textView.string.count)

        // Mark command execution as complete and hide menu
        coordinator.finishSlashCommand()
        showSlashMenu = false

        // Execute AI operation
        Task { [weak textViewRef] in
            do {
                let result = try await aiService.processText(selectedText, operation: operation)

                // Replace text with AI result
                await MainActor.run {
                    textView.textStorage?.replaceCharacters(in: rangeToReplace, with: result)
                    onTextChange(textView.attributedString())

                    // Clear formatting flag after AI result is applied
                    DispatchQueue.main.async {
                        textViewRef?.isFormatting = false
                    }
                }
            } catch {
                await MainActor.run {
                    aiErrorMessage = error.localizedDescription
                    showAIError = true

                    // Clear formatting flag even on error
                    DispatchQueue.main.async {
                        textViewRef?.isFormatting = false
                    }
                }
            }
        }
    }
}

extension NSFont {
    var italic: NSFont {
        let descriptor = fontDescriptor.withSymbolicTraits(.italic)
        return NSFont(descriptor: descriptor, size: pointSize) ?? self
    }
}
