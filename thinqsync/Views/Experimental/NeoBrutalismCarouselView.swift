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
    @State private var selectedFilter: FilterOption = .all
    @State private var sortOrder: SortOrder = .modifiedDate
    @State private var selectedFolder: String? = nil
    @State private var showFilterPopover = false
    @State private var showSortPopover = false

    enum FilterOption: String, CaseIterable {
        case all = "ALL NOTES"
        case favorites = "FAVORITES"
        case folder = "BY FOLDER"
    }

    enum SortOrder: String, CaseIterable {
        case modifiedDate = "MODIFIED DATE"
        case createdDate = "CREATED DATE"
        case title = "TITLE"
        case color = "COLOR"
    }

    private var availableFolders: [String] {
        Array(Set(notesManager.notes.compactMap { $0.folder })).sorted()
    }

    // Convert notes to display format
    private var displayNotes: [CarouselNoteData] {
        var sourceNotes = showTrash ? notesManager.deletedNotes : notesManager.notes

        // Apply search filter
        if !searchText.isEmpty && !showTrash {
            sourceNotes = sourceNotes.filter { note in
                note.title.localizedCaseInsensitiveContains(searchText) ||
                note.contentWrapper.attributedString.string.localizedCaseInsensitiveContains(searchText)
            }
        }

        // Apply category filter
        if !showTrash {
            switch selectedFilter {
            case .all:
                break
            case .favorites:
                sourceNotes = sourceNotes.filter { $0.isFavorite }
            case .folder:
                if let folder = selectedFolder {
                    sourceNotes = sourceNotes.filter { $0.folder == folder }
                }
            }
        }

        // Apply sort order
        if !showTrash {
            switch sortOrder {
            case .modifiedDate:
                sourceNotes = sourceNotes.sorted { $0.modifiedAt > $1.modifiedAt }
            case .createdDate:
                sourceNotes = sourceNotes.sorted { $0.createdAt > $1.createdAt }
            case .title:
                sourceNotes = sourceNotes.sorted { $0.title.localizedCompare($1.title) == .orderedAscending }
            case .color:
                sourceNotes = sourceNotes.sorted { $0.color.rawValue < $1.color.rawValue }
            }
        }

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
        GeometryReader { geometry in
            ZStack {
                // Sky blue background
                Color(hex: "8ecae6")
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Top Bar
                    topBar

                    Spacer()
                        .frame(height: geometry.size.height * 0.02)

                    // Main Carousel
                    carouselContainer
                        .frame(height: geometry.size.height * 0.50)

                    Spacer()
                        .frame(height: geometry.size.height * 0.025)

                    // Progress Dots
                    progressDots

                    Spacer()
                        .frame(height: geometry.size.height * 0.025)

                    // Thumbnail Strip
                    thumbnailStrip
                        .frame(height: geometry.size.height * 0.10)

                    Spacer()
                        .frame(height: geometry.size.height * 0.025)

                    // Bottom Bar
                    bottomBar
                }
                .padding(geometry.size.width * 0.025)
            }
        }
        .onChange(of: displayNotes.count) { oldValue, newValue in
            // Reset index if it's out of bounds when notes change
            if currentIndex >= newValue && newValue > 0 {
                currentIndex = newValue - 1
            } else if newValue == 0 {
                currentIndex = 0
            }
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        VStack(spacing: 0) {
            HStack {
                Text("THINQSYNC")
                    .font(.system(size: 28, weight: .black))
                    .foregroundColor(.black)

                Spacer()

                HStack(spacing: 16) {
                    NeoBrutalButton(
                        icon: showSearch ? "xmark" : "magnifyingglass",
                        background: showSearch ? Color(hex: "ffb703") : .white
                    ) {
                        withAnimation(.spring(duration: 0.3, bounce: 0.5)) {
                            showSearch.toggle()
                            if !showSearch {
                                searchText = ""
                            }
                        }
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

            // Search field
            if showSearch {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 24, weight: .black))
                        .foregroundColor(.black)

                    TextField("SEARCH NOTES...", text: $searchText)
                        .textFieldStyle(.plain)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.black)
                }
                .padding(20)
                .background(
                    Color(hex: "ffb703")
                        .overlay(
                            Rectangle()
                                .stroke(Color.black, lineWidth: 4)
                        )
                )
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
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
        GeometryReader { geometry in
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
                    emptyState(geometry: geometry)
                } else {
                    cardStack(geometry: geometry)
                }
            }
        }
    }

    private func cardStack(geometry: GeometryProxy) -> some View {
        ZStack {
            // Only show the active card - no stacking effect
            if !displayNotes.isEmpty {
                let safeIndex = min(currentIndex, displayNotes.count - 1)
                let noteData = displayNotes[safeIndex]

                NeoBrutalNoteCard(
                    noteData: noteData,
                    position: .active,
                    geometry: geometry,
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
                        if showTrash {
                            // In trash view - permanent delete
                            if let note = notesManager.deletedNotes.first(where: { $0.id == noteData.id }) {
                                notesManager.permanentlyDeleteNote(note)
                            }
                        } else {
                            // Normal view - move to trash
                            if let note = notesManager.notes.first(where: { $0.id == noteData.id }) {
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
                .onAppear {
                    // Reset index if it's out of bounds
                    if currentIndex >= displayNotes.count {
                        currentIndex = max(0, displayNotes.count - 1)
                    }
                }
            }
        }
        .frame(maxWidth: geometry.size.width * 0.6)
    }

    private func emptyState(geometry: GeometryProxy) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "note.text")
                .font(.system(size: min(geometry.size.width * 0.08, 64), weight: .black))
                .foregroundColor(.black)

            Text(showTrash ? "TRASH IS EMPTY" : "NO NOTES YET")
                .font(.system(size: min(geometry.size.width * 0.04, 32), weight: .black))
                .foregroundColor(.black)
        }
        .frame(maxWidth: geometry.size.width * 0.6)
        .frame(maxHeight: .infinity)
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
            HStack(spacing: 28) {
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
        VStack(spacing: 0) {
            // Filter popover
            if showFilterPopover {
                VStack(spacing: 0) {
                    ForEach(FilterOption.allCases, id: \.self) { option in
                        Button(action: {
                            selectedFilter = option
                            if option == .folder && !availableFolders.isEmpty {
                                selectedFolder = availableFolders.first
                            } else {
                                showFilterPopover = false
                            }
                            currentIndex = 0
                        }) {
                            HStack {
                                Text(option.rawValue)
                                    .font(.system(size: 16, weight: .black))
                                    .foregroundColor(.black)
                                Spacer()
                                if selectedFilter == option {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 16, weight: .black))
                                        .foregroundColor(.black)
                                }
                            }
                            .padding(16)
                        }
                        .buttonStyle(.plain)

                        if option != FilterOption.allCases.last {
                            Rectangle()
                                .fill(Color.black)
                                .frame(height: 2)
                        }
                    }

                    if selectedFilter == .folder && !availableFolders.isEmpty {
                        Rectangle()
                            .fill(Color.black)
                            .frame(height: 4)

                        ForEach(availableFolders, id: \.self) { folder in
                            Button(action: {
                                selectedFolder = folder
                                currentIndex = 0
                                showFilterPopover = false
                            }) {
                                HStack {
                                    Text(folder.uppercased())
                                        .font(.system(size: 16, weight: .black))
                                        .foregroundColor(.black)
                                    Spacer()
                                    if selectedFolder == folder {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 16, weight: .black))
                                            .foregroundColor(.black)
                                    }
                                }
                                .padding(16)
                            }
                            .buttonStyle(.plain)

                            if folder != availableFolders.last {
                                Rectangle()
                                    .fill(Color.black)
                                    .frame(height: 2)
                            }
                        }
                    }
                }
                .background(
                    Color.white
                        .overlay(
                            Rectangle()
                                .stroke(Color.black, lineWidth: 4)
                        )
                        .shadow(color: .black, radius: 0, x: 6, y: 6)
                )
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            // Sort popover
            if showSortPopover {
                VStack(spacing: 0) {
                    ForEach(SortOrder.allCases, id: \.self) { order in
                        Button(action: {
                            sortOrder = order
                            currentIndex = 0
                            showSortPopover = false
                        }) {
                            HStack {
                                Text(order.rawValue)
                                    .font(.system(size: 16, weight: .black))
                                    .foregroundColor(.black)
                                Spacer()
                                if sortOrder == order {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 16, weight: .black))
                                        .foregroundColor(.black)
                                }
                            }
                            .padding(16)
                        }
                        .buttonStyle(.plain)

                        if order != SortOrder.allCases.last {
                            Rectangle()
                                .fill(Color.black)
                                .frame(height: 2)
                        }
                    }
                }
                .background(
                    Color.white
                        .overlay(
                            Rectangle()
                                .stroke(Color.black, lineWidth: 4)
                        )
                        .shadow(color: .black, radius: 0, x: 6, y: 6)
                )
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            HStack {
                HStack(spacing: 12) {
                    // Filter button
                    NeoBrutalButton(
                        text: selectedFilter == .folder && selectedFolder != nil ? (selectedFolder ?? "FILTER") : selectedFilter.rawValue,
                        icon: "line.3.horizontal.decrease",
                        background: selectedFilter != .all ? Color(hex: "219ebc") : .white
                    ) {
                        withAnimation(.spring(duration: 0.3, bounce: 0.5)) {
                            showFilterPopover.toggle()
                            showSortPopover = false
                        }
                    }

                    // Sort button
                    NeoBrutalButton(
                        text: sortOrder.rawValue,
                        icon: "arrow.up.arrow.down",
                        background: sortOrder != .modifiedDate ? Color(hex: "a855f7") : .white
                    ) {
                        withAnimation(.spring(duration: 0.3, bounce: 0.5)) {
                            showSortPopover.toggle()
                            showFilterPopover = false
                        }
                    }

                    NeoBrutalButton(
                        text: showTrash ? "NOTES" : "TRASH",
                        icon: showTrash ? "arrow.left" : "trash",
                        background: showTrash ? .white : Color(hex: "fb8500")
                    ) {
                        withAnimation(.spring(duration: 0.3, bounce: 0.5)) {
                            showTrash.toggle()
                            currentIndex = 0
                            // Reset filters when switching to/from trash
                            selectedFilter = .all
                            searchText = ""
                            showFilterPopover = false
                            showSortPopover = false
                        }
                    }
                }

                Spacer()

                Text("CARD \(currentIndex + 1) OF \(max(displayNotes.count, 1)) • USE ← →")
                    .font(.system(size: 13, weight: .black))
                    .foregroundColor(.black)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
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
    let geometry: GeometryProxy
    let onTap: () -> Void
    let onFavorite: () -> Void
    let onDelete: () -> Void
    let onRestore: () -> Void
    let isTrashView: Bool

    @State private var showDeleteConfirmation = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text(noteData.title.uppercased())
                    .font(.system(size: min(geometry.size.width * 0.03, 40), weight: .heavy))
                    .foregroundColor(.black)
                    .lineLimit(1)

                Spacer()

                Button(action: onFavorite) {
                    Image(systemName: noteData.isFavorite ? "star.fill" : "star")
                        .font(.system(size: min(geometry.size.width * 0.02, 24), weight: .black))
                        .foregroundColor(noteData.isFavorite ? Color(hex: "ffb703") : .black)
                }
                .buttonStyle(.plain)
            }
            .padding(.bottom, geometry.size.height * 0.03)
            .overlay(
                Rectangle()
                    .fill(Color.black)
                    .frame(height: 4),
                alignment: .bottom
            )

            // Content
            ScrollView {
                Text(noteData.content.isEmpty ? "Empty note" : noteData.content)
                    .font(.system(size: min(geometry.size.width * 0.014, 18), weight: .regular))
                    .foregroundColor(.black)
                    .lineSpacing(6)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.top, geometry.size.height * 0.04)

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
                                .font(.system(size: min(geometry.size.width * 0.01, 13), weight: .black))
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
                            .font(.system(size: min(geometry.size.width * 0.011, 14), weight: .black))
                            .foregroundColor(.black)
                    }

                    Spacer()

                    HStack(spacing: 8) {
                        if isTrashView {
                            NeoBrutalButton(text: "RESTORE", icon: "arrow.uturn.backward", background: Color(hex: "22c55e"), action: onRestore)
                            NeoBrutalButton(text: "DELETE", icon: "trash", background: Color(hex: "fb8500")) {
                                showDeleteConfirmation = true
                            }
                        } else {
                            NeoBrutalButton(text: "EDIT", icon: "pencil", background: .white, action: onTap)
                            NeoBrutalButton(icon: "trash", background: Color(hex: "fb8500"), action: onDelete)
                        }
                    }
                }
                .padding(.top, geometry.size.height * 0.03)
            }
        }
        .padding(geometry.size.width * 0.035)
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
        .overlay(
            Group {
                if showDeleteConfirmation {
                    NeoBrutalDeleteConfirmation(
                        onConfirm: {
                            showDeleteConfirmation = false
                            onDelete()
                        },
                        onCancel: {
                            showDeleteConfirmation = false
                        }
                    )
                }
            }
        )
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d • h:mm a"
        return formatter.string(from: date).uppercased()
    }
}

