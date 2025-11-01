# ThinqSync - Architecture Deep Dive

## System Architecture

### Overall Application Flow

```
┌────────────────────────────────────────────────────────────────┐
│                        macOS System                            │
│                                                                │
│  ┌─────────────────────────────────────────────────────────┐  │
│  │              ThinqSync Application                      │  │
│  │                                                         │  │
│  │  ┌──────────────────┐         ┌──────────────────────┐ │  │
│  │  │  Menubar Scene   │         │  Window Group Scene  │ │  │
│  │  │                  │         │                      │ │  │
│  │  │ • Icon in menu   │         │ • Individual notes   │ │  │
│  │  │ • Popover menu   │         │ • Floating windows   │ │  │
│  │  └────────┬─────────┘         └──────────┬───────────┘ │  │
│  │           │                              │             │  │
│  │           └──────────┬───────────────────┘             │  │
│  │                      ▼                                  │  │
│  │       ┌──────────────────────────┐                     │  │
│  │       │   NotesManager (@Observable) │                 │  │
│  │       │                          │                     │  │
│  │       │ State:                   │                     │  │
│  │       │ • notes: [Note]          │                     │  │
│  │       │ • openNotes: tracking    │                     │  │
│  │       │ • iCloudEnabled: Bool    │                     │  │
│  │       │ • isSyncing: Bool        │                     │  │
│  │       │                          │                     │  │
│  │       │ Methods:                 │                     │  │
│  │       │ • CRUD operations        │                     │  │
│  │       │ • Sync management        │                     │  │
│  │       │ • Local save/load        │                     │  │
│  │       └──────┬───────────────────┘                     │  │
│  │              │                                         │  │
│  │    ┌─────────┼─────────┬──────────┐                   │  │
│  │    ▼         ▼         ▼          ▼                   │  │
│  │   ┌────┐  ┌─────┐  ┌──────┐  ┌─────────────┐        │  │
│  │   │Note│  │Color│  │Wrapper│ │CloudKitMgr  │        │  │
│  │   └────┘  └─────┘  └──────┘  │(disabled)   │        │  │
│  │                              └─────────────┘        │  │
│  │              ▼                                        │  │
│  │      ┌───────────────────┐                           │  │
│  │      │  UserDefaults     │                           │  │
│  │      │  (JSON storage)   │                           │  │
│  │      └───────────────────┘                           │  │
│  └─────────────────────────────────────────────────────────┘ │
└────────────────────────────────────────────────────────────────┘
```

---

## Data Layer: Models

### Note Structure

```
┌─────────────────────────────────────────┐
│           struct Note                   │
├─────────────────────────────────────────┤
│ Properties:                             │
│ ┌─────────────────────────────────────┐ │
│ │ id: UUID                            │ │
│ │ title: String                       │ │
│ │ contentWrapper: AttrStringWrapper   │ │
│ │ color: NoteColor                    │ │
│ │ isFavorite: Bool                    │ │
│ │ folder: String?                     │ │
│ │ createdAt: Date                     │ │
│ │ modifiedAt: Date                    │ │
│ └─────────────────────────────────────┘ │
│                                         │
│ Computed Properties:                    │
│ ┌─────────────────────────────────────┐ │
│ │ attributedContent: NSAttributedStr  │ │
│ │ content: String                     │ │
│ └─────────────────────────────────────┘ │
│                                         │
│ Protocols:                              │
│ • Identifiable (via id)                │
│ • Codable (JSON serialization)         │
│ • Sendable (thread-safe)               │
└─────────────────────────────────────────┘
```

### NoteColor Enum

```
┌──────────────────────────────────────────┐
│      enum NoteColor: String, Codable     │
├──────────────────────────────────────────┤
│ Cases:                                   │
│ • green     → Dark green + white text    │
│ • yellow    → Light yellow + dark text   │
│ • orange    → Light orange + dark text   │
│ • blue      → Medium blue + white text   │
│ • purple    → Medium purple + white text │
│ • white     → Light white + dark text    │
├──────────────────────────────────────────┤
│ Computed Properties:                     │
│ • backgroundColor: Color                │
│ • textColor: Color                      │
│ • iconColor: Color                      │
└──────────────────────────────────────────┘
```

---

## Presentation Layer: Views & Components

### View Hierarchy

