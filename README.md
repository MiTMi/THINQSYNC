# ThinqSync - macOS Sticky Notes App

A beautiful, feature-rich macOS sticky notes application with formatting support and iCloud sync.

## Features

### Core Functionality
- **Menubar-only app** - Lightweight app that lives in your menubar (no dock icon)
- **Beautiful note colors** - 6 color themes: Green, Yellow, Orange, Blue, Purple, and White
- **Favorites system** - Quick access to your most important notes
- **Folders** - Organize notes into folders (e.g., "Office")
- **Local persistence** - Notes are automatically saved locally

### Text Formatting
- **Rich text editing** - Full NSAttributedString support
- **Bold, Italic, Underline** - Standard text formatting options
- **Font size control** - Choose from 10pt to 24pt
- **Text alignment** - Left, center, and right alignment
- **Lists** - Bullet and numbered list support
- **Formatting toolbar** - Easy-to-use toolbar at the top of each note

### iCloud Sync
- **Automatic sync** - Notes sync automatically to iCloud when enabled
- **Cross-device** - Access your notes on any Mac signed into the same iCloud account
- **CloudKit integration** - Secure and private cloud storage

## Getting Started

### Installation
1. Open the project in Xcode
2. Build and run (Cmd+R)
3. The app will appear in your menubar

### Usage

#### Creating Notes
1. Click the menubar icon
2. Click "New Note"
3. A new note window will appear
4. Start typing!

#### Formatting Text
1. Select text in a note
2. Use the formatting toolbar:
   - **B** - Make text bold
   - **I** - Make text italic
   - **U** - Underline text
   - **Size** - Change font size
   - **Align** - Change text alignment
   - **Lists** - Add bullet or numbered lists

#### Changing Note Color
1. Click the dropdown arrow (▼) in the note's title bar
2. Select your desired color
3. The note background and text color will update automatically

#### Organizing Notes
- **Favorites**: Click the star icon to mark a note as favorite
- **Folders**: Assign notes to folders for better organization
- **Rename**: Click the title field to rename a note

#### iCloud Sync
- iCloud sync is automatically enabled if you're signed into iCloud
- Notes sync when:
  - You create a new note
  - You edit an existing note
  - You delete a note
  - The app launches

## Project Structure

```
thinqsync/
├── Models/
│   ├── Note.swift                     # Note data model
│   ├── NoteColor.swift                # Color theme definitions
│   ├── NotesManager.swift             # Main data manager
│   └── AttributedStringCodable.swift  # Rich text storage
├── Views/
│   ├── GettingStartedView.swift       # Menubar popup view
│   ├── NoteWindow.swift               # Individual note window
│   ├── RichTextEditor.swift           # NSTextView wrapper
│   └── FormattingToolbar.swift        # Text formatting controls
├── Services/
│   └── CloudKitSyncManager.swift      # iCloud sync logic
└── Info.plist                         # Menubar-only configuration
```

## Technical Details

### Architecture
- **SwiftUI** - Modern UI framework
- **Observation Framework** - New Swift observation system (@Observable)
- **CloudKit** - Apple's cloud database service
- **NSTextView** - Native AppKit rich text editing
- **UserDefaults** - Local data persistence

### Data Model
Notes are stored with the following properties:
- `id` - Unique identifier (UUID)
- `title` - Note title
- `attributedContent` - Rich text content (NSAttributedString)
- `color` - Theme color
- `isFavorite` - Favorite status
- `folder` - Optional folder name
- `createdAt` - Creation timestamp
- `modifiedAt` - Last modification timestamp

### Sync Strategy
- **Local-first**: All notes are saved locally first
- **Background sync**: iCloud sync happens automatically in the background
- **Simple conflict resolution**: Last modified wins
- **Automatic retry**: Failed syncs are retried automatically

## Requirements
- macOS 15.6 or later
- Xcode 16.0 or later
- Swift 5.0 or later
- iCloud account (for sync feature)

## Notes for Developers

### Enabling iCloud in Xcode
1. Open the project in Xcode
2. Select the thinqsync target
3. Go to "Signing & Capabilities"
4. Click "+ Capability" and add "iCloud"
5. Check "CloudKit"
6. The entitlements file is already configured

### Customization
- **Colors**: Edit `NoteColor.swift` to add or modify color themes
- **Sync interval**: Modify `CloudKitSyncManager.swift` for custom sync behavior
- **Sample notes**: Edit `createSampleNotes()` in `NotesManager.swift`

## Known Limitations
- No image support (text only)
- Simple conflict resolution (last write wins)
- No note sharing between users
- macOS only (no iOS/iPadOS support yet)

## Future Enhancements
- [ ] Note sharing with other users
- [ ] Note templates
- [ ] Search functionality
- [ ] Tags system
- [ ] Export notes to PDF/Markdown
- [ ] iOS and iPadOS versions
- [ ] Widgets for quick note access
- [ ] Keyboard shortcuts customization

## License
Private project - All rights reserved

## Support
For issues or questions, please contact the development team.

---

Built with ❤️ for macOS
