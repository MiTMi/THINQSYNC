//
//  RichTextEditor.swift
//  thinqsync
//
//  Created by Michael   on 31/10/2025.
//

import SwiftUI
import AppKit
import os

private let logger = Logger(subsystem: "com.MIT.thinqsync", category: "RichTextEditor")

// MARK: - Resizable Image Attachment Cell

class ResizableImageAttachmentCell: NSTextAttachmentCell {
    private var originalImage: NSImage?
    var displaySize: NSSize?

    // Minimum size for the image
    private let minSize: CGFloat = 50

    override init(imageCell image: NSImage?) {
        super.init(imageCell: image)
        self.originalImage = image
        if let img = image {
            self.displaySize = img.size
        }
    }

    required init(coder: NSCoder) {
        super.init(coder: coder)
    }

    func setDisplaySize(_ size: NSSize) {
        self.displaySize = size
    }

    func getDisplaySize() -> NSSize? {
        return displaySize
    }

    override var cellSize: NSSize {
        return displaySize ?? super.cellSize
    }

    override func draw(withFrame cellFrame: NSRect, in controlView: NSView?) {
        guard let image = self.image else {
            super.draw(withFrame: cellFrame, in: controlView)
            return
        }

        // Draw the image scaled to fit the cell frame
        image.draw(in: cellFrame, from: NSRect(origin: .zero, size: image.size), operation: .sourceOver, fraction: 1.0)

        // Draw resize handle in bottom-right corner
        let handleSize: CGFloat = 12
        let handleRect = NSRect(
            x: cellFrame.maxX - handleSize - 2,
            y: cellFrame.minY + 2,
            width: handleSize,
            height: handleSize
        )

        // Draw a subtle resize indicator
        NSColor.gray.withAlphaComponent(0.6).setFill()
        let path = NSBezierPath()
        path.move(to: NSPoint(x: handleRect.maxX, y: handleRect.minY))
        path.line(to: NSPoint(x: handleRect.maxX, y: handleRect.maxY))
        path.line(to: NSPoint(x: handleRect.minX, y: handleRect.maxY))
        path.close()
        path.fill()
    }

    func isInResizeHandle(point: NSPoint, cellFrame: NSRect) -> Bool {
        let handleSize: CGFloat = 16
        let handleRect = NSRect(
            x: cellFrame.maxX - handleSize,
            y: cellFrame.minY,
            width: handleSize,
            height: handleSize
        )
        return handleRect.contains(point)
    }

    func resize(to newSize: NSSize) {
        let constrainedSize = NSSize(
            width: max(minSize, newSize.width),
            height: max(minSize, newSize.height)
        )
        self.displaySize = constrainedSize
    }
}

// MARK: - Default Paragraph Style

/// Shared paragraph style used for default line spacing across all text in notes.
let defaultParagraphStyle: NSMutableParagraphStyle = {
    let style = NSMutableParagraphStyle()
    style.lineSpacing = 4
    return style
}()

// MARK: - Custom NSTextView with Image Paste and Resize Support

class PlainPasteTextView: NSTextView {

    /// Closure called on keyDown when the slash menu is visible.
    /// Return `true` if the key was handled (consumed), `false` to let NSTextView process it.
    var slashMenuKeyHandler: ((NSEvent) -> Bool)?

    override func keyDown(with event: NSEvent) {
        if let handler = slashMenuKeyHandler, handler(event) {
            return  // Key was consumed by slash menu
        }
        super.keyDown(with: event)
    }

    // Image resize tracking
    private var isResizingImage = false
    private var resizingAttachmentRange: NSRange?
    private var resizingCell: ResizableImageAttachmentCell?
    private var resizeStartPoint: NSPoint?
    private var resizeStartSize: NSSize?

    // Maximum dimensions for pasted images to avoid disrupting note layout
    private let maxImageWidth: CGFloat = 280
    private let maxImageHeight: CGFloat = 200

    // MARK: - Enable Paste for Image Content

