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
    @State private var selectedSection: SidebarSection? = .allNotes
    @State private var showingNewFolderAlert = false
    @State private var showingSearch = false
    @State private var newFolderName = ""
    @State private var viewMode: ViewMode = .grid
    @State private var showingEmptyTrashAlert = false
    @State private var sortOrder: SortOrder = .modifiedDate
    @Environment(\.openWindow) var openWindow

    enum SidebarSection: Hashable {
        case allNotes
        case starred
        case folder(String)
        case trash
    }

    enum ViewMode {
        case grid
        case list
    }

    enum SortOrder {
        case modifiedDate
        case createdDate
        case title
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
        case .allNotes, .none:
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
            switch sortOrder {
            case .modifiedDate:
                return notes.sorted { $0.modifiedAt > $1.modifiedAt }
            case .createdDate:
                return notes.sorted { $0.createdAt > $1.createdAt }
            case .title:
                return notes.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
            }
        }
        return notes
    }

    var body: some View {
        HStack(spacing: 0) {
            // Left Sidebar
            VStack(spacing: 0) {
                // Title and Settings
                HStack {
                    Text("Notes")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(.white)

                    Spacer()

                    Button(action: {
                        // TODO: Open settings
                    }) {
                        Image(systemName: "gearshape")
                            .font(.system(size: 16))
                            .foregroundColor(.gray)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)

                // New Note Button
                Button(action: {
                    let newNote = notesManager.createNote()
                    openWindow(value: newNote.id)
                }) {
                    HStack {
                        Image(systemName: "plus")
                            .font(.system(size: 14, weight: .semibold))
                        Text("New Note")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color(red: 0x3B/255, green: 0x82/255, blue: 0xF6/255))
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 16)
                .padding(.bottom, 16)

                // All Notes Section
                SidebarRow(
                    icon: "note.text",
                    title: "All Notes",
                    count: notesManager.notes.count,
                    iconColor: .blue,
                    isSelected: selectedSection == .allNotes
                )
                .contentShape(Rectangle())
                .onTapGesture {
                    selectedSection = .allNotes
                }
                .padding(.bottom, 12)

                Divider()
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)

                // Folders Section
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("FOLDERS")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.gray)

                        Spacer()

                        Button(action: {
                            showingNewFolderAlert = true
                        }) {
                            Image(systemName: "plus")
                                .font(.system(size: 10))
                                .foregroundColor(.gray)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 8)

                    ForEach(folders, id: \.self) { folder in
                        SidebarRow(
                            icon: getFolderIcon(folder),
                            title: folder,
                            count: notesManager.notes.filter { $0.folder == folder }.count,
                            iconColor: getFolderColor(folder),
                            isSelected: selectedSection == .folder(folder)
                        )
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedSection = .folder(folder)
                        }
                    }
                }
                .padding(.bottom, 12)

                Divider()
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)

                // Starred
                SidebarRow(
                    icon: "star.fill",
                    title: "Starred",
                    count: notesManager.notes.filter { $0.isFavorite }.count,
                    iconColor: .yellow,
                    isSelected: selectedSection == .starred
                )
                .contentShape(Rectangle())
                .onTapGesture {
                    selectedSection = .starred
                }

                // Trash
                SidebarRow(
                    icon: "trash",
                    title: "Trash",
                    count: notesManager.deletedNotes.count,
                    iconColor: .red,
                    isSelected: selectedSection == .trash
                )
                .contentShape(Rectangle())
                .onTapGesture {
                    selectedSection = .trash
                }

                Spacer()

                // User Profile at bottom
                Divider()
                    .padding(.horizontal, 16)

                HStack(spacing: 10) {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 32, height: 32)
                        .overlay(
                            Image(systemName: "person.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                        )

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Sarah Wilson")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white)
                        Text("Free Plan")
                            .font(.system(size: 11))
                            .foregroundColor(.gray)
                    }

                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .frame(width: 260)
            .background(Color(red: 0x1E/255, green: 0x24/255, blue: 0x2E/255))

            // Main Content Area
            VStack(spacing: 0) {
                // Top Navigation Bar
                HStack(spacing: 16) {
                    // Section title and count
                    HStack(spacing: 8) {
                        Text(sectionTitle)
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(.white)

                        Text("\(filteredNotes.count) notes")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }

                    Spacer()

                    // Empty Trash Button (only show in trash section)
                    if selectedSection == .trash && !notesManager.deletedNotes.isEmpty {
                        Button(action: {
                            showingEmptyTrashAlert = true
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "trash")
                                    .font(.system(size: 12))
                                Text("Empty Trash")
                                    .font(.system(size: 13, weight: .medium))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(Color.red)
                            .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                    }

                    // Search Field
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 13))
                            .foregroundColor(.gray)
                        TextField("Search notes...", text: $searchText)
                            .textFieldStyle(.plain)
                            .font(.system(size: 13))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .frame(width: 220)
                    .background(Color(red: 0x2D/255, green: 0x35/255, blue: 0x42/255))
                    .cornerRadius(8)

                    // Grid/List View Toggle
                    HStack(spacing: 4) {
                        Button(action: {
                            viewMode = .grid
                        }) {
                            Image(systemName: "square.grid.2x2")
                                .font(.system(size: 14))
                                .foregroundColor(viewMode == .grid ? .white : .gray)
                                .frame(width: 32, height: 32)
                                .background(viewMode == .grid ? Color(red: 0x2D/255, green: 0x35/255, blue: 0x42/255) : Color.clear)
                                .cornerRadius(6)
                        }
                        .buttonStyle(.plain)

                        Button(action: {
                            viewMode = .list
                        }) {
                            Image(systemName: "list.bullet")
                                .font(.system(size: 14))
                                .foregroundColor(viewMode == .list ? .white : .gray)
                                .frame(width: 32, height: 32)
                                .background(viewMode == .list ? Color(red: 0x2D/255, green: 0x35/255, blue: 0x42/255) : Color.clear)
                                .cornerRadius(6)
                        }
                        .buttonStyle(.plain)
                    }

                    // Sort Button
                    Menu {
                        Button(action: {
                            sortOrder = .modifiedDate
                        }) {
                            HStack {
                                Text("Modified Date")
                                if sortOrder == .modifiedDate {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                        Button(action: {
                            sortOrder = .createdDate
                        }) {
                            HStack {
                                Text("Created Date")
                                if sortOrder == .createdDate {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                        Button(action: {
                            sortOrder = .title
                        }) {
                            HStack {
                                Text("Title")
                                if sortOrder == .title {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.up.arrow.down")
                                .font(.system(size: 12))
                            Text("Sort")
                                .font(.system(size: 13))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color(red: 0x2D/255, green: 0x35/255, blue: 0x42/255))
                        .cornerRadius(8)
                    }
                    .menuStyle(.borderlessButton)
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
                .background(Color(red: 0x1A/255, green: 0x20/255, blue: 0x2A/255))

                // Notes Grid/List
                if filteredNotes.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "note.text")
                            .font(.system(size: 48))
                            .foregroundColor(.gray)
                        Text("No Notes")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.gray)
                        if selectedSection == .trash {
                            Text("Your trash is empty")
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        if viewMode == .grid {
                            LazyVGrid(columns: [
                                GridItem(.flexible(), spacing: 20),
                                GridItem(.flexible(), spacing: 20),
                                GridItem(.flexible(), spacing: 20),
                                GridItem(.flexible(), spacing: 20)
                            ], spacing: 20) {
                                ForEach(filteredNotes) { note in
                                    NoteCard(
                                        note: note,
                                        isSelected: selectedNoteID == note.id,
                                        isTrash: selectedSection == .trash,
                                        onTap: {
                                            // Open the note in a floating window like from menubar
                                            openWindow(value: note.id)
                                            notesManager.openNote(note.id)
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
                        } else {
                            LazyVStack(spacing: 12) {
                                ForEach(filteredNotes) { note in
                                    NoteListRow(
                                        note: note,
                                        isSelected: selectedNoteID == note.id,
                                        isTrash: selectedSection == .trash,
                                        onTap: {
                                            openWindow(value: note.id)
                                            notesManager.openNote(note.id)
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
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(red: 0x0F/255, green: 0x14/255, blue: 0x1A/255))
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
                    openWindow(value: newNote.id)
                    newFolderName = ""
                }
            }
        } message: {
            Text("Enter a name for the new folder")
        }
        .alert("Empty Trash", isPresented: $showingEmptyTrashAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Empty Trash", role: .destructive) {
                notesManager.emptyTrash()
            }
        } message: {
            Text("All notes in the trash will be permanently deleted. This action cannot be undone.")
        }
    }

    private func getFolderIcon(_ folder: String) -> String {
        switch folder.lowercased() {
        case "work": return "briefcase.fill"
        case "personal": return "person.fill"
        case "ideas": return "lightbulb.fill"
        default: return "folder.fill"
        }
    }

    private func getFolderColor(_ folder: String) -> Color {
        switch folder.lowercased() {
        case "work": return Color(red: 0x3B/255, green: 0x82/255, blue: 0xF6/255)
        case "personal": return Color(red: 0x10/255, green: 0xB9/255, blue: 0x81/255)
        case "ideas": return Color(red: 0xA8/255, green: 0x5C/255, blue: 0xF6/255)
        default: return Color.blue
        }
    }

    var sectionTitle: String {
        switch selectedSection {
        case .allNotes:
            return "All Notes"
        case .starred:
            return "Starred"
        case .folder(let name):
            return name
        case .trash:
            return "Trash"
        case .none:
            return "All Notes"
        }
    }
}

// Sidebar Row Component
struct SidebarRow: View {
    let icon: String
    let title: String
    let count: Int
    var iconColor: Color = .gray
    var isSelected: Bool = false

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundColor(iconColor)
                .frame(width: 20)

            Text(title)
                .font(.system(size: 13, weight: isSelected ? .medium : .regular))
                .foregroundColor(isSelected ? .white : Color.gray.opacity(0.8))

            Spacer()

            Text("\(count)")
                .font(.system(size: 11))
                .foregroundColor(.gray)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 6)
        .background(isSelected ? Color.white.opacity(0.1) : Color.clear)
        .cornerRadius(6)
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

    @State private var isHoveringDelete = false
    @State private var isHoveringHeader = false
    @State private var showingPermanentDeleteAlert = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Color Dot, Star, and Delete icon
            HStack {
                Circle()
                    .fill(note.color.backgroundColor)
                    .frame(width: 12, height: 12)

                Spacer()

                if note.isFavorite && !isTrash {
                    Image(systemName: "star.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.yellow)
                }

                // Delete button (soft delete when not in trash, permanent delete when in trash)
                Button(action: {
                    if isTrash {
                        showingPermanentDeleteAlert = true
                    } else {
                        onDelete()
                    }
                }) {
                    Image(systemName: isTrash ? "trash.slash" : "trash")
                        .font(.system(size: 11))
                        .foregroundColor(isHoveringDelete ? .red : .gray.opacity(0.6))
                }
                .buttonStyle(.plain)
                .onHover { hovering in
                    isHoveringDelete = hovering
                }
            }
            .padding(.horizontal, -4)
            .padding(.vertical, 4)
            .background(isHoveringHeader ? Color.white.opacity(0.05) : Color.clear)
            .cornerRadius(6)
            .onHover { hovering in
                isHoveringHeader = hovering
            }

            // Title
            Text(note.title.isEmpty ? "Untitled" : note.title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white)
                .lineLimit(1)

            // Content Preview
            Text(note.content)
                .font(.system(size: 13))
                .foregroundColor(.gray)
                .lineLimit(3)
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(height: 50)

            Spacer()

            // Footer: Date and Folder Tag
            HStack(alignment: .bottom) {
                Text(note.modifiedAt.formatted(date: .abbreviated, time: .omitted))
                    .font(.system(size: 11))
                    .foregroundColor(.gray)

                Spacer()

                if let folder = note.folder {
                    Text(folder)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(getFolderTagColor(folder))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(getFolderTagColor(folder).opacity(0.2))
                        .cornerRadius(4)
                }
            }
        }
        .padding(16)
        .frame(height: 180)
        .background(Color(red: 0x1E/255, green: 0x24/255, blue: 0x2E/255))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(isSelected ? Color.blue : Color.clear, lineWidth: 2)
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
                    showingPermanentDeleteAlert = true
                }
            } else {
                Button("Delete") {
                    onDelete()
                }
            }
        }
        .alert("Permanently Delete Note", isPresented: $showingPermanentDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete Permanently", role: .destructive) {
                onDelete()
            }
        } message: {
            Text("This note will be permanently deleted and cannot be restored. This action cannot be undone.")
        }
    }

    private func getFolderTagColor(_ folder: String) -> Color {
        switch folder.lowercased() {
        case "work": return Color(red: 0x3B/255, green: 0x82/255, blue: 0xF6/255)
        case "personal": return Color(red: 0x10/255, green: 0xB9/255, blue: 0x81/255)
        case "ideas": return Color(red: 0xA8/255, green: 0x5C/255, blue: 0xF6/255)
        default: return Color.blue
        }
    }
}

// Note List Row Component (for list view)
struct NoteListRow: View {
    let note: Note
    let isSelected: Bool
    let isTrash: Bool
    let onTap: () -> Void
    let onDelete: () -> Void
    let onRestore: () -> Void

    @State private var isHoveringDelete = false
    @State private var isHovering = false
    @State private var showingPermanentDeleteAlert = false

    var body: some View {
        HStack(spacing: 16) {
            // Color indicator
            Circle()
                .fill(note.color.backgroundColor)
                .frame(width: 10, height: 10)

            // Content
            VStack(alignment: .leading, spacing: 4) {
                // Title
                Text(note.title.isEmpty ? "Untitled" : note.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)

                // Content preview
                Text(note.content)
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
                    .lineLimit(2)
            }

            Spacer()

            // Folder tag
            if let folder = note.folder {
                Text(folder)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(getFolderTagColor(folder))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(getFolderTagColor(folder).opacity(0.2))
                    .cornerRadius(4)
            }

            // Date
            Text(note.modifiedAt.formatted(date: .abbreviated, time: .omitted))
                .font(.system(size: 11))
                .foregroundColor(.gray)
                .frame(width: 80, alignment: .trailing)

            // Star
            if note.isFavorite && !isTrash {
                Image(systemName: "star.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.yellow)
                    .frame(width: 20)
            } else {
                Color.clear.frame(width: 20)
            }

            // Delete button
            Button(action: {
                if isTrash {
                    showingPermanentDeleteAlert = true
                } else {
                    onDelete()
                }
            }) {
                Image(systemName: isTrash ? "trash.slash" : "trash")
                    .font(.system(size: 11))
                    .foregroundColor(isHoveringDelete ? .red : .gray.opacity(0.6))
                    .frame(width: 20)
            }
            .buttonStyle(.plain)
            .onHover { hovering in
                isHoveringDelete = hovering
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(isHovering ? Color(red: 0x1E/255, green: 0x24/255, blue: 0x2E/255) : Color.clear)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(isSelected ? Color.blue : Color.clear, lineWidth: 2)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
        .onHover { hovering in
            isHovering = hovering
        }
        .contextMenu {
            if isTrash {
                Button("Restore") {
                    onRestore()
                }
                Button("Delete Permanently", role: .destructive) {
                    showingPermanentDeleteAlert = true
                }
            } else {
                Button("Delete") {
                    onDelete()
                }
            }
        }
        .alert("Permanently Delete Note", isPresented: $showingPermanentDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete Permanently", role: .destructive) {
                onDelete()
            }
        } message: {
            Text("This note will be permanently deleted and cannot be restored. This action cannot be undone.")
        }
    }

    private func getFolderTagColor(_ folder: String) -> Color {
        switch folder.lowercased() {
        case "work": return Color(red: 0x3B/255, green: 0x82/255, blue: 0xF6/255)
        case "personal": return Color(red: 0x10/255, green: 0xB9/255, blue: 0x81/255)
        case "ideas": return Color(red: 0xA8/255, green: 0x5C/255, blue: 0xF6/255)
        default: return Color.blue
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
            // Header Bar
            HStack(spacing: 12) {
                // Close button
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                        .frame(width: 32, height: 32)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)

                Spacer()

                // Color picker
                Menu {
                    ForEach(NoteColor.allCases, id: \.self) { color in
                        Button(action: {
                            note.color = color
                            notesManager.updateNote(note)
                        }) {
                            HStack {
                                Circle()
                                    .fill(color.backgroundColor)
                                    .frame(width: 16, height: 16)
                                Text(color.rawValue.capitalized)
                                if note.color == color {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    Circle()
                        .fill(note.color.backgroundColor)
                        .frame(width: 24, height: 24)
                        .overlay(
                            Circle()
                                .strokeBorder(Color.white.opacity(0.3), lineWidth: 2)
                        )
                }
                .buttonStyle(.plain)

                // Favorite button
                Button(action: {
                    note.isFavorite.toggle()
                    notesManager.updateNote(note)
                }) {
                    Image(systemName: note.isFavorite ? "star.fill" : "star")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(note.isFavorite ? .yellow : .white.opacity(0.6))
                        .frame(width: 32, height: 32)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)

                // Folder menu
                Menu {
                    Button("No Folder") {
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
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                        .frame(width: 32, height: 32)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(Color(red: 0x1A/255, green: 0x20/255, blue: 0x2A/255))

            // Content Area
            VStack(spacing: 0) {
                // Title
                TextField("Title", text: $note.title)
                    .textFieldStyle(.plain)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 40)
                    .padding(.top, 32)
                    .padding(.bottom, 20)

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
                    textColor: Color.white.opacity(0.9),
                    onTextChange: { newText in
                        // Save with note's original color scheme (for menubar compatibility)
                        let contentWithNoteColors = applyNoteColors(newText)
                        note.attributedContent = contentWithNoteColors
                        note.modifiedAt = Date()
                        notesManager.updateNote(note)
                    }
                )
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
            }
        }
        .frame(minWidth: 800, minHeight: 600)
        .background(Color(red: 0x0F/255, green: 0x14/255, blue: 0x1A/255))
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
