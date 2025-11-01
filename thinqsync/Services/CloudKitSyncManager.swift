//
//  CloudKitSyncManager.swift
//  thinqsync
//
//  Created by Michael   on 31/10/2025.
//

import Foundation
import CloudKit

@MainActor
class CloudKitSyncManager {
    static let shared = CloudKitSyncManager()

    private let container: CKContainer
    private let privateDatabase: CKDatabase
    private let recordType = "Note"

    private init() {
        container = CKContainer.default()
        privateDatabase = container.privateCloudDatabase
    }

    // MARK: - Account Status

    func checkAccountStatus() async throws -> Bool {
        let status = try await container.accountStatus()
        return status == .available
    }

    // MARK: - Sync Notes

    func syncNotes(_ notes: [Note]) async throws {
        // Delete all existing records first (simple approach)
        // In production, you'd want a more sophisticated sync strategy
        try await deleteAllRecords()

        // Upload all notes
        for note in notes {
            try await saveNote(note)
        }
    }

    func fetchAllNotes() async throws -> [Note] {
        let query = CKQuery(recordType: recordType, predicate: NSPredicate(value: true))
        let (results, _) = try await privateDatabase.records(matching: query)

        var notes: [Note] = []
        for (_, result) in results {
            switch result {
            case .success(let record):
                if let note = noteFromRecord(record) {
                    notes.append(note)
                }
            case .failure(let error):
                print("Error fetching record: \(error)")
            }
        }

        return notes
    }

    // MARK: - Individual Operations

    func saveNote(_ note: Note) async throws {
        let record = recordFromNote(note)
        try await privateDatabase.save(record)
    }

    func deleteNote(_ noteID: UUID) async throws {
        let recordID = CKRecord.ID(recordName: noteID.uuidString)
        try await privateDatabase.deleteRecord(withID: recordID)
    }

    // MARK: - Helper Methods

    private func deleteAllRecords() async throws {
        let query = CKQuery(recordType: recordType, predicate: NSPredicate(value: true))
        let (results, _) = try await privateDatabase.records(matching: query)

        for (recordID, _) in results {
            _ = try? await privateDatabase.deleteRecord(withID: recordID)
        }
    }

    private func recordFromNote(_ note: Note) -> CKRecord {
        let recordID = CKRecord.ID(recordName: note.id.uuidString)
        let record = CKRecord(recordType: recordType, recordID: recordID)

        record["title"] = note.title as CKRecordValue
        record["content"] = note.content as CKRecordValue
        record["color"] = note.color.rawValue as CKRecordValue
        record["isFavorite"] = note.isFavorite as CKRecordValue
        record["folder"] = (note.folder ?? "") as CKRecordValue
        record["createdAt"] = note.createdAt as CKRecordValue
        record["modifiedAt"] = note.modifiedAt as CKRecordValue

        return record
    }

    private func noteFromRecord(_ record: CKRecord) -> Note? {
        guard let id = UUID(uuidString: record.recordID.recordName),
              let title = record["title"] as? String,
              let content = record["content"] as? String,
              let colorString = record["color"] as? String,
              let color = NoteColor(rawValue: colorString),
              let isFavorite = record["isFavorite"] as? Bool,
              let createdAt = record["createdAt"] as? Date,
              let modifiedAt = record["modifiedAt"] as? Date else {
            return nil
        }

        let folder = record["folder"] as? String
        return Note(
            id: id,
            title: title,
            content: content,
            color: color,
            isFavorite: isFavorite,
            folder: folder?.isEmpty == false ? folder : nil,
            createdAt: createdAt,
            modifiedAt: modifiedAt
        )
    }
}
