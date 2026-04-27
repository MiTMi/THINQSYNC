//
//  NoteExporter.swift
//  thinqsync
//
//  Created by Claude on 02/04/2026.
//

import AppKit
import UniformTypeIdentifiers

/// Shared export logic used by both the individual NoteWindow and the ShowAllNotesView dashboard.
enum NoteExporter {

    // MARK: - Save Panel (single note, user picks filename)

    static func exportWithSavePanel(note: Note, format: String) {
        let panel = NSSavePanel()
        let sanitized = sanitizeTitle(note.title)
        panel.nameFieldStringValue = "\(sanitized).\(format)"
        panel.allowedContentTypes = [contentType(for: format)]
        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            write(note: note, format: format, to: url)
        }
    }

    // MARK: - Folder Export (bulk, writes directly into a directory)

    /// Writes a note file directly to a folder. Used for bulk export.
    static func export(note: Note, format: String, to folder: URL) {
        let sanitized = sanitizeTitle(note.title)
        let url = folder.appendingPathComponent("\(sanitized).\(format)")
        write(note: note, format: format, to: url)
    }

    // MARK: - Private

    private static func write(note: Note, format: String, to url: URL) {
        switch format {
        case "txt":
            try? note.content.write(to: url, atomically: true, encoding: .utf8)
        case "pdf":
            writePDF(note: note, to: url)
        case "md":
            writeMarkdown(note: note, to: url)
        default:
            break
        }
    }

    private static func writePDF(note: Note, to url: URL) {
        let contentWidth: CGFloat = 468 // US Letter minus margins
        let textView = NSTextView(frame: NSRect(x: 0, y: 0, width: contentWidth, height: 0))
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.textContainer?.containerSize = NSSize(width: contentWidth, height: .greatestFiniteMagnitude)
        textView.textContainer?.widthTracksTextView = true
        textView.textStorage?.setAttributedString(note.attributedContent)

        textView.layoutManager?.ensureLayout(for: textView.textContainer!)
        let fullHeight = textView.layoutManager?.usedRect(for: textView.textContainer!).height ?? 100
        textView.frame = NSRect(x: 0, y: 0, width: contentWidth, height: fullHeight)

        let printInfo = NSPrintInfo()
        printInfo.paperSize = NSSize(width: 612, height: 792)
        printInfo.topMargin = 72
        printInfo.bottomMargin = 72
        printInfo.leftMargin = 72
        printInfo.rightMargin = 72
        printInfo.horizontalPagination = .fit
        printInfo.verticalPagination = .automatic
        printInfo.jobDisposition = .save
        printInfo.dictionary()[NSPrintInfo.AttributeKey.jobSavingURL] = url

        let printOp = NSPrintOperation(view: textView, printInfo: printInfo)
        printOp.showsPrintPanel = false
        printOp.showsProgressPanel = false
        printOp.run()
    }

    private static func writeMarkdown(note: Note, to url: URL) {
        let attrStr = note.attributedContent
        var markdown = ""

        if !note.title.isEmpty {
            markdown += "# \(note.title)\n\n"
        }

        attrStr.enumerateAttributes(in: NSRange(location: 0, length: attrStr.length)) { attrs, range, _ in
            var text = (attrStr.string as NSString).substring(with: range)

            if let font = attrs[.font] as? NSFont {
                let isBold = font.fontDescriptor.symbolicTraits.contains(.bold)
                let isItalic = font.fontDescriptor.symbolicTraits.contains(.italic)
                let size = font.pointSize

                if isBold && size >= 24 {
                    text = "## \(text)"
                } else if isBold && size >= 20 {
                    text = "### \(text)"
                } else {
                    if isBold { text = "**\(text)**" }
                    if isItalic { text = "*\(text)*" }
                }
            }

            if let strikethrough = attrs[.strikethroughStyle] as? Int, strikethrough != 0 {
                text = "~~\(text)~~"
            }

            markdown += text
        }

        try? markdown.write(to: url, atomically: true, encoding: .utf8)
    }

    private static func sanitizeTitle(_ title: String) -> String {
        let name = title.isEmpty ? "Untitled" : title
        return name.replacingOccurrences(of: "/", with: "-")
                   .replacingOccurrences(of: ":", with: "-")
                   .replacingOccurrences(of: "\\", with: "-")
    }

    private static func contentType(for format: String) -> UTType {
        switch format {
        case "pdf": return .pdf
        case "md": return UTType(filenameExtension: "md") ?? .plainText
        default: return .plainText
        }
    }
}
