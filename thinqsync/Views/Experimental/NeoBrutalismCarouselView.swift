//
//  NeoBrutalismCarouselView.swift
//  thinqsync
//
//  Neo-brutalism design carousel dashboard
//

import SwiftUI

struct NeoBrutalismCarouselView: View {
    @Environment(NotesManager.self) private var notesManager
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.openWindow) private var openWindow
    @State private var currentIndex: Int = 0
    @State private var searchText = ""
    @State private var showSearch = false
    @State private var showTrash = false

    // Convert notes to display format
    private var displayNotes: [CarouselNoteData] {
        let sourceNotes = showTrash ? notesManager.deletedNotes : notesManager.notes

        return sourceNotes.map { note in
            let plainText = note.content
            let carouselColor: Color = {
                switch note.color {
                case .green: return Color(hex: "22c55e")
                case .yellow: return Color(hex: "ffb703")
                case .orange: return Color(hex: "fb8500")
                case .blue: return Color(hex: "219ebc")
                case .purple: return Color(hex: "a855f7")
                case .pink: return .white
                }
            }()

            return CarouselNoteData(
                id: note.id,
                title: note.title,
                content: plainText,
                color: carouselColor,
                isFavorite: note.isFavorite,
                folder: note.folder,
                modifiedAt: note.modifiedAt,
                deletedAt: note.deletedAt
            )
        }
    }

    var body: some View {
        ZStack {
            // Sky blue background
            Color(hex: "8ecae6")
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 40) {
                    // Top Bar
                    topBar

                    // Main Carousel
                    carouselContainer

                    // Progress Dots
                    progressDots

                    // Thumbnail Strip
                    thumbnailStrip

                    // Bottom Bar
                    bottomBar
                }
                .padding(40)
            }
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            Text("THINQSYNC")
                .font(.system(size: 28, weight: .black))
                .foregroundColor(.black)

            Spacer()

            HStack(spacing: 16) {
                NeoBrutalButton(icon: "magnifyingglass", background: .white) {
                    showSearch.toggle()
                }

                NeoBrutalButton(icon: "gear", background: .white) {
                    // Settings action
                }

                NeoBrutalButton(text: "NEW NOTE", icon: "plus", background: Color(hex: "fb8500")) {
                    let newNote = notesManager.createNote()
                    openWindow(value: newNote.id)
                }
            }
        }
        .padding(24)
        .background(
            Color.white
                .overlay(
                    Rectangle()
                        .stroke(Color.black, lineWidth: 4)
                )
                .shadow(color: .black, radius: 0, x: 8, y: 8)
        )
    }

    // MARK: - Carousel Container

    private var carouselContainer: some View {
        ZStack {
            // Navigation buttons
            HStack {
                NeoBrutalNavigationButton(direction: .left) {
                    withAnimation(.spring(duration: 0.3, bounce: 0.5)) {
                        currentIndex = (currentIndex - 1 + displayNotes.count) % max(displayNotes.count, 1)
                    }
                }

                Spacer()

                NeoBrutalNavigationButton(direction: .right) {
                    withAnimation(.spring(duration: 0.3, bounce: 0.5)) {
                        currentIndex = (currentIndex + 1) % max(displayNotes.count, 1)
                    }
                }
            }
            .zIndex(10)

            // Card stack
            if displayNotes.isEmpty {
                emptyState
            } else {
                cardStack
            }
        }
        .frame(height: 540)
    }

    private var cardStack: some View {
        ZStack {
            // Only show the active card - no stacking effect
            if !displayNotes.isEmpty {
                let noteData = displayNotes[currentIndex]

                NeoBrutalNoteCard(
                    noteData: noteData,
                    position: .active,
                    onTap: {
                        if let note = notesManager.notes.first(where: { $0.id == noteData.id }) {
                            openWindow(value: note.id)
                        }
                    },
                    onFavorite: {
                        if var note = notesManager.notes.first(where: { $0.id == noteData.id }) {
                            note.isFavorite.toggle()
                            notesManager.updateNote(note)
                        }
                    },
                    onDelete: {
                        if let note = notesManager.notes.first(where: { $0.id == noteData.id }) {
                            if showTrash {
                                notesManager.permanentlyDeleteNote(note)
                            } else {
                                notesManager.deleteNote(note)
                            }
                        }
                    },
                    onRestore: {
                        if let note = notesManager.deletedNotes.first(where: { $0.id == noteData.id }) {
                            notesManager.restoreNote(note)
                        }
                    },
                    isTrashView: showTrash
                )
            }
        }
        .frame(maxWidth: 700)
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "note.text")
                .font(.system(size: 64, weight: .black))
                .foregroundColor(.black)

            Text(showTrash ? "TRASH IS EMPTY" : "NO NOTES YET")
                .font(.system(size: 32, weight: .black))
                .foregroundColor(.black)
        }
        .frame(width: 700, height: 540)
        .background(
            Color.white
                .overlay(
                    Rectangle()
                        .stroke(Color.black, lineWidth: 4)
                )
                .shadow(color: .black, radius: 0, x: 12, y: 12)
        )
    }

    private func cardPosition(for offset: Int) -> CardPosition {
        switch offset {
        case 0: return .active
        case 1: return .behindOne
        case 2: return .behindTwo
        default: return .hidden
        }
    }

    // MARK: - Progress Dots

    private var progressDots: some View {
        HStack(spacing: 16) {
            ForEach(0..<max(displayNotes.count, 1), id: \.self) { index in
                NeoBrutalDot(isActive: index == currentIndex) {
                    withAnimation(.spring(duration: 0.3, bounce: 0.5)) {
                        currentIndex = index
                    }
                }
            }
        }
    }

    // MARK: - Thumbnail Strip

    private var thumbnailStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 20) {
                ForEach(Array(displayNotes.enumerated()), id: \.element.id) { index, noteData in
                    NeoBrutalThumbnail(
                        color: noteData.color,
                        isActive: index == currentIndex
                    ) {
                        withAnimation(.spring(duration: 0.3, bounce: 0.5)) {
                            currentIndex = index
                        }
                    }
                }
            }
            .padding(24)
        }
        .background(
            Color.white
                .overlay(
                    Rectangle()
                        .stroke(Color.black, lineWidth: 4)
                )
                .shadow(color: .black, radius: 0, x: 6, y: 6)
        )
    }

    // MARK: - Bottom Bar

    private var bottomBar: some View {
        HStack {
            HStack(spacing: 16) {
                NeoBrutalButton(text: "FILTER", icon: "line.3.horizontal.decrease", background: .white) {
                    // Filter action
                }

                NeoBrutalButton(text: "SORT", icon: "arrow.up.arrow.down", background: .white) {
                    // Sort action
                }

                NeoBrutalButton(
                    text: showTrash ? "NOTES" : "TRASH",
                    icon: showTrash ? "arrow.left" : "trash",
                    background: showTrash ? .white : Color(hex: "fb8500")
                ) {
                    withAnimation(.spring(duration: 0.3, bounce: 0.5)) {
                        showTrash.toggle()
                        currentIndex = 0
                    }
                }
            }

            Spacer()

            Text("CARD \(currentIndex + 1) OF \(max(displayNotes.count, 1)) • USE ← →")
                .font(.system(size: 16, weight: .black))
                .foregroundColor(.black)
        }
        .padding(24)
        .background(
            Color.white
                .overlay(
                    Rectangle()
                        .stroke(Color.black, lineWidth: 4)
                )
                .shadow(color: .black, radius: 0, x: 6, y: 6)
        )
    }
}

