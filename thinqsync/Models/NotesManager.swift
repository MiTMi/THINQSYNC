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
    var notes: [Note] = []
    var openNotes: [UUID: Bool] = [:]
    var iCloudEnabled: Bool = false
    var isSyncing: Bool = false

    private let saveKey = "SavedNotes"
    private let cloudSync = CloudKitSyncManager.shared

    init() {
        // Always start fresh with demo notes
        // Comment out loadNotes() to always show demo notes
        // loadNotes()

        // Always create sample notes for demo
        createSampleNotes()

        // iCloud disabled for now - focusing on local storage
        // Task {
        //     await checkiCloudStatus()
        // }
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

    func createNote(title: String = "NewDemo", color: NoteColor = .green) -> Note {
        let note = Note(title: title, color: color)
        notes.append(note)
        openNotes[note.id] = true
        saveNotes()
        return note
    }

    func updateNote(_ note: Note) {
        if let index = notes.firstIndex(where: { $0.id == note.id }) {
            notes[index] = note
            saveNotes()
        }
    }

    func deleteNote(_ note: Note) {
        notes.removeAll { $0.id == note.id }
        openNotes.removeValue(forKey: note.id)
        saveNotes()
    }

    func toggleFavorite(_ note: Note) {
        if let index = notes.firstIndex(where: { $0.id == note.id }) {
            notes[index].isFavorite.toggle()
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

    private func saveNotes() {
        if let encoded = try? JSONEncoder().encode(notes) {
            UserDefaults.standard.set(encoded, forKey: saveKey)
        }

        // iCloud sync disabled for now
        // if iCloudEnabled {
        //     Task {
        //         await syncToiCloud()
        //     }
        // }
    }

    private func loadNotes() {
        if let savedNotes = UserDefaults.standard.data(forKey: saveKey),
           let decodedNotes = try? JSONDecoder().decode([Note].self, from: savedNotes) {
            notes = decodedNotes
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

        notes = [note1, note2, note3]
        saveNotes()
    }

    // MARK: - iCloud Sync

    private func checkiCloudStatus() async {
        do {
            iCloudEnabled = try await cloudSync.checkAccountStatus()
            if iCloudEnabled {
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
                notes = cloudNotes
                saveNotes()
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
