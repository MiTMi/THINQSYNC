//
//  NotesManager.swift
//  thinqsync
//
//  Created by Michael   on 31/10/2025.
//

import Foundation
import SwiftUI
import Observation
import os

private let logger = Logger(subsystem: "com.MIT.thinqsync", category: "NotesManager")

@MainActor
@Observable
class NotesManager {
    private var _allNotes: [Note] = [] {
        didSet { invalidateCache() }
    }
    var openNotes: [UUID: Bool] = [:]
    var iCloudEnabled: Bool = false
    var isSyncing: Bool = false
    var folders: [String] = []

    private let saveKey = "SavedNotes"
    private let foldersKey = "SavedFolders"
    private let cloudSync = CloudKitSyncManager.shared
    private var debouncedSaveTask: DispatchWorkItem?
    // iCloud sync uses a much longer debounce (10s) to avoid blocking the UI
    // during frequent note edits/scrolling.
    private var debouncedSyncTask: DispatchWorkItem?

    // Cached filtered lists, invalidated when _allNotes changes
    private var _cachedNotes: [Note]?
    private var _cachedDeletedNotes: [Note]?

    private func invalidateCache() {
        _cachedNotes = nil
        _cachedDeletedNotes = nil
    }

    var notes: [Note] {
        if let cached = _cachedNotes { return cached }
        let result = _allNotes.filter { $0.deletedAt == nil }
        _cachedNotes = result
        return result
    }

    var deletedNotes: [Note] {
        if let cached = _cachedDeletedNotes { return cached }
        let result = _allNotes.filter { $0.deletedAt != nil }.sorted { ($0.deletedAt ?? Date()) > ($1.deletedAt ?? Date()) }
        _cachedDeletedNotes = result
        return result
    }

    init() {
        // Load saved notes and folders from UserDefaults
        loadNotes()
        loadFolders()

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

    var availableFolders: [String] {
        // Combine explicitly created folders with folders that have notes
        let foldersWithNotes = Set(notes.compactMap { $0.folder })
        return Array(Set(folders).union(foldersWithNotes)).sorted()
    }

    func createNote(title: String = "", color: NoteColor = .yellow, folder: String? = nil) -> Note {
        var note = Note(title: title, color: color)
        note.folder = folder
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
            saveNotesImmediately()
        }
    }

    // Restore note from trash
    func restoreNote(_ note: Note) {
        if let index = _allNotes.firstIndex(where: { $0.id == note.id }) {
            _allNotes[index].deletedAt = nil
            saveNotesImmediately()
        }
    }

    // Permanently delete note
    func permanentlyDeleteNote(_ note: Note) {
        _allNotes.removeAll { $0.id == note.id }
        openNotes.removeValue(forKey: note.id)
        saveNotesImmediately()
    }

    // Empty trash - permanently delete all deleted notes
    func emptyTrash() {
        _allNotes.removeAll { $0.deletedAt != nil }
        saveNotesImmediately()
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

    // MARK: - Folder Management

    func createFolder(_ name: String) {
        guard !name.isEmpty && !folders.contains(name) else { return }
        folders.append(name)
        folders.sort()
        saveFolders()
    }

    func deleteFolder(_ name: String) {
        folders.removeAll { $0 == name }
        // Remove folder assignment from all notes in this folder
        for index in _allNotes.indices {
            if _allNotes[index].folder == name {
                _allNotes[index].folder = nil
            }
        }
        saveFolders()
        saveNotes()
    }

    func renameFolder(from oldName: String, to newName: String) {
        guard !newName.isEmpty && oldName != newName else { return }
        if let index = folders.firstIndex(of: oldName) {
            folders[index] = newName
            folders.sort()
        }
        // Update folder assignment in all notes
        for index in _allNotes.indices {
            if _allNotes[index].folder == oldName {
                _allNotes[index].folder = newName
            }
        }
        saveFolders()
        saveNotes()
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
        debouncedSaveTask?.cancel()
        let task = DispatchWorkItem { [weak self] in
            guard let self else { return }
            Task { @MainActor in
                self.performSave()
            }
        }
        debouncedSaveTask = task
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: task)

        // Schedule iCloud sync on a separate long debounce (10s) so frequent
        // edits don't trigger sync on every keystroke and block scrolling.
        scheduleCloudSync()
    }

