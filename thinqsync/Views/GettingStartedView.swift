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

    // Define explicit white color to bypass any system interference
    private let explicitWhite = Color(red: 1.0, green: 1.0, blue: 1.0)
    private let darkBackground = Color(red: 0.15, green: 0.15, blue: 0.15)

    var body: some View {
        VStack(spacing: 0) {
            // New Note button with edit icon
            Button(action: {
                let note = notesManager.createNote()
                openWindow(value: note.id)
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "square.and.pencil")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(explicitWhite)
                    Text("New Note")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(explicitWhite)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())

            // Divider
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(height: 1)
                .padding(.horizontal, 16)

            // Notes list
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(notesManager.notes) { note in
                        NoteRow(note: note, textColor: explicitWhite)
                    }
                }
                .padding(.vertical, 8)
            }
            .frame(maxHeight: 300)

            // Divider before bottom buttons
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(height: 1)
                .padding(.horizontal, 16)

            // Show all Notes button
            Button(action: {
                // Show all notes action
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "doc.on.doc")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(explicitWhite)
                    Text("Show all Notes")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(explicitWhite)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())

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
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(explicitWhite)
                    Text("More")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(explicitWhite)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(explicitWhite)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .contentShape(Rectangle())
            }
            .menuStyle(BorderlessButtonMenuStyle())
            .buttonStyle(PlainButtonStyle())
        }
        .frame(width: 280)
        .background(darkBackground)
    }
}

struct NoteRow: View {
    let note: Note
    let textColor: Color
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
                            .stroke(Color(red: 1.0, green: 1.0, blue: 1.0, opacity: 0.2), lineWidth: 0.5)
                    )

                Text(note.title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(textColor)
                    .lineLimit(1)

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    GettingStartedView()
        .environment(NotesManager())
}