// MARK: - Delete Confirmation Dialog

struct NeoBrutalDeleteConfirmation: View {
    let onConfirm: () -> Void
    let onCancel: () -> Void

    var body: some View {
        ZStack {
            // Dark overlay
            Color.black.opacity(0.7)
                .ignoresSafeArea()

            // Confirmation card
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 56, weight: .black))
                        .foregroundColor(Color(hex: "fb8500"))

                    Text("PERMANENT DELETE")
                        .font(.system(size: 32, weight: .black))
                        .foregroundColor(.black)
                }
                .padding(.top, 40)
                .padding(.horizontal, 40)

                // Message
                VStack(spacing: 16) {
                    Text("This action cannot be undone.")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.black)

                    Text("The note will be permanently deleted from your device and cannot be recovered.")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.black.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
                .padding(.vertical, 32)
                .padding(.horizontal, 40)

                // Buttons
                HStack(spacing: 16) {
                    Button(action: onCancel) {
                        HStack(spacing: 8) {
                            Image(systemName: "xmark")
                                .font(.system(size: 18, weight: .black))
                            Text("CANCEL")
                                .font(.system(size: 18, weight: .black))
                        }
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .background(
                            Color.white
                                .overlay(
                                    Rectangle()
                                        .stroke(Color.black, lineWidth: 4)
                                )
                        )
                    }
                    .buttonStyle(NeoBrutalButtonStyle())

                    Button(action: onConfirm) {
                        HStack(spacing: 8) {
                            Image(systemName: "trash.fill")
                                .font(.system(size: 18, weight: .black))
                            Text("DELETE")
                                .font(.system(size: 18, weight: .black))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .background(
                            Color(hex: "fb8500")
                                .overlay(
                                    Rectangle()
                                        .stroke(Color.black, lineWidth: 4)
                                )
                        )
                    }
                    .buttonStyle(NeoBrutalButtonStyle())
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
            }
            .frame(width: 520)
            .background(
                Color.white
                    .overlay(
                        Rectangle()
                            .stroke(Color.black, lineWidth: 6)
                    )
                    .shadow(color: .black, radius: 0, x: 12, y: 12)
            )
        }
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
            HStack(spacing: 6) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: text.isEmpty ? 18 : 14, weight: .black))
                }
                if !text.isEmpty {
                    Text(text.uppercased())
                        .font(.system(size: 14, weight: .black))
                }
            }
            .foregroundColor(.black)
            .padding(.horizontal, text.isEmpty ? 12 : 20)
            .padding(.vertical, 10)
            .background(
                background
                    .overlay(
                        Rectangle()
                            .stroke(Color.black, lineWidth: 3)
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