    private func scheduleCloudSync() {
        guard iCloudEnabled else { return }
        debouncedSyncTask?.cancel()
        let task = DispatchWorkItem { [weak self] in
            guard let self else { return }
            Task { @MainActor in
                await self.syncToiCloud()
            }
        }
        debouncedSyncTask = task
        DispatchQueue.main.asyncAfter(deadline: .now() + 10.0, execute: task)
    }

    private func saveNotesImmediately() {
        debouncedSaveTask?.cancel()
        performSave()
    }

    private func performSave() {
        // Capture the notes array for background encoding
        let notesToSave = _allNotes
        let key = saveKey

        // Move heavy JSON encoding off the main thread to avoid blocking scrolling/UI
        Task.detached(priority: .utility) {
            let encoded = try? JSONEncoder().encode(notesToSave)
            await MainActor.run {
                if let encoded {
                    UserDefaults.standard.set(encoded, forKey: key)
                }
            }
        }
    }

    private func loadNotes() {
        if let savedNotes = UserDefaults.standard.data(forKey: saveKey),
           let decodedNotes = try? JSONDecoder().decode([Note].self, from: savedNotes) {
            _allNotes = decodedNotes
        }
    }

    private func saveFolders() {
        if let encoded = try? JSONEncoder().encode(folders) {
            UserDefaults.standard.set(encoded, forKey: foldersKey)
        }
    }

    private func loadFolders() {
        if let savedFolders = UserDefaults.standard.data(forKey: foldersKey),
           let decodedFolders = try? JSONDecoder().decode([String].self, from: savedFolders) {
            folders = decodedFolders
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
            logger.error("iCloud check failed: \(error.localizedDescription, privacy: .public)")
            iCloudEnabled = false
        }
    }

    func syncToiCloud() async {
        guard iCloudEnabled, !isSyncing else { return }
        isSyncing = true

        do {
            try await cloudSync.syncNotes(notes)
            logger.info("Synced \(self.notes.count) notes to iCloud")
        } catch {
            logger.error("Sync to iCloud failed: \(error.localizedDescription, privacy: .public)")
        }

        isSyncing = false
    }

    func syncFromiCloud() async {
        guard iCloudEnabled, !isSyncing else { return }
        isSyncing = true

        do {
            let cloudNotes = try await cloudSync.fetchAllNotes()
            if !cloudNotes.isEmpty {
                // Merge cloud notes with local notes instead of overwriting
                let localByID = Dictionary(uniqueKeysWithValues: _allNotes.map { ($0.id, $0) })
                let cloudByID = Dictionary(uniqueKeysWithValues: cloudNotes.map { ($0.id, $0) })

                var merged: [Note] = []

                // All known IDs from both sources
                let allIDs = Set(localByID.keys).union(cloudByID.keys)

                for id in allIDs {
                    let local = localByID[id]
                    let cloud = cloudByID[id]

                    switch (local, cloud) {
                    case let (.some(l), .some(c)):
                        // Both exist — keep the one with the newer modifiedAt
                        merged.append(l.modifiedAt >= c.modifiedAt ? l : c)
                    case let (.some(l), .none):
                        // Local only — keep it (will sync up on next save)
                        merged.append(l)
                    case let (.none, .some(c)):
                        // Cloud only — add it
                        merged.append(c)
                    case (.none, .none):
                        break
                    }
                }

                _allNotes = merged
                // Save to local storage (without triggering another iCloud sync)
                if let encoded = try? JSONEncoder().encode(_allNotes) {
                    UserDefaults.standard.set(encoded, forKey: saveKey)
                }
                logger.info("Merged \(cloudNotes.count) cloud notes with \(localByID.count) local notes, \(merged.count) total")
            }
        } catch {
            logger.error("Sync from iCloud failed: \(error.localizedDescription, privacy: .public)")
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
