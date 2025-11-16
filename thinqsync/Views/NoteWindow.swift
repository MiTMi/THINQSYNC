//
//  NoteWindow.swift
//  thinqsync
//
//  Created by Michael   on 31/10/2025.
//

import SwiftUI
import Combine

// Reference holder that doesn't trigger view updates
@MainActor
class TextViewReference: ObservableObject {
    var textView: NSTextView?
    var isFormatting = false

    var isReady: Bool {
        textView != nil
    }
}

struct NoteWindow: View {
    @Binding var note: Note
    @Environment(NotesManager.self) private var notesManager
    @Environment(\.dismiss) private var dismiss
    @State private var showingColorPicker = false
    @StateObject private var textViewRef = TextViewReference()
    @State private var windowConfigured = false

    var body: some View {
        VStack(spacing: 0) {
            // Custom title bar with darker shade
            CustomTitleBar(
                note: $note,
                textViewRef: textViewRef,
                onClose: {
                    // Defer state changes to avoid modifying state during view update
                    DispatchQueue.main.async {
                        notesManager.closeNote(note.id)
                        dismiss()
                    }
                },
                onMinimize: {
                    // Minimize functionality
                    DispatchQueue.main.async {
                        if let window = NSApp.keyWindow {
                            window.miniaturize(nil)
                        }
                    }
                },
                onDelete: {
                    // Delete the note then close
                    DispatchQueue.main.async {
                        notesManager.deleteNote(note)
                        dismiss()
                    }
                }
            )
            .background(
                note.color.backgroundColor
                    .opacity(0.9) // Slightly darker header
            )
            .overlay(
                Rectangle()
                    .fill(Color.black.opacity(0.1))
                    .frame(height: 1),
                alignment: .bottom
            )

            // Main content area with text
            NoteContentArea(note: $note, textViewRef: textViewRef)
                .background(note.color.backgroundColor) // Apply color directly to content area
        }
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(Color.black.opacity(0.15), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.15), radius: 20, x: 0, y: 10)
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
        .ignoresSafeArea(.all, edges: .top)
        .background(WindowAccessor(onWindowReady: { window in
            configureWindow(window)
        }))
    }

    private func configureWindow(_ window: NSWindow) {
        // Only configure once to avoid repeated modifications
        guard !windowConfigured else { return }
        windowConfigured = true

        // Restore saved window frame if it exists, otherwise use default size
        if let savedFrame = note.windowFrame {
            window.setFrame(savedFrame, display: true)
        } else {
            // Default window size
            let currentOrigin = window.frame.origin
            let newFrame = NSRect(x: currentOrigin.x, y: currentOrigin.y, width: 530, height: 330)
            window.setFrame(newFrame, display: true)
        }

        // Set window to float
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        // Use fullSizeContentView instead of borderless to maintain key/main status
        // This is the correct approach according to Apple's documentation
        window.styleMask.insert(.fullSizeContentView)

        // Remove standard window buttons
        window.standardWindowButton(.closeButton)?.isHidden = true
        window.standardWindowButton(.miniaturizeButton)?.isHidden = true
        window.standardWindowButton(.zoomButton)?.isHidden = true

        // Configure window appearance - titlebar becomes transparent and content extends underneath
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.isMovableByWindowBackground = true
        window.backgroundColor = .clear
        window.isOpaque = false
        window.hasShadow = false  // We add our own shadow in SwiftUI

        // Set up notification observer to save window frame when it changes
        NotificationCenter.default.addObserver(
            forName: NSWindow.didResizeNotification,
            object: window,
            queue: .main
        ) { [weak window] _ in
            if let window = window {
                Task { @MainActor in
                    // Save window frame
                    note.windowFrame = window.frame
                    notesManager.updateNote(note)
                }
            }
        }

        NotificationCenter.default.addObserver(
            forName: NSWindow.didMoveNotification,
            object: window,
            queue: .main
        ) { [weak window] _ in
            if let window = window {
                Task { @MainActor in
                    // Save window frame
                    note.windowFrame = window.frame
                    notesManager.updateNote(note)
                }
            }
        }
    }
}

