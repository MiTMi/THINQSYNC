//
//  thinqsyncApp.swift
//  thinqsync
//
//  Created by Michael   on 31/10/2025.
//

import SwiftUI
import AppKit

// Custom AppDelegate to prevent app termination when all windows close
class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // Return false to keep the app running even when all windows are closed
        // This keeps the menubar icon visible
        return false
    }
}

@main
struct thinqsyncApp: App {
    @State private var notesManager = NotesManager()
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // Menubar icon with popover menu
        MenuBarExtra {
            GettingStartedView()
                .environment(notesManager)
        } label: {
            Image(systemName: "note.text")
        }

        // Window group for individual notes
        WindowGroup(for: UUID.self) { $noteID in
            if let noteID = noteID,
               let index = notesManager.notes.firstIndex(where: { $0.id == noteID }) {
                NoteWindow(note: $notesManager.notes[index])
                    .environment(notesManager)
                    .frame(minWidth: 300, minHeight: 200)
                    .ignoresSafeArea(.all)
            }
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.automatic)
        .defaultSize(width: 400, height: 300)
    }
}