```
thinqsyncApp (@main)
│
├─ MenuBarExtra
│  │
│  └─ GettingStartedView
│     │
│     ├─ [New Note Button]
│     ├─ [Favorites Section]
│     │  └─ ForEach(favoriteNotes)
│     │     └─ FavoriteNoteRow
│     ├─ [Notes Section]
│     │  └─ ForEach(nonFavoriteNotes)
│     │     └─ FavoriteNoteRow
│     ├─ [Office Folder]
│     ├─ [Show all Notes]
│     └─ [More Menu]
│
└─ WindowGroup(for: UUID)
   │
   └─ NoteWindow
      ├─ NoteWindowTitleBar
      │  ├─ [Color Picker Menu]
      │  └─ [Title TextField]
      ├─ FormattingToolbar
      │  ├─ [Bold]
      │  ├─ [Italic]
      │  ├─ [Underline]
      │  ├─ [Font Size Menu]
      │  ├─ [Align Buttons]
      │  └─ [List Buttons]
      └─ NoteRichTextEditor
         └─ RichTextEditor (NSViewRepresentable)
            └─ NSTextView (AppKit)
```

### RichTextEditor: Bridge Pattern

```
┌─────────────────────────────────────────────┐
│      RichTextEditor (NSViewRepresentable)   │
├─────────────────────────────────────────────┤
│ Purpose: Wrap NSTextView in SwiftUI         │
│                                             │
│ makeNSView() → NSScrollView                 │
│    └─ documentView: NSTextView              │
│       ├─ isRichText: true                  │
│       ├─ allowsUndo: true                  │
│       ├─ textColor: from note              │
│       └─ backgroundColor: clear             │
│                                             │
│ updateNSView()                              │
│    └─ Syncs attributedText binding         │
│                                             │
│ Coordinator: NSTextViewDelegate             │
│    └─ textDidChange() → onTextChange()     │
└─────────────────────────────────────────────┘
```

---

## Business Logic Layer: NotesManager

### State Management

```
┌────────────────────────────────────────────────┐
│    @MainActor @Observable NotesManager         │
├────────────────────────────────────────────────┤
│                                                │
│ ┌──────────────────────────────────────────┐  │
│ │ State Variables                          │  │
│ ├──────────────────────────────────────────┤  │
│ │ var notes: [Note] = []                   │  │
│ │ var openNotes: [UUID: Bool] = [:]        │  │
│ │ var iCloudEnabled: Bool = false          │  │
│ │ var isSyncing: Bool = false              │  │
│ └──────────────────────────────────────────┘  │
│                                                │
│ ┌──────────────────────────────────────────┐  │
│ │ Computed Properties                      │  │
│ ├──────────────────────────────────────────┤  │
│ │ var favoriteNotes: [Note]                │  │
│ │    → Filtered & sorted by modifiedAt    │  │
│ │                                          │  │
│ │ var folderNotes: [String: [Note]]        │  │
│ │    → Grouped by folder name             │  │
│ └──────────────────────────────────────────┘  │
│                                                │
│ ┌──────────────────────────────────────────┐  │
│ │ Core Methods                             │  │
│ ├──────────────────────────────────────────┤  │
│ │ func createNote() → Note                 │  │
│ │ func updateNote(_ note: Note)            │  │
│ │ func deleteNote(_ note: Note)            │  │
│ │ func toggleFavorite(_ note: Note)        │  │
│ │ func openNote(_ id: UUID)                │  │
│ │ func closeNote(_ id: UUID)               │  │
│ └──────────────────────────────────────────┘  │
│                                                │
│ ┌──────────────────────────────────────────┐  │
│ │ Persistence Methods                      │  │
│ ├──────────────────────────────────────────┤  │
│ │ private func saveNotes()                 │  │
│ │    → JSONEncoder → UserDefaults         │  │
│ │                                          │  │
│ │ private func loadNotes()                 │  │
│ │    → UserDefaults → JSONDecoder         │  │
│ └──────────────────────────────────────────┘  │
└────────────────────────────────────────────────┘
```

### Data Persistence Flow

