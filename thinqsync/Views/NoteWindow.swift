//
//  NoteWindow.swift
//  thinqsync
//
//  Created by Michael   on 31/10/2025.
//

import SwiftUI
import Combine

struct NoteWindow: View {
    @Binding var note: Note
    @Environment(NotesManager.self) private var notesManager
    @Environment(\.dismiss) private var dismiss
    @State private var showingColorPicker = false
    @State private var textView: NSTextView?
    @State private var windowConfigured = false

    var body: some View {
        VStack(spacing: 0) {
            // Custom title bar that matches the screenshot
            CustomTitleBar(
                note: $note,
                textView: $textView,  // Pass as binding so it updates
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

            // Main content area with text
            NoteContentArea(note: $note, textView: $textView)
                .background(note.color.backgroundColor)
        }
        .background(note.color.backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(note.color.backgroundColor.opacity(0.3), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.3), radius: 15, x: 0, y: 8)
        .background(WindowAccessor(onWindowReady: { window in
            configureWindow(window)
        }))
    }

    private func configureWindow(_ window: NSWindow) {
        // Only configure once to avoid repeated modifications
        guard !windowConfigured else { return }
        windowConfigured = true

        // Set window to float
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        // Remove standard window buttons
        window.standardWindowButton(.closeButton)?.isHidden = true
        window.standardWindowButton(.miniaturizeButton)?.isHidden = true
        window.standardWindowButton(.zoomButton)?.isHidden = true

        // Configure window appearance
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.isMovableByWindowBackground = true
        window.backgroundColor = .clear
        window.isOpaque = false
        window.hasShadow = false  // We add our own shadow in SwiftUI
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
    @Binding var textView: NSTextView?  // Changed to Binding
    var onClose: () -> Void
    var onMinimize: () -> Void
    var onDelete: () -> Void

    @State private var isHoveringClose = false
    @State private var isHoveringMinimize = false

    var body: some View {
        HStack(spacing: 0) {
            // Left side: Close and Minimize buttons
            HStack(spacing: 8) {
                // Close button (X)
                Button(action: onClose) {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.15))
                            .frame(width: 28, height: 28)

                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
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
                            .fill(Color.white.opacity(0.15))
                            .frame(width: 28, height: 28)

                        Image(systemName: "chevron.down")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
                    }
                }
                .buttonStyle(.plain)
                .onHover { hovering in
                    isHoveringMinimize = hovering
                }
            }
            .padding(.leading, 12)

            Spacer()

            // Center: Title
            TextField("", text: $note.title, prompt: Text("New Note").foregroundColor(.white.opacity(0.5)))
                .textFieldStyle(.plain)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 200)

            Spacer()

            // Right side: Menu buttons
            HStack(spacing: 8) {
                // Hamburger menu
                Menu {
                    Button(action: {
                        note.isFavorite.toggle()
                    }) {
                        Label(
                            note.isFavorite ? "Remove from Favorites" : "Add to Favorites",
                            systemImage: note.isFavorite ? "star.fill" : "star"
                        )
                    }

                    Divider()

                    // Color menu
                    Menu("Change Color") {
                        ForEach(NoteColor.allCases, id: \.self) { color in
                            Button(action: {
                                note.color = color
                            }) {
                                HStack {
                                    Circle()
                                        .fill(color.backgroundColor)
                                        .frame(width: 12, height: 12)
                                    Text(color.rawValue.capitalized)
                                }
                            }
                        }
                    }

                    Divider()

                    Button("Delete Note", role: .destructive) {
                        onDelete()
                    }
                } label: {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.15))
                            .frame(width: 28, height: 28)