// MARK: - Card Position Enum

enum CardPosition: Equatable {
    case active, behindOne, behindTwo, hidden

    var zIndex: Double {
        switch self {
        case .active: return 3
        case .behindOne: return 2
        case .behindTwo: return 1
        case .hidden: return 0
        }
    }

    var offset: CGSize {
        switch self {
        case .active: return .zero
        case .behindOne: return CGSize(width: 30, height: -20)
        case .behindTwo: return CGSize(width: 60, height: -40)
        case .hidden: return CGSize(width: 100, height: -60)
        }
    }

    var opacity: Double {
        switch self {
        case .active: return 1
        case .behindOne: return 1
        case .behindTwo: return 1
        case .hidden: return 0
        }
    }

    var shadowOffset: CGFloat {
        switch self {
        case .active: return 12
        case .behindOne: return 8
        case .behindTwo: return 4
        case .hidden: return 0
        }
    }
}

// MARK: - Note Card

struct NeoBrutalNoteCard: View {
    let noteData: CarouselNoteData
    let position: CardPosition
    let onTap: () -> Void
    let onFavorite: () -> Void
    let onDelete: () -> Void
    let onRestore: () -> Void
    let isTrashView: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text(noteData.title.uppercased())
                    .font(.system(size: 40, weight: .heavy))
                    .foregroundColor(.black)
                    .lineLimit(1)

                Spacer()

