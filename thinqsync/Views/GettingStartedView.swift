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
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(spacing: 0) {
            // New Note button with edit icon
            Button(action: {
                let note = notesManager.createNote()
                openWindow(value: note.id)
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "square.and.pencil")
                        .font(.system(size: 16))
                        .foregroundStyle(.white)
                    Text("New Note")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .background(Color.white.opacity(0))
            .onHover { hovering in
                // Add hover effect if needed
            }

            // Divider
            Divider()
                .background(Color.gray.opacity(0.3))
                .padding(.horizontal, 16)

            // Notes list
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(notesManager.notes) { note in
                        NoteRow(note: note)
                    }
                }
                .padding(.vertical, 8)
            }
            .frame(maxHeight: 300)

            // Divider before bottom buttons
            Divider()
                .background(Color.gray.opacity(0.3))
                .padding(.horizontal, 16)

            // Show all Notes button
            Button(action: {
                // Show all notes action
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "doc.on.doc")
                        .font(.system(size: 16))
                        .foregroundStyle(.white)
                    Text("Show all Notes")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            // More button with arrow
            Menu {
                Button("Settings") {
                    // Settings action
                }
                Divider()
                Button("Quit thinqsync") {
                    NSApplication.shared.terminate(nil)
                }
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 16))
                        .foregroundStyle(.white)
                    Text("More")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .contentShape(Rectangle())
            }
            .menuStyle(.borderlessButton)
            .buttonStyle(.plain)
        }
        .frame(width: 280)
        .background(Color(red: 0.15, green: 0.15, blue: 0.15))
        .preferredColorScheme(.dark)
    }
}

struct NoteRow: View {
    let note: Note
    @Environment(NotesManager.self) private var notesManager
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Button(action: {
            notesManager.openNote(note.id)
            openWindow(value: note.id)
        }) {
            HStack(spacing: 12) {
                // Colored square icon based on note color
                RoundedRectangle(cornerRadius: 3)
                    .fill(note.color.backgroundColor)
                    .frame(width: 16, height: 16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 3)
                            .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
                    )

                Text(note.title)
                    .font(.system(size: 14))
                    .foregroundStyle(.white)
                    .lineLimit(1)

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(Color.white.opacity(0))
        .onHover { hovering in
            // Add hover effect if needed
        }
    }
}

#Preview {
    GettingStartedView()
        .environment(NotesManager())
}