                        Image(systemName: "line.3.horizontal")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
                    }
                }
                .menuStyle(.borderlessButton)

                // Text formatting button (A)
                Menu {
                    Button(action: { toggleBold() }) {
                        Label("Bold", systemImage: "bold")
                    }
                    .keyboardShortcut("b", modifiers: .command)

                    Button(action: { toggleItalic() }) {
                        Label("Italic", systemImage: "italic")
                    }
                    .keyboardShortcut("i", modifiers: .command)

                    Button(action: { toggleUnderline() }) {
                        Label("Underline", systemImage: "underline")
                    }
                    .keyboardShortcut("u", modifiers: .command)

                    Divider()

                    Menu("Font Size") {
                        ForEach([10, 12, 14, 16, 18, 20, 24], id: \.self) { size in
                            Button("\(size) pt") {
                                setFontSize(CGFloat(size))
                            }
                        }
                    }

                    Divider()

                    Menu("Alignment") {
                        Button(action: { setAlignment(.left) }) {
                            Label("Left", systemImage: "text.alignleft")
                        }
                        Button(action: { setAlignment(.center) }) {
                            Label("Center", systemImage: "text.aligncenter")
                        }
                        Button(action: { setAlignment(.right) }) {
                            Label("Right", systemImage: "text.alignright")
                        }
                    }
                } label: {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.15))
                            .frame(width: 28, height: 28)

                        Text("A")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white.opacity(0.9))
                    }
                }
                .menuStyle(.borderlessButton)

                // More options (three dots)
                Menu {
                    Button(action: {
                        // Export functionality
                        exportAsText()
                    }) {
                        Label("Export as Text", systemImage: "square.and.arrow.up")
                    }

                    Button(action: {
                        // Print functionality
                        printNote()
                    }) {
                        Label("Print", systemImage: "printer")
                    }

                    Divider()

                    Button(action: {
                        // Duplicate note
                        duplicateNote()
                    }) {
                        Label("Duplicate", systemImage: "doc.on.doc")
                    }
                } label: {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.15))
                            .frame(width: 28, height: 28)

                        Image(systemName: "ellipsis")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
                    }
                }
                .menuStyle(.borderlessButton)
            }
            .padding(.trailing, 12)
        }
        .frame(height: 44)
        .background(note.color.backgroundColor)
    }

    // Text formatting functions
    private func toggleBold() {
        guard let textView = textView,
              let textStorage = textView.textStorage else {
            print("TextVie is nil in toggleBold")
            return
        }

        textView.window?.makeFirstResponder(textView)
        let selectedRange = textView.selectedRange()

        // If no text is selected, select all
        let rangeToFormat = selectedRange.length > 0 ? selectedRange : NSRange(location: 0, length: textView.string.count)

        textStorage.beginEditing()
        textStorage.enumerateAttribute(.font, in: rangeToFormat) { value, range, _ in
            if let font = value as? NSFont {
                let isBold = font.fontDescriptor.symbolicTraits.contains(.bold)
                let newFont = isBold ?
                    NSFontManager.shared.convert(font, toNotHaveTrait: .boldFontMask) :
                    NSFontManager.shared.convert(font, toHaveTrait: .boldFontMask)
                textStorage.addAttribute(.font, value: newFont, range: range)
            }
        }
        textStorage.endEditing()
    }

    private func toggleItalic() {
        guard let textView = textView,
              let textStorage = textView.textStorage else {
            print("TextView is nil in toggleItalic")
            return
        }

        textView.window?.makeFirstResponder(textView)
        let selectedRange = textView.selectedRange()
        let rangeToFormat = selectedRange.length > 0 ? selectedRange : NSRange(location: 0, length: textView.string.count)

        textStorage.beginEditing()
        textStorage.enumerateAttribute(.font, in: rangeToFormat) { value, range, _ in
            if let font = value as? NSFont {
                let isItalic = font.fontDescriptor.symbolicTraits.contains(.italic)
                let newFont = isItalic ?
                    NSFontManager.shared.convert(font, toNotHaveTrait: .italicFontMask) :
                    NSFontManager.shared.convert(font, toHaveTrait: .italicFontMask)
                textStorage.addAttribute(.font, value: newFont, range: range)
            }
        }
        textStorage.endEditing()
    }

    private func toggleUnderline() {
        guard let textView = textView,
              let textStorage = textView.textStorage else {
            print("TextView is nil in toggleUnderline")
            return
        }

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
    }

    private func setFontSize(_ size: CGFloat) {
        guard let textView = textView,
              let textStorage = textView.textStorage else {
            print("TextView is nil in setFontSize")
            return
        }

        textView.window?.makeFirstResponder(textView)
        let selectedRange = textView.selectedRange()
        let rangeToFormat = selectedRange.length > 0 ? selectedRange : NSRange(location: 0, length: textView.string.count)

        textStorage.beginEditing()
        textStorage.enumerateAttribute(.font, in: rangeToFormat) { value, range, _ in
            if let font = value as? NSFont {
                let newFont = NSFont(name: font.fontName, size: size) ?? NSFont.systemFont(ofSize: size)
                textStorage.addAttribute(.font, value: newFont, range: range)
            }
        }
        textStorage.endEditing()
    }

    private func setAlignment(_ alignment: NSTextAlignment) {
        guard let textView = textView else {
            print("TextView is nil in setAlignment")
            return
        }
        textView.window?.makeFirstResponder(textView)
        textView.alignment = alignment
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

    private func duplicateNote() {
        // TODO: Implement duplicate functionality
        print("Duplicate note")
    }
}

struct NoteContentArea: View {
    @Binding var note: Note
    @Binding var textView: NSTextView?
    @Environment(NotesManager.self) private var notesManager

    var body: some View {
        RichTextEditor(
            attributedText: Binding(
                get: { note.attributedContent },
                set: { newValue in
                    note.attributedContent = newValue
                    note.modifiedAt = Date()
                    notesManager.updateNote(note)
                }
            ),
            textColor: note.color.textColor,
            onTextChange: { newText in
                note.attributedContent = newText
                note.modifiedAt = Date()
                notesManager.updateNote(note)
            },
            onTextViewCreated: { createdTextView in
                // Store the textView reference
                DispatchQueue.main.async {
                    textView = createdTextView
                    // Customize text view appearance
                    createdTextView.font = .systemFont(ofSize: 16)
                    createdTextView.textColor = .white  // Always white
                    createdTextView.textContainerInset = NSSize(width: 20, height: 20)
                }
            }
        )
        .frame(minHeight: 200)
    }
}

#Preview {
    NoteWindow(note: .constant(Note()))
        .environment(NotesManager())
        .frame(width: 400, height: 300)
}