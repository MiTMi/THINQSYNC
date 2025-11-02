//
//  ShowAllNotesView.swift
//  thinqsync
//
//  Created by Michael on 02/11/2025.
//

import SwiftUI

struct ShowAllNotesView: View {
    @Environment(NotesManager.self) private var notesManager
    @State private var selectedNoteID: UUID?
    @State private var searchText = ""
    @Environment(\.openWindow) var openWindow

    var filteredNotes: [Note] {
        if searchText.isEmpty {
            return notesManager.notes.sorted { $0.modifiedAt > $1.modifiedAt }
        } else {
            return notesManager.notes.filter { note in
                note.title.localizedCaseInsensitiveContains(searchText) ||
                note.content.localizedCaseInsensitiveContains(searchText)
            }.sorted { $0.modifiedAt > $1.modifiedAt }
        }
    }

    var body: some View {
        NavigationSplitView {
            // Sidebar with note list
            VStack(spacing: 0) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search all Notes", text: $searchText)
                        .textFieldStyle(.plain)
                }
                .padding(8)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(6)
                .padding()

                // Notes list
                List(selection: $selectedNoteID) {
                    ForEach(filteredNotes) { note in
                        NoteListItem(note: note)
                            .tag(note.id)
                            .contextMenu {
                                Button("Open in Window") {
                                    openWindow(value: note.id)
                                    notesManager.openNote(note.id)
                                }

                                Button("Toggle Favorite") {
                                    notesManager.toggleFavorite(note)
                                }

                                Divider()

                                Button("Delete", role: .destructive) {
                                    withAnimation {
                                        notesManager.deleteNote(note)
                                        if selectedNoteID == note.id {
                                            selectedNoteID = nil
                                        }
                                    }
                                }
                            }
                    }
                }
                .listStyle(.sidebar)
            }
            .navigationSplitViewColumnWidth(min: 200, ideal: 250, max: 300)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: {
                        let newNote = notesManager.createNote()
                        selectedNoteID = newNote.id
                    }) {
                        Label("New Note", systemImage: "square.and.pencil")
                    }
                }
            }
        } detail: {
            // Detail view
            if let noteID = selectedNoteID,
               let note = notesManager.notes.first(where: { $0.id == noteID }) {
                NoteDetailView(noteID: noteID, notesManager: notesManager)
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "note.text")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text("Select a note to view")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    Text("or create a new one")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .onAppear {
            // Select first note if available
            if selectedNoteID == nil && !filteredNotes.isEmpty {
                selectedNoteID = filteredNotes.first?.id
            }
        }
    }
}

struct NoteListItem: View {
    let note: Note

    var body: some View {
        HStack(spacing: 12) {
            // Color indicator
            RoundedRectangle(cornerRadius: 4)
                .fill(note.color.backgroundColor)
                .frame(width: 4, height: 44)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(note.title)
                        .font(.system(size: 14, weight: .medium))
                        .lineLimit(1)

                    if note.isFavorite {
                        Image(systemName: "star.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.yellow)
                    }
                }

                Text(note.content)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer()
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }
}

struct NoteDetailView: View {
    let noteID: UUID
    var notesManager: NotesManager
    @Environment(\.openWindow) var openWindow
    @State private var isEditingTitle = false
    @FocusState private var titleFieldFocused: Bool
    @State private var editedTitle = ""
    @State private var editedAttributedContent: NSAttributedString?

    var note: Note? {
        notesManager.notes.first(where: { $0.id == noteID })
    }