// Helper to access the window properly
struct WindowAccessor: NSViewRepresentable {
    let onWindowReady: (NSWindow) -> Void

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            if let window = view.window {
                self.onWindowReady(window)
            }
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        // Check if window is available on updates too
        if let window = nsView.window {
            onWindowReady(window)
        }
    }
}

struct CustomTitleBar: View {
    @Binding var note: Note
    let textViewRef: TextViewReference
    var onClose: () -> Void
    var onMinimize: () -> Void
    var onDelete: () -> Void

    @Environment(NotesManager.self) private var notesManager
    @Environment(\.openWindow) private var openWindow
    @Environment(\.colorScheme) private var colorScheme

    @State private var isHoveringClose = false
    @State private var isHoveringMinimize = false
    @State private var isHoveringDelete = false
    @State private var showingOptionsMenu = false
    @State private var showingFormatMenu = false
    @State private var showingAIMenu = false
    @State private var showingMoreMenu = false
    @StateObject private var aiService = DeepseekAIService.shared

    // Strong black color for neo-brutalism style
    private var adaptiveColor: Color {
        .black
    }

    private var shadowColor: Color {
        .white
    }

    var body: some View {
        HStack(spacing: 0) {
            // Left side: Close and Minimize buttons
            HStack(spacing: 8) {
                // Close button (X)
                Button(action: onClose) {
                    ZStack {
                        Circle()
                            .fill(adaptiveColor.opacity(isHoveringClose ? 0.3 : 0.2))
                            .frame(width: 32, height: 32)

                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .black))
                            .foregroundColor(adaptiveColor)
                    }
                }
                .buttonStyle(.plain)
                .onHover { hovering in
                    isHoveringClose = hovering
                }

                // Minimize button (down arrow)
                Button(action: onMinimize) {
                    ZStack {
                        Circle()
                            .fill(adaptiveColor.opacity(isHoveringMinimize ? 0.3 : 0.2))
                            .frame(width: 32, height: 32)

                        Image(systemName: "chevron.down")
                            .font(.system(size: 14, weight: .black))
                            .foregroundColor(adaptiveColor)
                    }
                }
                .buttonStyle(.plain)
                .onHover { hovering in
                    isHoveringMinimize = hovering
                }
            }
            .padding(.leading, 12)

