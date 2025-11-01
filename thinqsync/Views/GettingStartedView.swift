//
//  GettingStartedView.swift
//  thinqsync
//
//  Created by Michael   on 31/10/2025.
//

import SwiftUI

struct GettingStartedView: View {
    @Environment(NotesManager.self) private var notesManager
    @Environment(\.openWindow) private var openWindow

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

            // Notes list
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(notesManager.notes) { note in
                        MenuButton(
                            icon: nil,
                            title: note.title,
                            color: note.color.backgroundColor,
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
                action: { }
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
    var color: Color?
    let action: () -> Void

    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                if let iconName = icon {
                    Image(systemName: iconName)
                        .font(.system(size: 16))
                        .foregroundColor(Color(nsColor: .labelColor))
                } else if let noteColor = color {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(noteColor)
                        .frame(width: 16, height: 16)
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