```
Creating a Note:
┌──────────────┐
│ User clicks  │
│ "New Note"   │
└──────┬───────┘
       ▼
┌──────────────────────────────┐
│ createNote()                 │
│ • Create Note struct         │
│ • Append to notes array      │
│ • Set openNotes[id] = true   │
└──────┬───────────────────────┘
       ▼
┌──────────────────────────────┐
│ saveNotes()                  │
│ • JSONEncoder.encode(notes)  │
│ • UserDefaults.set(key)      │
└──────┬───────────────────────┘
       ▼
┌──────────────────────────────┐
│ @Observable triggers update  │
│ • All views subscribed to    │
│   notesManager refresh       │
└──────────────────────────────┘

Updating Note Content:
┌──────────────────────┐
│ User types in editor │
└──────┬───────────────┘
       ▼
┌────────────────────────────────────┐
│ RichTextEditor.Coordinator         │
│ → textDidChange()                  │
│ → onTextChange() callback          │
└──────┬─────────────────────────────┘
       ▼
┌────────────────────────────────┐
│ NoteRichTextEditor             │
│ → Update note.attributedContent│
│ → Update note.modifiedAt       │
└──────┬─────────────────────────┘
       ▼
┌────────────────────────────────┐
│ notesManager.updateNote(note)  │
└──────┬─────────────────────────┘
       ▼
┌────────────────────────────────┐
│ saveNotes()                    │
│ → UserDefaults persistence    │
└────────────────────────────────┘
```

---

## Service Layer: CloudKit Integration

### CloudKitSyncManager Structure

```
┌──────────────────────────────────────────────┐
│    @MainActor CloudKitSyncManager            │
├──────────────────────────────────────────────┤
│                                              │
│ Properties:                                  │
│ • container: CKContainer.default()           │
│ • privateDatabase: CKDatabase               │
│ • recordType: "Note"                        │
│                                              │
│ Core Methods:                                │
│ • checkAccountStatus() → Bool               │
│ • syncNotes([Note])                         │
│ • fetchAllNotes() → [Note]                  │
│ • saveNote(Note)                            │
│ • deleteNote(UUID)                          │
│                                              │
│ Helper Methods:                              │
│ • recordFromNote(Note) → CKRecord           │
│ • noteFromRecord(CKRecord) → Note?          │
│ • deleteAllRecords()                        │
│                                              │
│ Status: DISABLED (incomplete implementation)│
│ Issue: Rich text not synced (plain text)   │
└──────────────────────────────────────────────┘
```

### CloudKit Schema (Planned)

```
┌────────────────────────────────────┐
│      CloudKit "Note" Record        │
├────────────────────────────────────┤
│ title            (CKRecordValue)   │
│ content          (CKRecordValue)   │
│ color            (CKRecordValue)   │
│ isFavorite       (CKRecordValue)   │
│ folder           (CKRecordValue)   │
│ createdAt        (CKRecordValue)   │
│ modifiedAt       (CKRecordValue)   │
└────────────────────────────────────┘

⚠️ Known Issues:
• Rich text attributes lost
• Uses plain text for content
• Simple delete-all/sync-all strategy
• No conflict resolution
• Currently disabled
```

---

## Text Formatting Architecture

### FormattingToolbar Operations

```
┌─────────────────────────────────────────────┐
│       FormattingToolbar                     │
├─────────────────────────────────────────────┤
│                                             │
│ Text Formatting                             │
│ ├─ toggleBold()                             │
│ │  └─ NSFontManager.convert(font, trait)  │
│ ├─ toggleItalic()                           │
│ │  └─ NSFontManager.convert(font, trait)  │
│ └─ toggleUnderline()                        │
│    └─ NSTextStorage.addAttribute()         │
│                                             │
│ Font Control                                │
│ └─ setFontSize(CGFloat)                    │
│    └─ NSFont(name:, size:)                 │
│                                             │
│ Paragraph Formatting                        │
│ ├─ setAlignment(NSTextAlignment)           │
│ ├─ insertBulletList()                       │
│ └─ insertNumberedList()                     │
│                                             │
│ Implementation Pattern:                      │
│ 1. Get selected range from NSTextView       │
│ 2. Verify selection not empty               │
│ 3. Get textStorage for modification         │
│ 4. beginEditing() → modify → endEditing()  │
│ 5. NSView.window?.makeFirstResponder()     │
└─────────────────────────────────────────────┘
```

### Rich Text Serialization