    var body: some View {
        if let currentNote = note {
            VStack(spacing: 0) {
                // Header with title and actions
                HStack(spacing: 16) {
                    // Color indicator
                    Circle()
                        .fill(currentNote.color.backgroundColor)
                        .frame(width: 12, height: 12)

                    if isEditingTitle {
                        TextField("Note Title", text: $editedTitle)
                            .textFieldStyle(.plain)
                            .font(.title2.weight(.semibold))
                            .foregroundColor(currentNote.color.textColor)
                            .focused($titleFieldFocused)
                            .onSubmit {
                                isEditingTitle = false
                                var updatedNote = currentNote
                                updatedNote.title = editedTitle
                                notesManager.updateNote(updatedNote)
                            }
                    } else {
                        Text(currentNote.title)
                            .font(.title2.weight(.semibold))
                            .foregroundColor(currentNote.color.textColor)
                            .onTapGesture(count: 2) {
                                editedTitle = currentNote.title
                                isEditingTitle = true
                                titleFieldFocused = true
                            }
                    }

                    Spacer()

                    // Action buttons
                    HStack(spacing: 12) {
                        Button(action: {
                            var updatedNote = currentNote
                            updatedNote.isFavorite.toggle()
                            notesManager.updateNote(updatedNote)
                        }) {
                            Image(systemName: currentNote.isFavorite ? "star.fill" : "star")
                                .foregroundColor(currentNote.isFavorite ? .yellow : currentNote.color.iconColor)
                        }
                        .buttonStyle(.plain)

                        Menu {
                            ForEach(NoteColor.allCases, id: \.self) { color in
                                Button(action: {
                                    var updatedNote = currentNote
                                    updatedNote.color = color
                                    notesManager.updateNote(updatedNote)
                                }) {
                                    HStack {
                                        Circle()
                                            .fill(color.backgroundColor)
                                            .frame(width: 12, height: 12)
                                        Text(color.rawValue.capitalized)
                                    }
                                }
                            }
                        } label: {
                            Image(systemName: "paintpalette")
                                .foregroundColor(currentNote.color.iconColor)
                        }
                        .buttonStyle(.plain)

                        Button(action: {
                            openWindow(value: currentNote.id)
                            notesManager.openNote(currentNote.id)
                        }) {
                            Image(systemName: "arrow.up.forward.square")
                                .foregroundColor(currentNote.color.iconColor)
                        }
                        .buttonStyle(.plain)
                        .help("Open in separate window")

                        Button(action: {
                            notesManager.deleteNote(currentNote)
                        }) {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
                .background(currentNote.color.backgroundColor)

                // Note content with color background
                ZStack {
                    currentNote.color.backgroundColor
                        .ignoresSafeArea()

                    ScrollView {
                        RichTextEditor(
                            attributedText: Binding(
                                get: { editedAttributedContent ?? currentNote.attributedContent },
                                set: { newValue in
                                    editedAttributedContent = newValue
                                }
                            ),
                            textColor: Color(currentNote.color.textColor),
                            onTextChange: { newValue in
                                editedAttributedContent = newValue
                                var updatedNote = currentNote
                                updatedNote.attributedContent = newValue
                                updatedNote.modifiedAt = Date()
                                notesManager.updateNote(updatedNote)
                            }
                        )
                        .frame(minHeight: 400)
                        .padding(16)
                    }
                }

                Divider()

                // Footer with metadata
                HStack {
                    Text("Created: \(currentNote.createdAt.formatted(date: .abbreviated, time: .shortened))")
                        .font(.caption)
                        .foregroundColor(currentNote.color.textColor.opacity(0.7))

                    Spacer()

                    Text("Modified: \(currentNote.modifiedAt.formatted(date: .abbreviated, time: .shortened))")
                        .font(.caption)
                        .foregroundColor(currentNote.color.textColor.opacity(0.7))
                }
                .padding()
                .background(currentNote.color.backgroundColor)
            }
            .onAppear {
                editedAttributedContent = currentNote.attributedContent
            }
            .onChange(of: noteID) { oldValue, newValue in
                // Reset edited content when note changes
                if let newNote = notesManager.notes.first(where: { $0.id == newValue }) {
                    editedAttributedContent = newNote.attributedContent
                    editedTitle = newNote.title
                }
            }
        } else {
            Text("Note not found")
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    ShowAllNotesView()
        .environment(NotesManager())
        .frame(width: 800, height: 600)
}
