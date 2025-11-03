//
//  ShowAllNotesView.swift
//  thinqsync
//
//  Created by Michael on 02/11/2025.
//

import SwiftUI
import AppKit

struct ShowAllNotesView: View {
    @Environment(NotesManager.self) private var notesManager
    @State private var selectedNoteID: UUID?
    @State private var searchText = ""
    @State private var selectedSection: SidebarSection? = .mySpace
    @State private var showingNewFolderAlert = false
    @State private var showingSearch = false
    @State private var newFolderName = ""
    @Environment(\.openWindow) var openWindow

    enum SidebarSection: Hashable {
        case mySpace
        case starred
        case folder(String)
        case trash
    }

    var folders: [String] {
        let folderSet = Set(notesManager.notes.compactMap { $0.folder })
        return folderSet.sorted()
    }

    var filteredNotes: [Note] {
        var notes: [Note]

        // Filter by section
        switch selectedSection {
        case .starred:
            notes = notesManager.notes.filter { $0.isFavorite }
        case .folder(let folderName):
            notes = notesManager.notes.filter { $0.folder == folderName }
        case .trash:
            notes = notesManager.deletedNotes
        case .mySpace, .none:
            notes = notesManager.notes
        }

        // Apply search filter
        if !searchText.isEmpty {
            notes = notes.filter { note in
                note.title.localizedCaseInsensitiveContains(searchText) ||
                note.content.localizedCaseInsensitiveContains(searchText)
            }
        }

        // Sort
        if selectedSection != .trash {
            return notes.sorted { $0.modifiedAt > $1.modifiedAt }
        }
        return notes
    }

    var body: some View {
        HStack(spacing: 0) {
            // Left Sidebar
            VStack(spacing: 0) {
                // New Note Button
                Button(action: {
                    let newNote = notesManager.createNote()
                    selectedNoteID = newNote.id
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 16))
                        Text("New Note")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 12)

                Divider()

                // Sidebar List
                List(selection: $selectedSection) {
                    // Michael's Space
                    Section {
                        SidebarRow(
                            icon: "person.crop.circle.fill",
                            title: "Michael's Space",
                            count: notesManager.notes.count
                        )
                        .tag(SidebarSection.mySpace)
                    }

                    // Starred
                    Section {
                        SidebarRow(
                            icon: "star.fill",
                            title: "Starred",
                            count: notesManager.notes.filter { $0.isFavorite }.count,
                            iconColor: .yellow
                        )
                        .tag(SidebarSection.starred)
                    }

                    // Folders
                    Section("Folders") {
                        ForEach(folders, id: \.self) { folder in
                            SidebarRow(
                                icon: "folder.fill",
                                title: folder,
                                count: notesManager.notes.filter { $0.folder == folder }.count,
                                iconColor: .blue
                            )
                            .tag(SidebarSection.folder(folder))
                        }

                        // New Folder
                        Button(action: {
                            showingNewFolderAlert = true
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "plus.circle")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                                Text("New Folder")
                                    .font(.system(size: 13))
                                    .foregroundColor(.secondary)
                            }
                        }
                        .buttonStyle(.plain)
                    }

                    // Trash
                    Section {
                        SidebarRow(
                            icon: "trash",
                            title: "Trash",
                            count: notesManager.deletedNotes.count,
                            iconColor: .red
                        )
                        .tag(SidebarSection.trash)
                    }
                }
                .listStyle(.sidebar)
                .scrollContentBackground(.hidden)
            }
            .frame(width: 240)
            .background(Color(nsColor: .windowBackgroundColor))

            Divider()

            // Main Content Area
            VStack(spacing: 0) {
                // Top Bar
                HStack {
                    Text(sectionTitle)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(Color(nsColor: .labelColor))

                    Spacer()

                    // Search Button
                    Button(action: {
                        showingSearch.toggle()
                    }) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 16))
                            .foregroundColor(Color(nsColor: .labelColor))
                            .frame(width: 32, height: 32)
                            .background(Color(nsColor: .controlBackgroundColor))
                            .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)

                // Search Field (conditional)
                if showingSearch {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        TextField("Search notes...", text: $searchText)
                            .textFieldStyle(.plain)
                        if !searchText.isEmpty {
                            Button(action: {
                                searchText = ""
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(10)
                    .background(Color(nsColor: .controlBackgroundColor))
                    .cornerRadius(8)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 12)
                }

                Divider()

                // Notes Grid
                if filteredNotes.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "note.text")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        Text("No Notes")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.secondary)
                        if selectedSection == .trash {
                            Text("Your trash is empty")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: 16),
                            GridItem(.flexible(), spacing: 16),
                            GridItem(.flexible(), spacing: 16)
                        ], spacing: 16) {
                            ForEach(filteredNotes) { note in
                                NoteCard(
                                    note: note,
                                    isSelected: selectedNoteID == note.id,
                                    isTrash: selectedSection == .trash,
                                    onTap: {
                                        selectedNoteID = note.id
                                    },
                                    onDelete: {
                                        notesManager.deleteNote(note)
                                    },
                                    onRestore: {
                                        notesManager.restoreNote(note)
                                    }
                                )
                            }
                        }
                        .padding(24)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(nsColor: .windowBackgroundColor))
        }
        .alert("New Folder", isPresented: $showingNewFolderAlert) {
            TextField("Folder Name", text: $newFolderName)
            Button("Cancel", role: .cancel) {
                newFolderName = ""
            }
            Button("Create") {
                if !newFolderName.isEmpty {
                    var newNote = notesManager.createNote()
                    newNote.folder = newFolderName
                    notesManager.updateNote(newNote)
                    selectedSection = .folder(newFolderName)
                    selectedNoteID = newNote.id
                    newFolderName = ""
                }
            }
        } message: {
            Text("Enter a name for the new folder")
        }
        .sheet(isPresented: Binding(
            get: { selectedNoteID != nil },
            set: { if !$0 { selectedNoteID = nil } }
        )) {
            if let noteID = selectedNoteID,
               let noteBinding = notesManager.binding(for: noteID) {
                NoteEditorSheet(note: noteBinding)
                    .environment(notesManager)
            }
        }
    }

    var sectionTitle: String {
        switch selectedSection {
        case .mySpace:
            return "All Documents"
        case .starred:
            return "Starred"
        case .folder(let name):
            return name
        case .trash:
            return "Trash"
        case .none:
            return "All Documents"
        }
    }
}