    // Tell NSTextView that we can read image types from the pasteboard
    override var readablePasteboardTypes: [NSPasteboard.PasteboardType] {
        var types = super.readablePasteboardTypes
        let imageTypes: [NSPasteboard.PasteboardType] = [
            .tiff, .png,
            NSPasteboard.PasteboardType("public.jpeg"),
            NSPasteboard.PasteboardType("public.heic"),
            NSPasteboard.PasteboardType("public.image"),
            .fileURL
        ]
        for type in imageTypes {
            if !types.contains(type) {
                types.append(type)
            }
        }
        return types
    }

    // Ensure the "Paste" menu item is enabled when images are on the clipboard
    override func validateUserInterfaceItem(_ item: NSValidatedUserInterfaceItem) -> Bool {
        if item.action == #selector(paste(_:)) {
            let pasteboard = NSPasteboard.general
            // Allow paste if pasteboard has any image-related types
            let hasImage = pasteboard.canReadItem(withDataConformingToTypes: [
                NSPasteboard.PasteboardType.tiff.rawValue,
                NSPasteboard.PasteboardType.png.rawValue,
                "public.jpeg", "public.heic", "public.image",
                NSPasteboard.PasteboardType.fileURL.rawValue,
                NSPasteboard.PasteboardType.string.rawValue
            ])
            if hasImage {
                return true
            }
        }
        return super.validateUserInterfaceItem(item)
    }

    override func paste(_ sender: Any?) {
        let pasteboard = NSPasteboard.general

        // First, check if there's an image on the pasteboard
        if let image = getImageFromPasteboard(pasteboard) {
            pasteImage(image)
            return
        }

        // Otherwise, handle text paste with formatting stripped
        guard let plainText = pasteboard.string(forType: .string) else {
            super.paste(sender)
            return
        }

        // Create attributed string with default formatting
        let defaultFont = NSFont.systemFont(ofSize: 18)
        let defaultColor = self.textColor ?? NSColor.labelColor

        let attributes: [NSAttributedString.Key: Any] = [
            .font: defaultFont,
            .foregroundColor: defaultColor
        ]

        let attributedString = NSAttributedString(string: plainText, attributes: attributes)

        // Insert the plain text with default formatting
        if let textStorage = self.textStorage {
            let selectedRange = self.selectedRange()
            textStorage.beginEditing()
            textStorage.replaceCharacters(in: selectedRange, with: attributedString)
            textStorage.endEditing()

            // Move cursor to end of inserted text
            let newPosition = selectedRange.location + plainText.count
            self.setSelectedRange(NSRange(location: newPosition, length: 0))

            // CRITICAL: Notify delegate that text changed so binding gets updated
            self.delegate?.textDidChange?(Notification(name: NSText.didChangeNotification, object: self))
        }
    }

    // MARK: - Image Handling

    private func getImageFromPasteboard(_ pasteboard: NSPasteboard) -> NSImage? {
        // 1. NSImage native pasteboard init
        if NSImage.canInit(with: pasteboard), let image = NSImage(pasteboard: pasteboard) {
            return image
        }

        // 2. Raw data types
        let imageTypes: [NSPasteboard.PasteboardType] = [
            .png, .tiff, NSPasteboard.PasteboardType("public.jpeg"), NSPasteboard.PasteboardType("public.heic")
        ]
        for type in imageTypes {
            if let data = pasteboard.data(forType: type), let image = NSImage(data: data) {
                return image
            }
        }

        // 3. File URLs
        if let urls = pasteboard.readObjects(forClasses: [NSURL.self], options: [.urlReadingFileURLsOnly: true]) as? [URL] {
            for url in urls {
                if let data = try? Data(contentsOf: url), let image = NSImage(data: data) {
                    return image
                }
            }
        }

        // 4. Try readObjects with NSImage class
        if let images = pasteboard.readObjects(forClasses: [NSImage.self], options: nil) as? [NSImage], let image = images.first {
            return image
        }

        return nil
    }

    private func pasteImage(_ image: NSImage) {
        // Resize image to fit within constraints
        let resizedImage = resizeImageToFit(image)

        // Compress the image to PNG (better for RTFD serialization)
        guard let imageData = compressImageToPNG(resizedImage) else {
            logger.error("Failed to compress image")
            return
        }

        // Create final image from compressed data
        guard let finalImage = NSImage(data: imageData) else {
            logger.error("Failed to create image from compressed data")
            return
        }

        // Create text attachment with embedded data for persistence
        let attachment = NSTextAttachment()
        attachment.contents = imageData
        attachment.fileType = "public.png"

        // Create a file wrapper for the attachment data
        let fileWrapper = FileWrapper(regularFileWithContents: imageData)
        fileWrapper.preferredFilename = "image.png"
        attachment.fileWrapper = fileWrapper

        // Use our resizable cell for display
        let cell = ResizableImageAttachmentCell(imageCell: finalImage)
        cell.setDisplaySize(resizedImage.size)
        attachment.attachmentCell = cell

        // Create attributed string with attachment
        let attachmentString = NSAttributedString(attachment: attachment)

        // Insert the image at cursor position
        if let textStorage = self.textStorage {
            let selectedRange = self.selectedRange()
            textStorage.beginEditing()
            textStorage.replaceCharacters(in: selectedRange, with: attachmentString)
            textStorage.endEditing()

            // Move cursor to after the image
            let newPosition = selectedRange.location + 1
            self.setSelectedRange(NSRange(location: newPosition, length: 0))

            // Notify delegate that content changed
            self.delegate?.textDidChange?(Notification(name: NSText.didChangeNotification, object: self))
        }
    }

    private func resizeImageToFit(_ image: NSImage) -> NSImage {
        let originalSize = image.size

        // Check if resizing is needed
        if originalSize.width <= maxImageWidth && originalSize.height <= maxImageHeight {
            return image
        }

        // Calculate scale factor to fit within constraints
        let widthRatio = maxImageWidth / originalSize.width
        let heightRatio = maxImageHeight / originalSize.height
        let scaleFactor = min(widthRatio, heightRatio)

        let newSize = NSSize(
            width: originalSize.width * scaleFactor,
            height: originalSize.height * scaleFactor
        )

        // Create resized image using proper drawing method
        let resizedImage = NSImage(size: newSize)
        resizedImage.lockFocus()

        // Flip the coordinate system to prevent upside-down images
        let transform = NSAffineTransform()
        transform.translateX(by: 0, yBy: newSize.height)
        transform.scaleX(by: 1.0, yBy: -1.0)
        transform.concat()

        // Draw with flipped context
        if let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) {
            let context = NSGraphicsContext.current?.cgContext
            context?.interpolationQuality = .high
            context?.draw(cgImage, in: CGRect(origin: .zero, size: newSize))
        }

        resizedImage.unlockFocus()
        return resizedImage
    }

    private func compressImageToPNG(_ image: NSImage) -> Data? {
        // Get bitmap representation
        guard let tiffData = image.tiffRepresentation,
              let bitmapRep = NSBitmapImageRep(data: tiffData) else {
            return nil
        }

        // Use PNG for better compatibility with RTFD serialization
        return bitmapRep.representation(using: .png, properties: [:])
    }

    // MARK: - Mouse Events for Image Resizing

    override func mouseDown(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)

        // Check if clicking on an image attachment's resize handle
        if let (attachmentRange, cell, cellFrame) = findAttachmentAt(point: point) {
            if cell.isInResizeHandle(point: point, cellFrame: cellFrame) {
                isResizingImage = true
                resizingAttachmentRange = attachmentRange
                resizingCell = cell
                resizeStartPoint = point
                resizeStartSize = cell.getDisplaySize() ?? cell.cellSize()
                return
            }
        }

        super.mouseDown(with: event)
    }

    override func mouseDragged(with event: NSEvent) {
        if isResizingImage, let startPoint = resizeStartPoint, let startSize = resizeStartSize, let cell = resizingCell {
            let currentPoint = convert(event.locationInWindow, from: nil)
            let deltaX = currentPoint.x - startPoint.x
            let deltaY = startPoint.y - currentPoint.y  // Inverted because y increases downward

            // Maintain aspect ratio
            let aspectRatio = startSize.width / startSize.height
            let delta = max(deltaX, deltaY)

            let newWidth = startSize.width + delta
            let newHeight = newWidth / aspectRatio

            cell.resize(to: NSSize(width: newWidth, height: newHeight))

            // Force redraw
            needsDisplay = true
            layoutManager?.invalidateLayout(forCharacterRange: resizingAttachmentRange!, actualCharacterRange: nil)

            return
        }

        super.mouseDragged(with: event)
    }

    override func mouseUp(with event: NSEvent) {
        if isResizingImage, let range = resizingAttachmentRange, let cell = resizingCell {
            // Update the attachment with resized image data for persistence
            if let displaySize = cell.getDisplaySize(), let textStorage = self.textStorage {
                if let attachment = textStorage.attribute(.attachment, at: range.location, effectiveRange: nil) as? NSTextAttachment,
                   let originalImage = cell.image {
                    // Create a resized version of the image
                    let resizedImage = createResizedImage(originalImage, to: displaySize)

                    // Convert to PNG data
                    if let tiffData = resizedImage.tiffRepresentation,
                       let bitmapRep = NSBitmapImageRep(data: tiffData),
                       let pngData = bitmapRep.representation(using: .png, properties: [:]) {
                        // Update attachment with new image data
                        attachment.contents = pngData
                        attachment.fileType = "public.png"

                        // Create a new file wrapper with the resized image data
                        let fileWrapper = FileWrapper(regularFileWithContents: pngData)
                        fileWrapper.preferredFilename = "image.png"
                        attachment.fileWrapper = fileWrapper

                        // Update the cell with the resized image
                        let newCell = ResizableImageAttachmentCell(imageCell: resizedImage)
                        newCell.setDisplaySize(displaySize)
                        attachment.attachmentCell = newCell

                        // Update our reference
                        resizingCell = newCell

                        logger.debug("Resized image saved: \(displaySize.width)x\(displaySize.height), data: \(pngData.count) bytes")
                    }
                }
            }

            // Notify delegate that content changed so it gets saved
            self.delegate?.textDidChange?(Notification(name: NSText.didChangeNotification, object: self))

            isResizingImage = false
            resizingAttachmentRange = nil
            resizingCell = nil
            resizeStartPoint = nil
            resizeStartSize = nil
            return
        }

        super.mouseUp(with: event)
    }

    private func createResizedImage(_ image: NSImage, to size: NSSize) -> NSImage {
        let resizedImage = NSImage(size: size)
        resizedImage.lockFocus()
        NSGraphicsContext.current?.imageInterpolation = .high
        image.draw(in: NSRect(origin: .zero, size: size),
                   from: NSRect(origin: .zero, size: image.size),
                   operation: .copy,
                   fraction: 1.0)
        resizedImage.unlockFocus()
        return resizedImage
    }

    override func resetCursorRects() {
        super.resetCursorRects()

        // Add resize cursor for image resize handles
        guard let textStorage = textStorage else { return }

        textStorage.enumerateAttribute(.attachment, in: NSRange(location: 0, length: textStorage.length)) { value, range, _ in
            if let attachment = value as? NSTextAttachment,
               let _ = attachment.attachmentCell as? ResizableImageAttachmentCell,
               let lm = self.layoutManager,
               let tc = self.textContainer {
                let rect = lm.boundingRect(forGlyphRange: range, in: tc)
                let handleSize: CGFloat = 16
                let handleRect = NSRect(
                    x: rect.maxX - handleSize + self.textContainerInset.width,
                    y: rect.minY + self.textContainerInset.height,
                    width: handleSize,
                    height: handleSize
                )
                self.addCursorRect(handleRect, cursor: .crosshair)
            }
        }
    }

    private func findAttachmentAt(point: NSPoint) -> (NSRange, ResizableImageAttachmentCell, NSRect)? {
        guard let textStorage = textStorage, let layoutManager = layoutManager, let textContainer = textContainer else {
            return nil
        }

        // Adjust point for text container inset
        let adjustedPoint = NSPoint(
            x: point.x - textContainerInset.width,
            y: point.y - textContainerInset.height
        )

        // Find character at point
        let charIndex = layoutManager.characterIndex(for: adjustedPoint, in: textContainer, fractionOfDistanceBetweenInsertionPoints: nil)

        if charIndex < textStorage.length {
            // Check if there's an attachment at this character
            if let attachment = textStorage.attribute(.attachment, at: charIndex, effectiveRange: nil) as? NSTextAttachment,
               let cell = attachment.attachmentCell as? ResizableImageAttachmentCell {
                let range = NSRange(location: charIndex, length: 1)
                let rect = layoutManager.boundingRect(forGlyphRange: range, in: textContainer)
                let adjustedRect = NSRect(
                    x: rect.origin.x + textContainerInset.width,
                    y: rect.origin.y + textContainerInset.height,
                    width: rect.width,
                    height: rect.height
                )
                return (range, cell, adjustedRect)
            }
        }

        return nil
    }
}

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
        // Create scroll view manually with our custom text view
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder
        scrollView.backgroundColor = .clear
        scrollView.drawsBackground = false

        // Create text container and layout manager
        let textContainer = NSTextContainer()
        textContainer.widthTracksTextView = true
        textContainer.heightTracksTextView = false
        textContainer.containerSize = NSSize(width: 0, height: CGFloat.greatestFiniteMagnitude)

        let layoutManager = NSLayoutManager()
        layoutManager.addTextContainer(textContainer)

        // Create text storage with initial attributed text
        let textStorage = NSTextStorage(attributedString: attributedText)
        textStorage.addLayoutManager(layoutManager)

        // Upgrade any existing image attachments to use our resizable cell
        upgradeAttachmentsToResizable(in: textStorage)

        // Create our custom text view that strips formatting on paste
        let textView = PlainPasteTextView(frame: .zero, textContainer: textContainer)

        // Configure the text view
        textView.delegate = context.coordinator
        textView.isRichText = true
        textView.importsGraphics = true  // CRITICAL: Allow paste when only image data is on clipboard (screenshots)
        textView.allowsUndo = true
        textView.font = .systemFont(ofSize: 16)
        textView.textColor = NSColor(textColor)
        textView.backgroundColor = .clear
        textView.drawsBackground = false
        textView.textContainerInset = NSSize(width: 16, height: 14)
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]

        // Critical: Set max and min sizes to prevent text from disappearing
        textView.minSize = NSSize(width: 0, height: 0)
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)

        // Set the text view as the document view
        scrollView.documentView = textView

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
            .font: NSFont.systemFont(ofSize: 18),
            .foregroundColor: NSColor(textColor),
            .paragraphStyle: defaultParagraphStyle
        ]

        // Apply default line spacing to existing text
        if let textStorage = textView.textStorage, textStorage.length > 0 {
            textStorage.addAttribute(.paragraphStyle, value: defaultParagraphStyle, range: NSRange(location: 0, length: textStorage.length))
        }

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

        // IMPORTANT: Don't reset text storage if window is key (user is actively using it)
        // This prevents pasted text from being erased during window resize
        if let window = textView.window, window.isKeyWindow {
            // Window is active - skip text storage updates to preserve user edits
            return
        }

        // Only update if the text is different to avoid cursor jumping
        if textView.attributedString() != attributedText {
            let selectedRange = textView.selectedRange()
            textView.textStorage?.setAttributedString(attributedText)

            // Upgrade any image attachments to use our resizable cell
            if let textStorage = textView.textStorage {
                upgradeAttachmentsToResizable(in: textStorage)
            }

            if selectedRange.location <= textView.string.count {
                textView.setSelectedRange(selectedRange)
            }
        }

        // Color correction for dark/light mode is handled by NoteContentArea.onChange(of: colorScheme)
        // which runs only when appearance actually changes, instead of on every view update.
    }

    // Upgrade existing attachments to use ResizableImageAttachmentCell
    private func upgradeAttachmentsToResizable(in textStorage: NSTextStorage) {
        let fullRange = NSRange(location: 0, length: textStorage.length)

        textStorage.beginEditing()
        textStorage.enumerateAttribute(.attachment, in: fullRange, options: []) { value, range, _ in
            guard let attachment = value as? NSTextAttachment else { return }

            // Skip if already using our resizable cell
            if attachment.attachmentCell is ResizableImageAttachmentCell {
                return
            }

            // Try to get image from the attachment
            var image: NSImage?

            // First try to get from existing cell
            if let cell = attachment.attachmentCell as? NSTextAttachmentCell,
               let cellImage = cell.image {
                image = cellImage
            }
            // Then try from contents/fileWrapper
            else if let contents = attachment.contents,
                    let dataImage = NSImage(data: contents) {
                image = dataImage
            }
            else if let fileWrapper = attachment.fileWrapper,
                    let data = fileWrapper.regularFileContents,
                    let wrapperImage = NSImage(data: data) {
                image = wrapperImage
            }

            // If we found an image, upgrade to resizable cell
            if let img = image {
                let resizableCell = ResizableImageAttachmentCell(imageCell: img)

                // Check if there's a stored display size in attachment bounds
                let bounds = attachment.bounds
                if bounds.size.width > 0 && bounds.size.height > 0 {
                    // Use the stored bounds size
                    resizableCell.setDisplaySize(bounds.size)
                } else {
                    // No stored size, use image's natural size
                    resizableCell.setDisplaySize(img.size)
                }

                attachment.attachmentCell = resizableCell
            }
        }
        textStorage.endEditing()
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
                            .font: NSFont.systemFont(ofSize: 18),
                            .foregroundColor: NSColor(parent.textColor),
                            .paragraphStyle: defaultParagraphStyle
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

                        // Get cursor position for menu placement, accounting for scroll offset
                        let menuPosition: CGPoint
                        if let rect = textView.layoutManager?.boundingRect(
                            forGlyphRange: NSRange(location: slashLocation, length: 1),
                            in: textView.textContainer!
                        ) {
                            // rect is in text container coordinates.
                            // Subtract the scroll view's visible rect origin to convert
                            // to viewport-relative coordinates.
                            let scrollOffset = textView.enclosingScrollView?.documentVisibleRect.origin ?? .zero
                            let inset = textView.textContainerInset
                            menuPosition = CGPoint(
                                x: rect.origin.x + inset.width,
                                y: rect.origin.y + rect.height + inset.height - scrollOffset.y
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

        // Detect RTL characters and auto-adjust text alignment.
        // Only checks a small window around the cursor instead of the full text.
        private var lastDetectedRTL: Bool?

        private func detectAndAdjustTextDirection(in textView: NSTextView) {
            let text = textView.string
            guard !text.isEmpty else { return }

            // Only scan around the cursor (up to 200 chars) instead of the entire text
            let cursorPos = textView.selectedRange().location
            let scanStart = max(0, cursorPos - 100)
            let scanEnd = min(text.count, cursorPos + 100)
            let startIdx = text.index(text.startIndex, offsetBy: scanStart)
            let endIdx = text.index(text.startIndex, offsetBy: scanEnd)
            let window = text[startIdx..<endIdx]

            let hasRTLCharacters = window.unicodeScalars.contains { scalar in
                let v = scalar.value
                return (v >= 0x0590 && v <= 0x05FF) ||
                       (v >= 0x0600 && v <= 0x06FF) ||
                       (v >= 0xFB1D && v <= 0xFB4F) ||
                       (v >= 0xFB50 && v <= 0xFDFF) ||
                       (v >= 0xFE70 && v <= 0xFEFF)
            }

            // Skip if direction hasn't changed
            if hasRTLCharacters == lastDetectedRTL { return }
            lastDetectedRTL = hasRTLCharacters

            let currentParagraphStyle = textView.defaultParagraphStyle ?? NSParagraphStyle.default
            let mutableParagraphStyle = currentParagraphStyle.mutableCopy() as! NSMutableParagraphStyle

            if hasRTLCharacters {
                mutableParagraphStyle.alignment = .right
                mutableParagraphStyle.baseWritingDirection = .rightToLeft
                textView.defaultParagraphStyle = mutableParagraphStyle
                textView.alignment = .right

                if let textStorage = textView.textStorage {
                    let fullRange = NSRange(location: 0, length: textStorage.length)
                    textStorage.addAttribute(.paragraphStyle, value: mutableParagraphStyle, range: fullRange)
                }
            } else {
                mutableParagraphStyle.alignment = .left
                mutableParagraphStyle.baseWritingDirection = .leftToRight
                textView.defaultParagraphStyle = mutableParagraphStyle
                textView.alignment = .left

                if let textStorage = textView.textStorage {
                    let fullRange = NSRange(location: 0, length: textStorage.length)
                    textStorage.addAttribute(.paragraphStyle, value: mutableParagraphStyle, range: fullRange)
                }
            }
        }
    }
}

// Extension to create attributed string with default attributes
extension NSAttributedString {
    convenience init(string: String, color: NSColor) {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 18),
            .foregroundColor: color,
            .paragraphStyle: defaultParagraphStyle
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