            // Title (left-aligned)
            TextField("", text: $note.title, prompt: Text("New Note").foregroundColor(adaptiveColor.opacity(0.6)))
                .textFieldStyle(.plain)
                .font(.system(size: 20, weight: .black))
                .foregroundColor(adaptiveColor)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 12)

            // iCloud sync indicator
            if notesManager.iCloudEnabled {
                HStack(spacing: 4) {
                    Image(systemName: notesManager.isSyncing ? "icloud.and.arrow.up" : "icloud")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(adaptiveColor.opacity(0.7))
                        .symbolEffect(.pulse, options: .repeating, isActive: notesManager.isSyncing)

                    if notesManager.isSyncing {
                        Text("Syncing...")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(adaptiveColor.opacity(0.6))
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(adaptiveColor.opacity(0.08))
                .cornerRadius(8)
            }

            Spacer()

            // Right side: Menu buttons with circular backgrounds
            HStack(spacing: 12) {
                // Hamburger menu - Using Button with popover instead of Menu
                Button(action: {
                    showingOptionsMenu.toggle()
                }) {
                    ZStack {
                        Circle()
                            .fill(adaptiveColor.opacity(0.2))
                            .frame(width: 36, height: 36)

                        Circle()
                            .stroke(adaptiveColor.opacity(0.4), lineWidth: 2)
                            .frame(width: 36, height: 36)

                        Image(systemName: "list.bullet")
                            .font(.system(size: 14, weight: .black))
                            .foregroundColor(adaptiveColor)
                    }
                    .frame(width: 36, height: 36)
                }
                .buttonStyle(.plain)
                .popover(isPresented: $showingOptionsMenu, arrowEdge: .bottom) {
                    VStack(alignment: .leading, spacing: 0) {
                        Button(action: {
                            note.isFavorite.toggle()
                            notesManager.updateNote(note)
                            showingOptionsMenu = false
                        }) {
                            Label(
                                note.isFavorite ? "Remove from Favorites" : "Add to Favorites",
                                systemImage: note.isFavorite ? "star.fill" : "star"
                            )
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                        }
                        .buttonStyle(.plain)

                        Divider()

                        // Color submenu
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Change Color")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 12)
                                .padding(.top, 8)

                            ForEach(NoteColor.allCases, id: \.self) { color in
                                Button(action: {
                                    note.color = color
                                    notesManager.updateNote(note)
                                    showingOptionsMenu = false
                                }) {
                                    HStack {
                                        Circle()
                                            .fill(color.backgroundColor)
                                            .frame(width: 12, height: 12)
                                        Text(color.rawValue.capitalized)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        Divider()

                        Button(action: {
                            showingOptionsMenu = false
                            onDelete()
                        }) {
                            Label("Delete Note", systemImage: "trash")
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                        }
                        .buttonStyle(.plain)
                    }
                    .frame(width: 220)
                    .padding(.vertical, 8)
                }

                // Text formatting button (A) - Using Button with popover
                Button(action: {
                    showingFormatMenu.toggle()
                }) {
                    ZStack {
                        Circle()
                            .fill(adaptiveColor.opacity(0.2))
                            .frame(width: 36, height: 36)

                        Circle()
                            .stroke(adaptiveColor.opacity(0.4), lineWidth: 2)
                            .frame(width: 36, height: 36)

                        Text("A")
                            .font(.system(size: 16, weight: .black))
                            .foregroundColor(adaptiveColor)
                    }
                    .frame(width: 36, height: 36)
                }
                .buttonStyle(.plain)
                .popover(isPresented: $showingFormatMenu, arrowEdge: .bottom) {
                    VStack(alignment: .leading, spacing: 0) {
                        Button(action: {
                            toggleBold()
                            showingFormatMenu = false
                        }) {
                            Label("Bold", systemImage: "bold")
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                        }
                        .buttonStyle(.plain)

                        Button(action: {
                            toggleItalic()
                            showingFormatMenu = false
                        }) {
                            Label("Italic", systemImage: "italic")
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                        }
                        .buttonStyle(.plain)

                        Button(action: {
                            toggleUnderline()
                            showingFormatMenu = false
                        }) {
                            Label("Underline", systemImage: "underline")
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                        }
                        .buttonStyle(.plain)

                        Button(action: {
                            toggleStrikethrough()
                            showingFormatMenu = false
                        }) {
                            Label("Strikethrough", systemImage: "strikethrough")
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                        }
                        .buttonStyle(.plain)

                        Divider()

                        // Font sizes
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Font Size")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 12)
                                .padding(.top, 8)

                            ForEach([10, 12, 14, 16, 18, 20, 24], id: \.self) { size in
                                Button("\(size) pt") {
                                    setFontSize(CGFloat(size))
                                    showingFormatMenu = false
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .buttonStyle(.plain)
                            }
                        }

                        Divider()

                        // Alignment
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Alignment")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 12)
                                .padding(.top, 8)

                            Button(action: {
                                setAlignment(.left)
                                showingFormatMenu = false
                            }) {
                                Label("Left", systemImage: "text.alignleft")
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                            }
                            .buttonStyle(.plain)

                            Button(action: {
                                setAlignment(.center)
                                showingFormatMenu = false
                            }) {
                                Label("Center", systemImage: "text.aligncenter")
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                            }
                            .buttonStyle(.plain)

                            Button(action: {
                                setAlignment(.right)
                                showingFormatMenu = false
                            }) {
                                Label("Right", systemImage: "text.alignright")
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .frame(width: 200)
                    .padding(.vertical, 8)
                }

                // AI button - Using Button with popover
                Button(action: {
                    showingAIMenu.toggle()
                }) {
                    ZStack {
                        Circle()
                            .fill(adaptiveColor.opacity(0.2))
                            .frame(width: 36, height: 36)

                        Circle()
                            .stroke(adaptiveColor.opacity(0.4), lineWidth: 2)
                            .frame(width: 36, height: 36)

                        Image(systemName: "sparkles")
                            .font(.system(size: 14, weight: .black))
                            .foregroundColor(adaptiveColor)
                    }
                    .frame(width: 36, height: 36)
                }
                .buttonStyle(.plain)
                .popover(isPresented: $showingAIMenu, arrowEdge: .bottom) {
                    VStack(alignment: .leading, spacing: 0) {
                        Button(action: {
                            executeAICommand(.improveWriting)
                            showingAIMenu = false
                        }) {
                            Label("AI: Improve Writing", systemImage: "wand.and.stars")
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                        }
                        .buttonStyle(.plain)

                        Button(action: {
                            executeAICommand(.summarize)
                            showingAIMenu = false
                        }) {
                            Label("AI: Summarize", systemImage: "doc.text.magnifyingglass")
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                        }
                        .buttonStyle(.plain)

                        Button(action: {
                            executeAICommand(.expand)
                            showingAIMenu = false
                        }) {
                            Label("AI: Expand", systemImage: "arrow.up.left.and.arrow.down.right")
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                        }
                        .buttonStyle(.plain)

                        Button(action: {
                            executeAICommand(.fixGrammar)
                            showingAIMenu = false
                        }) {
                            Label("AI: Fix Grammar", systemImage: "checkmark.seal")
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                        }
                        .buttonStyle(.plain)
                    }
                    .frame(width: 220)
                    .padding(.vertical, 8)
                }

                // More options (three dots) - Using Button with popover
                Button(action: {
                    showingMoreMenu.toggle()
                }) {
                    ZStack {
                        Circle()
                            .fill(adaptiveColor.opacity(0.2))
                            .frame(width: 36, height: 36)

                        Circle()
                            .stroke(adaptiveColor.opacity(0.4), lineWidth: 2)
                            .frame(width: 36, height: 36)

                        Image(systemName: "ellipsis")
                            .font(.system(size: 14, weight: .black))
                            .foregroundColor(adaptiveColor)
                    }
                    .frame(width: 36, height: 36)
                }
                .buttonStyle(.plain)
                .popover(isPresented: $showingMoreMenu, arrowEdge: .bottom) {
                    VStack(alignment: .leading, spacing: 0) {
                        Button(action: {
                            exportAsText()
                            showingMoreMenu = false
                        }) {
                            Label("Export as Text", systemImage: "square.and.arrow.up")
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                        }
                        .buttonStyle(.plain)

                        Button(action: {
                            printNote()
                            showingMoreMenu = false
                        }) {
                            Label("Print", systemImage: "printer")
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                        }
                        .buttonStyle(.plain)

                        Divider()

                        Button(action: {
                            duplicateNote()
                            showingMoreMenu = false
                        }) {
                            Label("Duplicate", systemImage: "doc.on.doc")
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                        }
                        .buttonStyle(.plain)

                        Divider()

                        Button(action: {
                            showingMoreMenu = false
                            openWindow(id: "ai-settings")
                        }) {
                            Label("AI Settings", systemImage: "brain")
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                        }
                        .buttonStyle(.plain)
                    }
                    .frame(width: 200)
                    .padding(.vertical, 8)
                }

                // Delete button (trash icon)
                Button(action: {
                    onDelete()
                }) {
                    ZStack {
                        Circle()
                            .fill(adaptiveColor.opacity(isHoveringDelete ? 0.3 : 0.2))
                            .frame(width: 36, height: 36)

                        Circle()
                            .stroke(adaptiveColor.opacity(isHoveringDelete ? 0.6 : 0.4), lineWidth: 2)
                            .frame(width: 36, height: 36)

                        Image(systemName: "trash")
                            .font(.system(size: 14, weight: .black))
                            .foregroundColor(isHoveringDelete ? Color.red : adaptiveColor)
                    }
                    .frame(width: 36, height: 36)
                }
                .buttonStyle(.plain)
                .onHover { hovering in
                    isHoveringDelete = hovering
                }
            }
            .padding(.trailing, 16)
        }
        .frame(height: 44)
        .background(.clear)
    }

    // Text formatting functions
    private func toggleBold() {
        guard let textView = textViewRef.textView,
              let textStorage = textView.textStorage else {
            print("TextView is nil in toggleBold")
            return
        }

        // Set formatting flag to prevent updateNSView from overwriting
        textViewRef.isFormatting = true
        defer { textViewRef.isFormatting = false }

        textView.window?.makeFirstResponder(textView)
        let selectedRange = textView.selectedRange()

        // If no text is selected, select all
        let rangeToFormat = selectedRange.length > 0 ? selectedRange : NSRange(location: 0, length: textView.string.count)

        textStorage.beginEditing()
        textStorage.enumerateAttribute(.font, in: rangeToFormat) { value, range, _ in
            let font = value as? NSFont ?? NSFont.systemFont(ofSize: 16)
            let isBold = font.fontDescriptor.symbolicTraits.contains(.bold)
            let newFont = isBold ?
                NSFontManager.shared.convert(font, toNotHaveTrait: .boldFontMask) :
                NSFontManager.shared.convert(font, toHaveTrait: .boldFontMask)
            textStorage.addAttribute(.font, value: newFont, range: range)
        }
        textStorage.endEditing()

        // Update the note with formatted content
        note.attributedContent = textView.attributedString()
        note.modifiedAt = Date()
        notesManager.updateNote(note)
    }

    private func toggleItalic() {
        guard let textView = textViewRef.textView,
              let textStorage = textView.textStorage else {
            print("TextView is nil in toggleItalic")
            return
        }

        // Set formatting flag to prevent updateNSView from overwriting
        textViewRef.isFormatting = true
        defer { textViewRef.isFormatting = false }

        textView.window?.makeFirstResponder(textView)
        let selectedRange = textView.selectedRange()
        let rangeToFormat = selectedRange.length > 0 ? selectedRange : NSRange(location: 0, length: textView.string.count)

        textStorage.beginEditing()
        textStorage.enumerateAttribute(.font, in: rangeToFormat) { value, range, _ in
            let font = value as? NSFont ?? NSFont.systemFont(ofSize: 16)
            let isItalic = font.fontDescriptor.symbolicTraits.contains(.italic)
            let newFont = isItalic ?
                NSFontManager.shared.convert(font, toNotHaveTrait: .italicFontMask) :
                NSFontManager.shared.convert(font, toHaveTrait: .italicFontMask)
            textStorage.addAttribute(.font, value: newFont, range: range)
        }
        textStorage.endEditing()

        // Update the note with formatted content
        note.attributedContent = textView.attributedString()
        note.modifiedAt = Date()
        notesManager.updateNote(note)
    }

    private func toggleUnderline() {
        guard let textView = textViewRef.textView,
              let textStorage = textView.textStorage else {
            print("TextView is nil in toggleUnderline")
            return
        }

        // Set formatting flag to prevent updateNSView from overwriting
        textViewRef.isFormatting = true
        defer { textViewRef.isFormatting = false }

        textView.window?.makeFirstResponder(textView)
        let selectedRange = textView.selectedRange()
        let rangeToFormat = selectedRange.length > 0 ? selectedRange : NSRange(location: 0, length: textView.string.count)

        textStorage.beginEditing()
        textStorage.enumerateAttribute(.underlineStyle, in: rangeToFormat) { value, range, _ in
            let currentStyle = value as? Int ?? 0
            let newStyle = currentStyle == 0 ? NSUnderlineStyle.single.rawValue : 0
            textStorage.addAttribute(.underlineStyle, value: newStyle, range: range)
        }
        textStorage.endEditing()

        // Update the note with formatted content
        note.attributedContent = textView.attributedString()
        note.modifiedAt = Date()
        notesManager.updateNote(note)
    }

    private func toggleStrikethrough() {
        guard let textView = textViewRef.textView,
              let textStorage = textView.textStorage else {
            print("TextView is nil in toggleStrikethrough")
            return
        }

        // Set formatting flag to prevent updateNSView from overwriting
        textViewRef.isFormatting = true
        defer { textViewRef.isFormatting = false }

        textView.window?.makeFirstResponder(textView)
        let selectedRange = textView.selectedRange()
        let rangeToFormat = selectedRange.length > 0 ? selectedRange : NSRange(location: 0, length: textView.string.count)

        textStorage.beginEditing()
        textStorage.enumerateAttribute(.strikethroughStyle, in: rangeToFormat) { value, range, _ in
            let currentStyle = value as? Int ?? 0
            let newStyle = currentStyle == 0 ? NSUnderlineStyle.single.rawValue : 0
            textStorage.addAttribute(.strikethroughStyle, value: newStyle, range: range)
        }
        textStorage.endEditing()

        // Update the note with formatted content
        note.attributedContent = textView.attributedString()
        note.modifiedAt = Date()
        notesManager.updateNote(note)
    }

    private func setFontSize(_ size: CGFloat) {
        guard let textView = textViewRef.textView,
              let textStorage = textView.textStorage else {
            print("TextView is nil in setFontSize")
            return
        }

        // Set formatting flag to prevent updateNSView from overwriting
        textViewRef.isFormatting = true
        defer { textViewRef.isFormatting = false }

        textView.window?.makeFirstResponder(textView)
        let selectedRange = textView.selectedRange()
        let rangeToFormat = selectedRange.length > 0 ? selectedRange : NSRange(location: 0, length: textView.string.count)

        textStorage.beginEditing()
        textStorage.enumerateAttribute(.font, in: rangeToFormat) { value, range, _ in
            let font = value as? NSFont ?? NSFont.systemFont(ofSize: 16)
            let newFont = NSFont(name: font.fontName, size: size) ?? NSFont.systemFont(ofSize: size)
            textStorage.addAttribute(.font, value: newFont, range: range)
        }
        textStorage.endEditing()

        // Also update typing attributes for new text
        textView.typingAttributes[.font] = NSFont.systemFont(ofSize: size)

        // Update the note with formatted content
        note.attributedContent = textView.attributedString()
        note.modifiedAt = Date()
        notesManager.updateNote(note)
    }

    private func setAlignment(_ alignment: NSTextAlignment) {
        guard let textView = textViewRef.textView else {
            print("TextView is nil in setAlignment")
            return
        }

        // Set formatting flag to prevent updateNSView from overwriting
        textViewRef.isFormatting = true
        defer { textViewRef.isFormatting = false }

        textView.window?.makeFirstResponder(textView)
        textView.alignment = alignment

        // Update the note with formatted content
        note.attributedContent = textView.attributedString()
        note.modifiedAt = Date()
        notesManager.updateNote(note)
    }

    // Additional actions
    private func exportAsText() {
        // TODO: Implement export functionality
        print("Export as text")
    }

    private func printNote() {
        // TODO: Implement print functionality
        print("Print note")
    }

    private func executeAICommand(_ operation: DeepseekAIService.AIOperation) {
        guard let textView = textViewRef.textView else {
            print("TextView is nil in executeAICommand")
            return
        }

        // Set formatting flag to prevent updateNSView from overwriting during AI processing
        textViewRef.isFormatting = true

        // Get selected text or all text
        let selectedRange = textView.selectedRange()
        let textToProcess: String
        let rangeToReplace: NSRange

        if selectedRange.length > 0 {
            textToProcess = (textView.string as NSString).substring(with: selectedRange)
            rangeToReplace = selectedRange
        } else {
            textToProcess = textView.string
            rangeToReplace = NSRange(location: 0, length: textView.string.count)
        }

        // Execute AI operation asynchronously
        Task { @MainActor in
            do {
                let result = try await aiService.processText(textToProcess, operation: operation)

                // Replace text with AI result
                if let textStorage = textView.textStorage {
                    textStorage.replaceCharacters(in: rangeToReplace, with: result)

                    // Update the note
                    note.attributedContent = textView.attributedString()
                    note.modifiedAt = Date()
                    notesManager.updateNote(note)
                }

                // Clear formatting flag after successful AI result
                textViewRef.isFormatting = false
            } catch {
                // Show error to user
                print("AI Error: \(error.localizedDescription)")

                // Clear formatting flag even on error
                textViewRef.isFormatting = false

                // TODO: Show error alert to user
            }
        }
    }

    private func duplicateNote() {
        // TODO: Implement duplicate functionality
        print("Duplicate note")
    }
}

struct NoteContentArea: View {
    @Binding var note: Note
    let textViewRef: TextViewReference
    @Environment(NotesManager.self) private var notesManager
    @Environment(\.colorScheme) private var colorScheme
    @State private var isEditorReady = false
    @State private var colorSchemeVersion = 0  // Track appearance changes

    var body: some View {
        RichTextEditorWithSlashMenu(
            attributedText: Binding(
                get: { note.attributedContent },
                set: { newValue in
                    note.attributedContent = newValue
                    note.modifiedAt = Date()
                    notesManager.updateNote(note)
                }
            ),
            textColor: note.color.textColor(for: colorScheme) == .white ? .white : .black,
            onTextChange: { newText in
                Task { @MainActor in
                    await Task.yield()
                    note.attributedContent = newText
                    note.modifiedAt = Date()
                    notesManager.updateNote(note)
                }
            },
            onTextViewCreated: { tv in
                // Direct assignment - no state modification warning
                textViewRef.textView = tv
            },
            textViewRef: textViewRef
        )
        .frame(minHeight: 200)
        .onAppear {
            // Give the textView a moment to initialize
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isEditorReady = true
            }
        }
        .onChange(of: colorScheme) { oldScheme, newScheme in
            // Force immediate text color update when appearance changes
            colorSchemeVersion += 1

            // Directly update text colors in the text view
            if let textView = textViewRef.textView,
               let textStorage = textView.textStorage {
                let targetColor = note.color.textColor(for: newScheme) == .white ? NSColor.white : NSColor.black
                let fullRange = NSRange(location: 0, length: textStorage.length)

                textStorage.beginEditing()
                textStorage.enumerateAttribute(.foregroundColor, in: fullRange) { value, range, _ in
                    if let existingColor = value as? NSColor {
                        // Check if this is a default text color
                        let isWhite = existingColor.isClose(to: .white)
                        let isBlack = existingColor.isClose(to: .black)
                        let isLabelColor = existingColor.isClose(to: .labelColor)

                        // Update if it's a default system text color
                        if isWhite || isBlack || isLabelColor {
                            textStorage.addAttribute(.foregroundColor, value: targetColor, range: range)
                        }
                    } else {
                        // No color set - apply the current text color
                        textStorage.addAttribute(.foregroundColor, value: targetColor, range: range)
                    }
                }
                textStorage.endEditing()

                // Also update typing attributes
                textView.typingAttributes[.foregroundColor] = targetColor

                // CRITICAL: Force immediate visual redisplay of the text view
                // Without this, the color changes won't appear until the next view update
                textView.setNeedsDisplay(textView.bounds)
            }
        }
    }
}

#Preview {
    NoteWindow(note: .constant(Note()))
        .environment(NotesManager())
        .frame(width: 400, height: 300)
}