// Sidebar Row Component
struct SidebarRow: View {
    let icon: String
    let title: String
    let count: Int
    var iconColor: Color = Color(nsColor: .labelColor)

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(iconColor)
                .frame(width: 18)

            Text(title)
                .font(.system(size: 13))
                .foregroundColor(Color(nsColor: .labelColor))

            Spacer()

            Text("\(count)")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

// Note Card Component
struct NoteCard: View {
    let note: Note
    let isSelected: Bool
    let isTrash: Bool
    let onTap: () -> Void
    let onDelete: () -> Void
    let onRestore: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Title
            Text(note.title.isEmpty ? "Untitled" : note.title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Color(nsColor: .labelColor))
                .lineLimit(2)

            // Content Preview
            Text(note.content)
                .font(.system(size: 13))
                .foregroundColor(.secondary)
                .lineLimit(4)
                .frame(maxWidth: .infinity, alignment: .leading)

            Spacer()

            // Footer
            HStack {
                Text(note.modifiedAt.formatted(date: .abbreviated, time: .omitted))
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)

                Spacer()

                if note.isFavorite {
                    Image(systemName: "star.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.yellow)
                }
            }
        }
        .padding(16)
        .frame(height: 200)
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
        .contextMenu {
            if isTrash {
                Button("Restore") {
                    onRestore()
                }
                Button("Delete Permanently", role: .destructive) {
                    onDelete()
                }
            } else {
                Button("Delete") {
                    onDelete()
                }
            }
        }
    }
}

// Note Editor Sheet
struct NoteEditorSheet: View {
    @Binding var note: Note
    @Environment(NotesManager.self) private var notesManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)

                Spacer()

                // Favorite button
                Button(action: {
                    note.isFavorite.toggle()
                    notesManager.updateNote(note)
                }) {
                    Image(systemName: note.isFavorite ? "star.fill" : "star")
                        .font(.system(size: 18))
                        .foregroundColor(note.isFavorite ? .yellow : .secondary)
                }
                .buttonStyle(.plain)

                // Folder menu
                Menu {
                    Button("None") {
                        note.folder = nil
                        notesManager.updateNote(note)
                    }

                    Divider()

                    let folders = Set(notesManager.notes.compactMap { $0.folder }).sorted()
                    ForEach(folders, id: \.self) { folder in
                        Button(folder) {
                            note.folder = folder
                            notesManager.updateNote(note)
                        }
                    }
                } label: {
                    Image(systemName: "folder")
                        .font(.system(size: 18))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(16)

            Divider()

            // Title
            TextField("Title", text: $note.title)
                .textFieldStyle(.plain)
                .font(.system(size: 28, weight: .bold))
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 12)

            Divider()

            // Editor
            RichTextEditorWithSlashMenu(
                attributedText: Binding(
                    get: {
                        // Always use fixed colors for display in Show All Notes
                        fixAttributedStringColors(note.attributedContent)
                    },
                    set: { newValue in
                        // Save with note's original color scheme (for menubar compatibility)
                        let contentWithNoteColors = applyNoteColors(newValue)
                        note.attributedContent = contentWithNoteColors
                        note.modifiedAt = Date()
                        notesManager.updateNote(note)
                    }
                ),
                textColor: Color(nsColor: .labelColor),
                onTextChange: { newText in
                    // Save with note's original color scheme (for menubar compatibility)
                    let contentWithNoteColors = applyNoteColors(newText)
                    note.attributedContent = contentWithNoteColors
                    note.modifiedAt = Date()
                    notesManager.updateNote(note)
                }
            )
            .padding(20)
        }
        .frame(minWidth: 700, minHeight: 500)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    // Fix colors to system colors for display in Show All Notes
    private func fixAttributedStringColors(_ attributedString: NSAttributedString) -> NSAttributedString {
        let mutableString = NSMutableAttributedString(attributedString: attributedString)
        let range = NSRange(location: 0, length: mutableString.length)

        // Replace all foreground colors with system label color
        mutableString.enumerateAttribute(.foregroundColor, in: range) { value, range, _ in
            mutableString.addAttribute(.foregroundColor, value: NSColor.labelColor, range: range)
        }

        return mutableString
    }

    // Apply note's color scheme when saving (for menubar notes)
    private func applyNoteColors(_ attributedString: NSAttributedString) -> NSAttributedString {
        let mutableString = NSMutableAttributedString(attributedString: attributedString)
        let range = NSRange(location: 0, length: mutableString.length)

        // Apply the note's text color
        let noteTextColor = NSColor(note.color.textColor)
        mutableString.enumerateAttribute(.foregroundColor, in: range) { value, range, _ in
            mutableString.addAttribute(.foregroundColor, value: noteTextColor, range: range)
        }

        return mutableString
    }
}

#Preview {
    ShowAllNotesView()
        .environment(NotesManager())
        .frame(width: 1200, height: 800)
}
