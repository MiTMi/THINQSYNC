//
//  NotesManager.swift
//  thinqsync
//
//  Created by Michael   on 31/10/2025.
//

import Foundation
import SwiftUI
import Observation

@MainActor
@Observable
class NotesManager {
    private var _allNotes: [Note] = []
    var openNotes: [UUID: Bool] = [:]
    var iCloudEnabled: Bool = false
    var isSyncing: Bool = false

    private let saveKey = "SavedNotes"
    private let cloudSync = CloudKitSyncManager.shared

    // Public computed property that filters out deleted notes
    var notes: [Note] {
        _allNotes.filter { $0.deletedAt == nil }
    }

    // Trash: deleted notes
    var deletedNotes: [Note] {
        _allNotes.filter { $0.deletedAt != nil }.sorted { ($0.deletedAt ?? Date()) > ($1.deletedAt ?? Date()) }
    }

    init() {
        // Load saved notes from UserDefaults
        loadNotes()

        // If no saved notes exist, create sample notes (only if not using iCloud)
        if _allNotes.isEmpty {
            createSampleNotes()
        }

        // Check iCloud status and sync on app launch
        Task {
            await checkiCloudStatus()
        }
    }

    var favoriteNotes: [Note] {
        notes.filter { $0.isFavorite }.sorted { $0.modifiedAt > $1.modifiedAt }
    }

    var folderNotes: [String: [Note]] {
        var folders: [String: [Note]] = [:]
        for note in notes {
            if let folder = note.folder {
                folders[folder, default: []].append(note)
            }
        }
        return folders
    }

    func createNote(title: String = "", color: NoteColor = .yellow) -> Note {
        let note = Note(title: title, color: color)
        _allNotes.append(note)
        openNotes[note.id] = true
        saveNotes()
        return note
    }

    func updateNote(_ note: Note) {
        if let index = _allNotes.firstIndex(where: { $0.id == note.id }) {
            _allNotes[index] = note
            saveNotes()
        }
    }

    // Soft delete: move to trash
    func deleteNote(_ note: Note) {
        if let index = _allNotes.firstIndex(where: { $0.id == note.id }) {
            _allNotes[index].deletedAt = Date()
            openNotes.removeValue(forKey: note.id)
            saveNotes()
        }
    }

    // Restore note from trash
    func restoreNote(_ note: Note) {
        if let index = _allNotes.firstIndex(where: { $0.id == note.id }) {
            _allNotes[index].deletedAt = nil
            saveNotes()
        }
    }

    // Permanently delete note
    func permanentlyDeleteNote(_ note: Note) {
        _allNotes.removeAll { $0.id == note.id }
        openNotes.removeValue(forKey: note.id)
        saveNotes()
    }

    // Empty trash - permanently delete all deleted notes
    func emptyTrash() {
        _allNotes.removeAll { $0.deletedAt != nil }
        saveNotes()
    }

    func toggleFavorite(_ note: Note) {
        if let index = _allNotes.firstIndex(where: { $0.id == note.id }) {
            _allNotes[index].isFavorite.toggle()
            saveNotes()
        }
    }

    func isNoteOpen(_ id: UUID) -> Bool {
        openNotes[id] ?? false
    }

    func openNote(_ id: UUID) {
        openNotes[id] = true
    }

    func closeNote(_ id: UUID) {
        openNotes[id] = false
    }

    // Get note by ID (including deleted notes)
    func getNote(by id: UUID) -> Note? {
        _allNotes.first(where: { $0.id == id })
    }

    // Get binding to note by ID
    func binding(for id: UUID) -> Binding<Note>? {
        guard let index = _allNotes.firstIndex(where: { $0.id == id }) else {
            return nil
        }
        return Binding(
            get: { [weak self] in self?._allNotes[index] ?? Note() },
            set: { [weak self] newValue in
                guard let self = self else { return }
                if index < self._allNotes.count {
                    self._allNotes[index] = newValue
                    self.saveNotes()
                }
            }
        )
    }

    private func saveNotes() {
        if let encoded = try? JSONEncoder().encode(_allNotes) {
            UserDefaults.standard.set(encoded, forKey: saveKey)
        }

        // Auto-sync to iCloud after saving locally
        if iCloudEnabled {
            Task {
                await syncToiCloud()
            }
        }
    }

    private func loadNotes() {
        if let savedNotes = UserDefaults.standard.data(forKey: saveKey),
           let decodedNotes = try? JSONDecoder().decode([Note].self, from: savedNotes) {
            _allNotes = decodedNotes
        }
    }

    private func createSampleNotes() {
        // Create exactly 3 demo notes as shown in the screenshot
        let note1 = Note(
            title: "Demo Note",
            content: "This is a demo note to show the functionality of ThinqSync",
            color: .blue,
            isFavorite: false
        )

        let note2 = Note(
            title: "Clear Derived Data",
            content: "rm -rf ~/Library/Developer/Xcode/DerivedData",
            color: .green,
            isFavorite: false
        )

        let note3 = Note(
            title: "Overall Goals",
            content: "1. Build amazing apps\n2. Learn new technologies\n3. Help users be productive",
            color: .green,
            isFavorite: false
        )

        _allNotes = [note1, note2, note3]
        saveNotes()
    }

    // MARK: - iCloud Sync

    private func checkiCloudStatus() async {
        do {
            iCloudEnabled = try await cloudSync.checkAccountStatus()
            if iCloudEnabled {
                // Initialize CloudKit schema if needed (first-time setup)
                try await cloudSync.initializeSchema()
                // Then sync notes
                await syncFromiCloud()
            }
        } catch {
            print("iCloud check failed: \(error)")
            iCloudEnabled = false
        }
    }

    func syncToiCloud() async {
        guard iCloudEnabled, !isSyncing else { return }
        isSyncing = true

        do {
            try await cloudSync.syncNotes(notes)
            print("Synced \(notes.count) notes to iCloud")
        } catch {
            print("Sync to iCloud failed: \(error)")
        }

        isSyncing = false
    }

    func syncFromiCloud() async {
        guard iCloudEnabled, !isSyncing else { return }
        isSyncing = true

        do {
            let cloudNotes = try await cloudSync.fetchAllNotes()
            if !cloudNotes.isEmpty {
                _allNotes = cloudNotes
                // Save to local storage (without triggering another iCloud sync)
                if let encoded = try? JSONEncoder().encode(_allNotes) {
                    UserDefaults.standard.set(encoded, forKey: saveKey)
                }
                print("Loaded \(cloudNotes.count) notes from iCloud")
            }
        } catch {
            print("Sync from iCloud failed: \(error)")
        }

        isSyncing = false
    }

    func toggleiCloudSync() async {
        if iCloudEnabled {
            // Disable sync
            iCloudEnabled = false
        } else {
            // Enable sync
            await checkiCloudStatus()
            if iCloudEnabled {
                await syncToiCloud()
            }
        }
    }
}
