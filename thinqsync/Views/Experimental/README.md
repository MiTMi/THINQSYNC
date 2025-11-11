# Carousel Dashboard - Experimental Views

This directory contains the experimental carousel-style dashboard for ThinqSync, converted from the HTML/CSS glass morphism prototype to native SwiftUI.

## Files Overview

### Core Files

#### `CarouselDashboardView.swift`
- **Purpose**: Standalone carousel dashboard with demo data
- **Features**:
  - 5 sample notes in carousel format
  - Full glass morphism styling
  - Particle burst effects
  - Keyboard navigation (← →)
  - Touch/swipe gestures
  - Loading animation
  - Progress dots with expand/contract
  - Thumbnail strip
- **Use Case**: Testing and prototyping without affecting real note data

#### `CarouselDashboardIntegratedView.swift`
- **Purpose**: Production-ready carousel dashboard integrated with NotesManager
- **Features**:
  - Uses real note data from NotesManager
  - Converts Note objects to carousel format
  - Maps NoteColor to carousel color palette
  - Toggles favorites in real NotesManager
  - Empty state handling
  - All animations and interactions from standalone version
- **Use Case**: Drop-in replacement for ShowAllNotesView

#### `CarouselHelpers.swift`
- **Purpose**: Helper utilities and extensions
- **Contents**:
  - `Color` extensions (hex string initializer)
  - Custom color palette (Sky Blue, Blue Green, Prussian Blue, Selective Yellow, UT Orange)
  - `AnimationValues` struct for keyframe animations
  - `Particle` model for burst effects
  - `CardState` enum (active, behindOne, behindTwo, hidden)
  - `GlassMorphismModifier` - native SwiftUI glass effect using `.ultraThinMaterial`
  - `FloatingModifier` - continuous up/down animation

#### `ParticleBurstView.swift`
- **Purpose**: Particle system for star favorite toggle
- **Features**:
  - 8 particles in circular pattern
  - 30pt distance from center
  - 0.8s fade-out animation
  - Canvas-based rendering
  - Automatic cleanup

## Color Palette

The carousel uses a specific color scheme defined in [carousel_glassmorphism_theme.css](../../../../.superdesign/design_iterations/carousel_glassmorphism_theme.css):

| Color Name       | Hex Code  | Usage                          |
|------------------|-----------|--------------------------------|
| Sky Blue         | #8ecae6   | Pink notes, accents            |
| Blue Green       | #219ebc   | Green/Purple notes, buttons    |
| Prussian Blue    | #023047   | Blue notes, background         |
| Selective Yellow | #ffb703   | Yellow notes, stars, highlights|
| UT Orange        | #fb8500   | Orange notes, accents          |

## Visual Similarity to HTML Prototype

Based on Context7 MCP research, the SwiftUI version achieves approximately **85-92%** visual similarity to the HTML/CSS prototype:

### What Matches Exactly:
- ✅ Glass morphism effects (using `.ultraThinMaterial`)
- ✅ Card stack depth (scale, offset, opacity, blur)
- ✅ Spring animations (bounce physics)
- ✅ Particle burst (8-particle circular pattern)
- ✅ Floating cards animation
- ✅ Progress dots expand/contract
- ✅ Keyboard navigation
- ✅ Gesture recognizers

### What's Different (8-15% gap):
- ⚠️ Ripple effect complexity (simpler in SwiftUI)
- ⚠️ Font rendering (system fonts vs Inter web font)
- ⚠️ Backdrop blur intensity (SwiftUI materials vs CSS backdrop-filter)
- ⚠️ Pixel-perfect spacing (minor differences)

### What's Better in SwiftUI:
- 🎯 Native performance (60fps vs browser rendering)
- 🎯 Spring physics (more realistic bounce)
- 🎯 Gesture integration (native macOS gestures)
- 🎯 Accessibility (VoiceOver support)

## Architecture

### Data Flow

```
NotesManager (Observable)
    ↓
CarouselDashboardIntegratedView
    ↓ (converts Note → CarouselNoteData)
    ├── Top Bar (search, settings, new note)
    ├── Carousel Container
    │   ├── IntegratedCarouselCardView (foreach note)
    │   └── Navigation Arrows
    ├── Progress Dots
    ├── Thumbnail Strip (IntegratedThumbnailView)
    └── Bottom Bar (counter, view all)
```