                Button(action: onFavorite) {
                    Image(systemName: noteData.isFavorite ? "star.fill" : "star")
                        .font(.system(size: 24, weight: .black))
                        .foregroundColor(noteData.isFavorite ? Color(hex: "ffb703") : .black)
                }
                .buttonStyle(.plain)
            }
            .padding(.bottom, 24)
            .overlay(
                Rectangle()
                    .fill(Color.black)
                    .frame(height: 4),
                alignment: .bottom
            )

            // Content
            ScrollView {
                Text(noteData.content.isEmpty ? "Empty note" : noteData.content)
                    .font(.system(size: 18, weight: .regular))
                    .foregroundColor(.black)
                    .lineSpacing(6)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(minHeight: 220)
            .padding(.top, 32)

            Spacer()

            // Footer
            VStack(spacing: 0) {
                Rectangle()
                    .fill(Color.black)
                    .frame(height: 4)

                HStack {
                    HStack(spacing: 16) {
                        if let folder = noteData.folder {
                            Text(folder.uppercased())
                                .font(.system(size: 13, weight: .black))
                                .foregroundColor(.black)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.white)
                                .overlay(
                                    Rectangle()
                                        .stroke(Color.black, lineWidth: 3)
                                )
                        }

                        Text(formatDate(noteData.modifiedAt))
                            .font(.system(size: 14, weight: .black))
                            .foregroundColor(.black)
                    }

                    Spacer()

                    HStack(spacing: 8) {
                        if isTrashView {
                            NeoBrutalButton(text: "RESTORE", icon: "arrow.uturn.backward", background: Color(hex: "22c55e"), action: onRestore)
                            NeoBrutalButton(text: "DELETE", icon: "trash", background: Color(hex: "fb8500"), action: onDelete)
                        } else {
                            NeoBrutalButton(text: "EDIT", icon: "pencil", background: .white, action: onTap)
                        }
                    }
                }
                .padding(.top, 24)
            }
        }
        .padding(48)
        .background(
            noteData.color
                .overlay(
                    Rectangle()
                        .stroke(Color.black, lineWidth: 4)
                )
                .shadow(color: .black, radius: 0, x: position.shadowOffset, y: position.shadowOffset)
        )
        .offset(position.offset)
        .opacity(position.opacity)
        .zIndex(position.zIndex)
        .frame(height: 540)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d • h:mm a"
        return formatter.string(from: date).uppercased()
    }
}

// MARK: - Reusable Components

struct NeoBrutalButton: View {
    var text: String = ""
    var icon: String?
    var background: Color
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: text.isEmpty ? 24 : 18, weight: .black))
                }
                if !text.isEmpty {
                    Text(text.uppercased())
                        .font(.system(size: 18, weight: .black))
                }
            }
            .foregroundColor(.black)
            .padding(.horizontal, text.isEmpty ? 16 : 32)
            .padding(.vertical, 16)
            .background(
                background
                    .overlay(
                        Rectangle()
                            .stroke(Color.black, lineWidth: 4)
                    )
            )
        }
        .buttonStyle(NeoBrutalButtonStyle())
    }
}

struct NeoBrutalButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.spring(duration: 0.15, bounce: 0.5), value: configuration.isPressed)
    }
}

struct NeoBrutalNavigationButton: View {
    enum Direction {
        case left, right
    }

    let direction: Direction
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: direction == .left ? "chevron.left" : "chevron.right")
                .font(.system(size: 36, weight: .black))
                .foregroundColor(.black)
                .frame(width: 72, height: 72)
                .background(
                    Color.white
                        .overlay(
                            Rectangle()
                                .stroke(Color.black, lineWidth: 4)
                        )
                )
        }
        .buttonStyle(NeoBrutalButtonStyle())
    }
}

struct NeoBrutalDot: View {
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Rectangle()
                    .fill(isActive ? Color(hex: "219ebc") : Color.white)
                    .frame(width: isActive ? 48 : 20, height: 20)
                    .rotationEffect(.degrees(isActive ? 45 : 0))

                Rectangle()
                    .stroke(Color.black, lineWidth: 4)
                    .frame(width: isActive ? 48 : 20, height: 20)
                    .rotationEffect(.degrees(isActive ? 45 : 0))
            }
        }
        .buttonStyle(.plain)
        .animation(.spring(duration: 0.3, bounce: 0.5), value: isActive)
    }
}

struct NeoBrutalThumbnail: View {
    let color: Color
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Rectangle()
                    .fill(color)
                    .frame(width: 90, height: 90)

                Rectangle()
                    .stroke(Color.black, lineWidth: isActive ? 6 : 4)
                    .frame(width: 90, height: 90)
            }
            .scaleEffect(isActive ? 1.1 : 1.0)
            .rotationEffect(.degrees(isActive ? -5 : 0))
        }
        .buttonStyle(NeoBrutalButtonStyle())
        .animation(.spring(duration: 0.3, bounce: 0.5), value: isActive)
    }
}

#Preview {
    NeoBrutalismCarouselView()
        .environment(NotesManager())
        .frame(width: 1200, height: 800)
}
