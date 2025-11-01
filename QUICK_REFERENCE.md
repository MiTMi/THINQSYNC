# ThinqSync - Quick Reference Guide

## One-Page Overview

**What Is ThinqSync?**
A macOS menubar sticky notes app with rich text editing, local persistence, and optional iCloud sync.

**Key Stats**:
- Platform: macOS 15.6+ only
- Architecture: MVVM with @Observable
- Storage: UserDefaults (JSON)
- Cloud: CloudKit (currently disabled)
- Code: ~1,000 lines of pure SwiftUI/AppKit
- Dependencies: Zero (all native Apple frameworks)

---

## File Guide

### Models (Data Layer)
| File | Purpose | Key Class |
|------|---------|-----------|
| `Note.swift` | Note data structure | `struct Note` |
| `NoteColor.swift` | 6 color themes | `enum NoteColor` |
| `NotesManager.swift` | State container & business logic | `@Observable class` |
| `AttributedStringCodable.swift` | Rich text serialization | `struct AttributedStringWrapper` |

### Views (UI Layer)
| File | Purpose | Shows |
|------|---------|-------|
| `thinqsyncApp.swift` | App root | Menubar + note windows |
| `GettingStartedView.swift` | Menubar menu | Notes list, new note button |
| `NoteWindow.swift` | Note editor | Title bar + toolbar + editor |
| `RichTextEditor.swift` | Text input | NSTextView wrapper |
| `FormattingToolbar.swift` | Text tools | Bold, italic, size, align, lists |

### Services (Business Logic)
| File | Purpose | Status |
|------|---------|--------|
| `CloudKitSyncManager.swift` | iCloud sync | Implemented but disabled |

### Configuration
| File | Purpose |
|------|---------|
| `Info.plist` | Menubar-only configuration |
| `thinqsync.entitlements` | Sandbox & CloudKit permissions |

---

## Data Model

```swift
Note {
  id: UUID                           // Unique identifier
  title: String                      // Editable name
  attributedContent: NSAttributedString  // Rich text
  color: NoteColor                   // Green/Yellow/Orange/Blue/Purple/White
  isFavorite: Bool                   // Star status
  folder: String?                    // Organization (e.g., "Office")
  createdAt: Date                    // When created
  modifiedAt: Date                   // When last edited
}
```

---

## Architecture Diagram

```
┌─────────────────────────────────────┐
│        thinqsyncApp (@main)         │
│   Manages menubar & window scenes   │
└──────────────┬──────────────────────┘
               │
        ┌──────┴──────┐
        ▼             ▼
┌──────────────┐  ┌──────────────────────┐
│  MenuBar UI  │  │  WindowGroup (Notes) │
│ (popover)    │  │   Individual windows │
└──────────────┘  └──────────────────────┘
        │             │
        └─────┬───────┘
              ▼
    ┌─────────────────────────┐
    │   NotesManager          │
    │   (@Observable)         │
    │  • notes: [Note]        │
    │  • openNotes tracking   │
    │  • CRUD operations      │
    │  • Local save/load      │
    └──────────┬──────────────┘
               │
        ┌──────┴────────┐
        ▼               ▼
   ┌────────┐      ┌──────────────────┐
   │ Models │      │CloudKitSyncMgr   │
   │(Note)  │      │(disabled)        │
   └────────┘      └──────────────────┘
        │
   UserDefaults
```

---

## Features Summary

### Fully Working
- Create/edit/delete notes
- Local persistence
- 6 color themes
- Favorite marking
- Folder organization
- Floating windows
- Rich text editing:
  - Bold, italic, underline
  - Font size (10-24pt)
  - Alignment (left/center/right)
  - Bullet/numbered lists

### Not Implemented Yet
- iCloud sync (code exists but disabled)
- Search
- Tags
- Export
- iOS version

---

## Important Code Patterns

### 1. Adding a New Note
```swift
let note = notesManager.createNote(title: "Title", color: .blue)
```

### 2. Updating Note Content
Changes to `note.attributedContent` automatically trigger:
1. `NotesManager.updateNote(note)`
2. `saveNotes()` to UserDefaults

### 3. Accessing Notes Manager in Views
```swift
@Environment(NotesManager.self) private var notesManager
```

### 4. Opening a Note Window
```swift
@Environment(\.openWindow) private var openWindow
openWindow(value: note.id)
```

---

## Known Issues & TODO

### Bugs/Limitations
- ContentView.swift is unused (dead code)
- NoteStatusBar defined but never shown
- CloudKit sync doesn't preserve rich text (uses plain text)
- List insertion adds simple prefixes, not true list structures

### Test Coverage
- Only placeholder tests exist
- No actual test implementations

### Production Considerations
- CloudKit sync needs rich text support
- Need conflict resolution strategy
- No offline fallback
- No error UI for sync failures

---

## How to Extend

### Add a New Color
1. Add case to `NoteColor` enum
2. Add `backgroundColor`, `textColor`, `iconColor` computed properties

### Add a Formatting Option
1. Add button to `FormattingToolbar`
2. Implement private method to modify `NSTextStorage`
3. Call method from button action

### Enable iCloud Sync
1. Un-comment code in `NotesManager.init()`
2. Set iCloud container ID in entitlements
3. Fix rich text serialization (use RTF in CloudKit)
4. Test conflict resolution

---

## File Size Reference

| File | Lines | Purpose |
|------|-------|---------|
| `Note.swift` | 70 | Model |
| `NoteColor.swift` | 67 | Enum |
| `NotesManager.swift` | 215 | ViewModel |
| `AttributedStringCodable.swift` | 41 | Helper |
| `thinqsyncApp.swift` | 43 | Entry |
| `GettingStartedView.swift` | 174 | Menubar UI |
| `NoteWindow.swift` | 178 | Note UI |
| `RichTextEditor.swift` | 83 | NSView wrapper |
| `FormattingToolbar.swift` | 286 | Toolbar |
| `CloudKitSyncManager.swift` | 126 | Service |

**Total**: ~1,100 lines of Swift code

---

## Build & Run

```bash
# Open in Xcode
open /Users/michaeltouboul/Claude/thinqsync/thinqsync.xcodeproj

# Or build from command line
xcodebuild -scheme thinqsync -configuration Debug build
```

**Requirements**:
- macOS 15.6+
- Xcode 16.0+
- Swift 5.0+

---

## Contact Points for Common Tasks

### Want to modify note storage?
→ Edit `NotesManager.swift` methods: `saveNotes()`, `loadNotes()`

### Want to add a new field to notes?
→ Add property to `Note` struct

### Want to change UI appearance?
→ Edit `NoteWindow.swift` and view files

### Want to fix CloudKit sync?
→ Focus on `CloudKitSyncManager.swift` + `AttributedStringCodable.swift`

### Want to add persistence to iCloud?
→ Enable commented code in `NotesManager.init()`, fix RTF sync

---

**Last Updated**: November 1, 2025
**Version**: 1.0
**Status**: Early-stage, core features complete