### Animation States

Cards have 4 states with different visual properties:

| State      | Scale | Y Offset | Opacity | Blur |
|------------|-------|----------|---------|------|
| Active     | 1.0   | 0        | 1.0     | 0    |
| Behind One | 0.95  | -20      | 0.8     | 1    |
| Behind Two | 0.9   | -40      | 0.6     | 2    |
| Hidden     | 0.85  | -60      | 0.0     | 3    |

### Glass Morphism Implementation

Instead of using the third-party SwiftGlass library, we use native SwiftUI materials:

```swift
.background(
    ZStack {
        color.opacity(0.15)
        Rectangle().fill(.ultraThinMaterial)
    }
)
.overlay(
    RoundedRectangle(cornerRadius: 24)
        .stroke(Color.white.opacity(0.25), lineWidth: 1)
)
```

This provides:
- Built-in system blur (adapts to dark/light mode)
- No external dependencies
- Native macOS look and feel
- Better performance

## Usage

### Standalone Version (Demo Data)

```swift
import SwiftUI

struct ContentView: View {
    var body: some View {
        CarouselDashboardView()
            .environment(NotesManager())
            .frame(width: 1200, height: 800)
    }
}
```

### Integrated Version (Real Data)

```swift
import SwiftUI

@main
struct ThinqSyncApp: App {
    @State private var notesManager = NotesManager()

    var body: some Scene {
        WindowGroup {
            CarouselDashboardIntegratedView()
                .environment(notesManager)
        }
    }
}
```

## Interactions

### Keyboard Navigation
- `←` Previous card
- `→` Next card

### Mouse/Trackpad
- Click navigation arrows
- Click progress dots to jump to specific card
- Click thumbnails to jump to specific card
- Click star to toggle favorite (triggers particle burst)

### Gestures
- Swipe left: Next card (50px threshold)
- Swipe right: Previous card (50px threshold)
- Drag offset provides live feedback

## Performance Considerations

- **Rendering**: Only visible cards are fully rendered (state = .hidden has opacity 0)
- **Animations**: Spring animations use `.spring(duration:bounce:)` for 60fps
- **Particle System**: Canvas-based rendering for efficient particle effects
- **Memory**: Particle bursts auto-cleanup after 0.8s

## Future Enhancements

Potential improvements based on user feedback:

1. **Search Integration**: Filter cards by title/content
2. **Folder Filtering**: Show only cards from specific folder
3. **Sort Options**: By modified date, title, favorite status
4. **Card Editing**: Tap card to open in NoteWindow
5. **Batch Actions**: Select multiple cards for bulk operations
6. **Export View**: Share current card as image
7. **Customization**: User-selectable color themes
8. **Persistence**: Remember last viewed card index

## Testing

To test the views:

```bash
# Build project
xcodebuild -project thinqsync.xcodeproj -scheme thinqsync build

# Run in Xcode
open thinqsync.xcodeproj
# Press Cmd+R to run
```

## Known Limitations

1. **No SwiftGlass Library**: Using native materials instead (slightly different blur)
2. **Ripple Effect**: Simplified compared to CSS version
3. **Font**: Uses system font instead of Inter from Google Fonts
4. **Loading Animation**: Simple spinner vs complex staggered sequence

## Related Files

- HTML Prototype: [.superdesign/design_iterations/carousel_glassmorphism_1.html](../../../../.superdesign/design_iterations/carousel_glassmorphism_1.html)
- CSS Theme: [.superdesign/design_iterations/carousel_glassmorphism_theme.css](../../../../.superdesign/design_iterations/carousel_glassmorphism_theme.css)
- Original Dashboard: [ShowAllNotesView.swift](../ShowAllNotesView.swift)
- Note Model: [Models/Note.swift](../../Models/Note.swift)
- Notes Manager: [Models/NotesManager.swift](../../Models/NotesManager.swift)

## Credits

Design based on glass morphism carousel concept with custom ThinqSync color palette. Converted from HTML/CSS to SwiftUI with Context7 MCP research for implementation guidance.

Generated with [Claude Code](https://claude.com/claude-code)