```
┌──────────────────────────────────────────┐
│   AttributedStringWrapper                │
├──────────────────────────────────────────┤
│                                          │
│ Serialization (NSAttributedString → Data)│
│ • Primary: RTF format (.documentType)    │
│ • Fallback: UTF-8 plain text             │
│ • Preserves: bold, italic, underline,   │
│             size, color, alignment       │
│                                          │
│ Deserialization (Data → NSAttributedString)
│ • Attempt RTF decode                     │
│ • Fallback: Plain text                   │
│                                          │
│ Why Needed:                              │
│ • NSAttributedString not Codable         │
│ • Need Codable for JSON storage          │
│ • UserDefaults requires Codable          │
└──────────────────────────────────────────┘
```

---

## State Flow Diagram

### @Observable Reactivity

```
User Action (e.g., type text)
        ↓
NSTextView.textDidChange()
        ↓
RichTextEditor.Coordinator callback
        ↓
onTextChange() function
        ↓
note.attributedContent = newValue
        ↓
notesManager.updateNote(note)
        ↓
notesManager.notes[index] = updated note
        ↓
@Observable detects property change
        ↓
All subscribed views refresh automatically
        ↓
UI updates (re-renders affected views)


Adding/Deleting Notes:
notesManager.notes array modified
        ↓
@Observable triggers change notification
        ↓
GettingStartedView:
├─ favoriteNotes computed property re-evaluated
├─ folderNotes computed property re-evaluated
└─ UI lists refresh automatically

Opening/Closing Windows:
notesManager.openNotes dictionary modified
        ↓
@Observable triggers update
        ↓
Views monitoring openNotes state refresh
```

---

## Configuration & Entitlements

### App Configuration (Info.plist)

```
LSUIElement = true
├─ Removes dock icon
├─ App lives in menubar only
└─ Requires restart to take effect
```

### Sandbox & CloudKit (Entitlements)

```
App Sandbox
├─ com.apple.security.app-sandbox = true
└─ Required for App Store

Network Access
├─ com.apple.security.network.client = true
└─ Required for CloudKit

CloudKit Services
├─ com.apple.developer.icloud-services = [CloudKit]
├─ com.apple.developer.aps-environment = development
└─ com.apple.developer.icloud-container-identifiers = []
   (empty - needs setup for actual sync)
```

---

## Dependency Injection Strategy

### Environment-Based DI

```
Views access NotesManager via SwiftUI Environment:

���──────────────────────────────────────────┐
│          thinqsyncApp                    │
│                                          │
│ @State private var notesManager          │
│                                          │
│ MenuBarExtra {                           │
│   GettingStartedView()                   │
│     .environment(notesManager)           │
│ }                                        │
│                                          │
│ WindowGroup {                            │
│   NoteWindow()                           │
│     .environment(notesManager)           │
│ }                                        │
└──────────────────────────────────────────┘
        ↓
┌──────────────────────────────────────────┐
│        Any Child View                    │
│                                          │
│ @Environment(NotesManager.self) var nm   │
│                                          │
│ Usage:                                   │
│ • nm.createNote()                        │
│ • nm.updateNote()                        │
│ • nm.notes (binding via @Observable)    │
└──────────────────────────────────────────┘
```

---

## Testing Architecture

### Current Test Status

```
Unit Tests: thinqsyncTests
├─ Test Framework: Swift Testing
├─ Status: Placeholder only
└─ Needs: Model tests, manager tests

UI Tests: thinqsyncUITests
├─ Test Framework: XCTest
├─ Status: Placeholder only
└─ Needs: Flow tests, window tests

Coverage: ~0% (template tests)
```

---

## Window Management

### Floating Window Behavior

```
┌──────────────────────────────────────────┐
│       NoteWindow Component               │
├──────────────────────────────────────────┤
│                                          │
│ onAppear {                               │
│   setWindowFloating()                    │
│ }                                        │
│                                          │
│ setWindowFloating() {                    │
│   for window in NSApp.windows {          │
│     window.level = .floating             │
│     window.collectionBehavior = [        │
│       .canJoinAllSpaces,                 │
│       .fullScreenAuxiliary               │
│     ]                                    │
│   }                                      │
│ }                                        │
│                                          │
│ Monitoring: Registers for               │
│ NSWindow.didBecomeKeyNotification        │
│ to maintain floating status              │
└──────────────────────────────────────────┘
```

---

**Architecture Diagram Generated**: November 1, 2025
**For**: ThinqSync v1.0
**Scope**: Complete system architecture overview

