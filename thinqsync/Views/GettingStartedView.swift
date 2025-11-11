//
//  GettingStartedView.swift
//  thinqsync
//
//  Created by Michael   on 31/10/2025.
//

import SwiftUI
import AppKit

// Helper to create colored square images for menu items
func createColoredSquareImage(color: NSColor, size: CGSize) -> NSImage {
    let image = NSImage(size: size)
    image.lockFocus()

    color.setFill()
    let rect = NSRect(origin: .zero, size: size)
    let path = NSBezierPath(roundedRect: rect, xRadius: 3, yRadius: 3)
    path.fill()

    image.unlockFocus()
    return image
}

struct GettingStartedView: View {
    @Environment(NotesManager.self) private var notesManager
    @Environment(\.openWindow) private var openWindow

    var recentNotes: [Note] {
        Array(notesManager.notes.sorted { $0.createdAt > $1.createdAt }.prefix(5))
    }

    var body: some View {
        VStack(spacing: 0) {
            // New Note button
            MenuButton(
                icon: "square.and.pencil",
                title: "New Note",
                action: {
                    let note = notesManager.createNote()
                    openWindow(value: note.id)
                }
            )

            Divider()
                .padding(.horizontal, 16)

            // Carousel Dashboard button
            MenuButton(
                icon: "square.stack.3d.up",
                title: "Carousel Dashboard",
                action: {
                    openWindow(id: "carousel-dashboard")
                }
            )

            Divider()
                .padding(.horizontal, 16)

            // Notes list - showing only 5 most recent notes
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(recentNotes) { note in
                        MenuButton(
                            icon: nil,
                            title: note.title.isEmpty ? "Untitled" : note.title,
                            nsColor: note.color.nsBackgroundColor,
                            action: {
                                notesManager.openNote(note.id)
                                openWindow(value: note.id)
                            }
                        )
                    }
                }
                .padding(.vertical, 8)
            }
            .frame(maxHeight: 300)

            Divider()
                .padding(.horizontal, 16)

            // Show all Notes button
            MenuButton(
                icon: "doc.on.doc",
                title: "Show all Notes",
                action: {
                    openWindow(id: "show-all-notes")
                }
            )

            // More menu
            VStack(spacing: 0) {
                Divider()
                    .padding(.horizontal, 16)

                MenuButton(
                    icon: "gear",
                    title: "Settings",
                    action: { }
                )

                Divider()
                    .padding(.horizontal, 16)

                MenuButton(
                    icon: "power",
                    title: "Quit thinqsync",
                    action: {
                        NSApplication.shared.terminate(nil)
                    }
                )
            }
        }
        .frame(width: 280)
        .background(Color(nsColor: .windowBackgroundColor))
    }
}

// Custom menu button that uses NSColor for proper rendering
struct MenuButton: View {
    let icon: String?
    let title: String
    var nsColor: NSColor? = nil
    let action: () -> Void

    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                if let noteNSColor = nsColor {
                    // Use NSImage-based colored square for menu compatibility
                    Image(nsImage: createColoredSquareImage(color: noteNSColor, size: CGSize(width: 18, height: 18)))
                        .frame(width: 18, height: 18)
                } else if let iconName = icon {
                    // Regular icon without color
                    Image(systemName: iconName)
                        .font(.system(size: 16))
                        .foregroundColor(Color(nsColor: .labelColor))
                }

                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(nsColor: .labelColor))

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(isHovering ? Color(nsColor: .selectedContentBackgroundColor) : Color.clear)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovering = hovering
        }
    }
}

#Preview {
    GettingStartedView()
        .environment(NotesManager())
}
