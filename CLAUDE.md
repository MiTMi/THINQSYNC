# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

ThinqSync is a macOS menubar-only sticky notes application with rich text formatting and iCloud sync capability. Built with SwiftUI and AppKit integration, it lives exclusively in the menubar (no dock icon) and displays floating note windows.

## Essential Build Commands

### Build the project
```bash
xcodebuild -project thinqsync.xcodeproj -scheme thinqsync build
```

### Clean build
```bash
xcodebuild clean -project thinqsync.xcodeproj -scheme thinqsync
```

### Run tests
```bash
xcodebuild test -project thinqsync.xcodeproj -scheme thinqsync
```

### Build and run (via Xcode)
```bash
open thinqsync.xcodeproj
# Then press Cmd+R in Xcode
```

## Critical Architecture Patterns

### MenuBarExtra Rendering System

**CRITICAL**: This app uses `MenuBarExtra` which employs macOS native menu rendering, NOT standard SwiftUI rendering. This has major implications:

- Standard SwiftUI colors (`.foregroundColor(.white)`, `Color(red:green:blue:)`, etc.) **DO NOT WORK**
- Must use `Color(nsColor: .labelColor)` for proper text/icon rendering in both light and dark modes
- Never use `.preferredColorScheme()` modifiers (causes double-dark-mode rendering)
- See `MENUBAR_STYLING_GUIDE.md` for complete details

**Correct pattern for MenuBarExtra views:**
```swift
Text("Menu Item")
    .foregroundColor(Color(nsColor: .labelColor))  // ✅ Works in light & dark

Image(systemName: "icon")
    .foregroundColor(Color(nsColor: .labelColor))  // ✅ Works in light & dark
```

### State Management with @Observable

Uses Swift's modern Observation framework (`@Observable` macro):
- `NotesManager` is the single source of truth for all note data
- Injected via SwiftUI environment (`.environment(notesManager)`)
- Automatic view updates when `notes` array changes
- All manager methods must be `@MainActor` isolated

### Rich Text Architecture

Notes use `NSAttributedString` for rich text with a custom wrapper pattern:
- `AttributedStringWrapper` handles Codable serialization (NSAttributedString is not Codable)
- Serializes to RTF format, falls back to plain text
- `RichTextEditor` bridges AppKit's `NSTextView` into SwiftUI via `NSViewRepresentable`
- Formatting operations modify `NSTextStorage` directly

### Window Management

Note windows are floating and persistent:
- Uses `WindowGroup(for: UUID.self)` for parameterized windows
- Windows set to `.level = .floating` on appear
- `AppDelegate` prevents app termination when all windows close (keeps menubar icon visible)
- Window styling: `.hiddenTitleBar` with custom title bar component

## Data Model Structure

```swift
struct Note {
    id: UUID
    title: String
    contentWrapper: AttributedStringWrapper  // wraps NSAttributedString
    color: NoteColor
    isFavorite: Bool
    folder: String?
    createdAt: Date
    modifiedAt: Date
}
```

### Note Color System

Six predefined color themes (`NoteColor` enum):
- green, yellow, orange, blue, purple, white
- Each defines: backgroundColor, textColor, iconColor
- Colors adapt to note content, not system appearance

### Local Persistence

- Uses `UserDefaults` with JSON encoding
- Key: `"SavedNotes"`
- `NotesManager` handles all save/load operations
- Auto-saves on any note modification

### CloudKit Sync (Currently Disabled)

iCloud sync infrastructure exists but is disabled:
- `CloudKitSyncManager.shared` exists but not actively used
- Rich text serialization to CloudKit incomplete (loses formatting)
- Entitlements configured for CloudKit (see `thinqsync.entitlements`)
- To enable: uncomment sync code in `NotesManager.init()` and `saveNotes()`

## Project Structure

```
thinqsync/
├── Models/
│   ├── Note.swift                     # Core data model
│   ├── NoteColor.swift                # Color theme definitions
│   ├── NotesManager.swift             # State manager (Observable)
│   └── AttributedStringCodable.swift  # RTF serialization wrapper
├── Views/
│   ├── GettingStartedView.swift       # MenuBarExtra dropdown menu
│   ├── NoteWindow.swift               # Individual floating note window
│   ├── RichTextEditor.swift           # NSTextView → SwiftUI bridge
│   └── FormattingToolbar.swift        # Bold/Italic/Size controls
├── Services/
│   └── CloudKitSyncManager.swift      # CloudKit sync (disabled)
└── thinqsyncApp.swift                 # App entry + AppDelegate
```

## Key Implementation Details

### Menubar-Only Configuration

In `Info.plist`:
```xml
<key>LSUIElement</key>
<true/>
```
This hides the dock icon and makes the app menubar-only.

### Formatting Operations Pattern

All text formatting follows this pattern:
```swift
func applyFormatting() {
    guard let textView = textView,
          textView.selectedRange().length > 0 else { return }

    let range = textView.selectedRange()
    textView.textStorage?.beginEditing()
    // Modify attributes here
    textView.textStorage?.endEditing()
    textView.window?.makeFirstResponder(textView)
}
```

### Sample Notes System

`NotesManager.init()` always creates 3 demo notes on launch:
- "Demo Note" (blue)
- "Clear Derived Data" (green)
- "Overall Goals" (green)

To enable persistent storage: uncomment `loadNotes()` in init and remove `createSampleNotes()`.

## Testing Strategy

Current test coverage is minimal (template tests only):
- `thinqsyncTests/` - Unit tests (placeholder)
- `thinqsyncUITests/` - UI tests (placeholder)

When adding tests:
- Model tests: Test Note serialization, NoteColor computed properties
- Manager tests: Test CRUD operations, favorite filtering, folder grouping
- UI tests: Test note window creation, formatting toolbar, menubar interactions

## Requirements

- macOS 15.6+
- Xcode 16.0+
- Swift 5.0+
- Apple Silicon (arm64) architecture
- iCloud account (for sync feature, when enabled)

## Documentation Files

- `ARCHITECTURE_DEEP_DIVE.md` - Complete system architecture diagrams
- `MENUBAR_STYLING_GUIDE.md` - Critical MenuBarExtra styling patterns
- `PROJECT_STATUS.md` - Current feature status and version history
- `RESTORE_POINTS.md` - Git tags and revert points
- `README.md` - User-facing documentation

## Common Pitfalls

1. **MenuBarExtra Colors**: Never use explicit RGB colors or `.foregroundColor(.white)` - use `Color(nsColor: .labelColor)`
2. **Window Closing**: App must not terminate when windows close - `AppDelegate.applicationShouldTerminateAfterLastWindowClosed` returns false
3. **Rich Text Sync**: CloudKit sync loses formatting - store plain text or implement proper RTF sync
4. **Text View Focus**: After formatting, always call `textView.window?.makeFirstResponder(textView)` to restore focus
5. **Observable Updates**: NotesManager mutations must happen on `@MainActor` to trigger view updates

## Git Workflow

- Main branch: `main`
- Commit messages include Claude co-authorship footer
- Stable points tagged (e.g., `v1.0-menubar-styling-fix`)
- See `RESTORE_POINTS.md` for revert instructions
