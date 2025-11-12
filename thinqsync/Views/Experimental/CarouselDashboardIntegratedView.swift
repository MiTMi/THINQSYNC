//
//  CarouselDashboardIntegratedView.swift
//  thinqsync
//
//  Carousel dashboard integrated with actual NotesManager
//

import SwiftUI

struct CarouselDashboardIntegratedView: View {
    @Environment(NotesManager.self) private var notesManager
    @Environment(\.colorScheme) private var colorScheme
    @State private var currentIndex: Int = 0
    @State private var particleBursts: [ParticleBurstTrigger] = []
    @State private var isLoading = true
    @State private var dragOffset: CGFloat = 0
    @State private var searchText = ""
    @State private var showSearch = false
    @State private var deletingNoteId: UUID? = nil
    @FocusState private var isFocused: Bool
    @Environment(\.openWindow) private var openWindow

    // Adaptive colors based on system appearance
    private var adaptiveTextColor: Color {
        colorScheme == .dark ? .white : .black
    }

    private var adaptiveShadowColor: Color {
        colorScheme == .dark ? .black.opacity(0.3) : .white.opacity(0.3)
    }

    // Convert real notes to carousel notes with search filtering
    private var displayNotes: [CarouselNoteData] {
        let allNotes = notesManager.notes.map { note in
            // Extract plain text from content property (preserve original formatting)
            let plainText = note.content

            // Map NoteColor to carousel colors
            let carouselColor: Color = {
                switch note.color {
                case .green: return .blueGreen
                case .yellow: return .selectiveYellow
                case .orange: return .utOrange
                case .blue: return .prussianBlue
                case .purple: return .blueGreen
                case .pink: return .skyBlue
                }
            }()

            return CarouselNoteData(
                id: note.id,
                title: note.title,
                content: plainText,
                color: carouselColor,
                isFavorite: note.isFavorite,
                folder: note.folder,
                modifiedAt: note.modifiedAt
            )
        }

        // Filter by search text
        if searchText.isEmpty {
            return allNotes
        } else {
            return allNotes.filter { noteData in
                noteData.title.localizedCaseInsensitiveContains(searchText) ||
                noteData.content.localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    var body: some View {
        ZStack {
            // Adaptive gradient background
            LinearGradient(
                gradient: Gradient(colors: colorScheme == .dark ? [
                    Color.prussianBlue.opacity(0.3),
                    Color.blueGreen.opacity(0.2),
                    Color.skyBlue.opacity(0.3)
                ] : [
                    Color.gray.opacity(0.1),
                    Color.blue.opacity(0.05),
                    Color.gray.opacity(0.15)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            if isLoading {
                // Loading overlay
                ZStack {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()

                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                }
                .transition(.opacity)
            } else {
                if displayNotes.isEmpty {
                    // Empty state - differentiate between search and truly empty
                    if !searchText.isEmpty {
                        // Search returned no results
                        VStack(spacing: 20) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 80))
                                .foregroundColor(adaptiveTextColor.opacity(0.5))

                            Text("No Results Found")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(adaptiveTextColor)

                            Text("Try a different search term")
                                .font(.body)
                                .foregroundColor(adaptiveTextColor.opacity(0.7))

                            Button(action: {
                                searchText = ""
                                showSearch = false
                            }) {
                                HStack {
                                    Image(systemName: "arrow.left")
                                    Text("Back to Notes")
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .background(
                                    Capsule()
                                        .fill(Color.blueGreen)
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    } else {
                        // Truly no notes
                        VStack(spacing: 20) {
                            Image(systemName: "note.text")
                                .font(.system(size: 80))
                                .foregroundColor(adaptiveTextColor.opacity(0.5))

                            Text("No Notes Yet")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(adaptiveTextColor)

                            Text("Create your first note to get started")
                                .font(.body)
                                .foregroundColor(adaptiveTextColor.opacity(0.7))

                            Button(action: {
                                let note = notesManager.createNote()
                                openWindow(value: note.id)
                            }) {
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                    Text("Create Note")
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .background(
                                    Capsule()
                                        .fill(Color.selectiveYellow)
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                } else {
                    VStack(spacing: 0) {
                        // Top Bar
                        topBar
                            .transition(.move(edge: .top).combined(with: .opacity))

                        // Search Bar (conditional)
                        if showSearch {
                            searchBar
                                .transition(.move(edge: .top).combined(with: .opacity))
                        }

                        Spacer()

                        // Main Carousel Area
                        carouselContainer
                            .frame(maxHeight: 600)

                        Spacer()

                        // Progress Dots
                        progressDots
                            .transition(.scale.combined(with: .opacity))
                            .padding(.bottom, 20)

                        // Thumbnail Strip
                        thumbnailStrip
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                            .padding(.bottom, 20)

                        // Bottom Bar
                        bottomBar
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
            }

            // Particle burst overlay
            ParticleBurstOverlay(triggers: $particleBursts, color: .selectiveYellow)
        }
        .focusable()
        .focused($isFocused)
        .onAppear {
            isFocused = true
            // Simulate loading
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.spring(duration: 0.6, bounce: 0.3)) {
                    isLoading = false
                }
            }
        }
        .onKeyPress(.leftArrow) {
            previousCard()
            return .handled
        }
        .onKeyPress(.rightArrow) {
            nextCard()
            return .handled
        }
        .gesture(
            DragGesture()
                .onChanged { value in
                    dragOffset = value.translation.width
                }
                .onEnded { value in
                    if value.translation.width < -50 {
                        nextCard()
                    } else if value.translation.width > 50 {
                        previousCard()
                    }
                    dragOffset = 0
                }
        )
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack(spacing: 16) {
            // Logo/Title
            HStack(spacing: 8) {
                Image(systemName: "note.text")
                    .font(.title2)
                    .foregroundColor(adaptiveTextColor)
                Text("ThinqSync")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(adaptiveTextColor)
            }

            // iCloud sync indicator
            if notesManager.iCloudEnabled {
                HStack(spacing: 6) {
                    Image(systemName: notesManager.isSyncing ? "icloud.and.arrow.up" : "icloud")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(adaptiveTextColor.opacity(0.9))
                        .symbolEffect(.pulse, options: .repeating, isActive: notesManager.isSyncing)

                    if notesManager.isSyncing {
                        Text("Syncing...")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(adaptiveTextColor.opacity(0.8))
                    } else {
                        Text("Synced")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(adaptiveTextColor.opacity(0.8))
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(.ultraThinMaterial)
                        .opacity(0.5)
                )
                .overlay(
                    Capsule()
                        .stroke(adaptiveTextColor.opacity(0.3), lineWidth: 1)
                )
            }

            Spacer()

            // Actions
            HStack(spacing: 12) {
                // Search button - toggles search bar
                Button(action: {
                    withAnimation(.spring(duration: 0.3, bounce: 0.5)) {
                        showSearch.toggle()
                    }
                    if showSearch {
                        // Focus on search field after animation
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            isFocused = true
                        }
                    } else {
                        searchText = ""
                    }
                }) {
                    Image(systemName: showSearch ? "xmark" : "magnifyingglass")
                        .font(.title3)
                        .foregroundColor(adaptiveTextColor)
                }
                .buttonStyle(GlassButtonStyle())
                .help(showSearch ? "Close search" : "Search notes")

                // Settings button - placeholder for future settings
                Button(action: {
                    // Future: Open settings window
                }) {
                    Image(systemName: "gearshape")
                        .font(.title3)
                        .foregroundColor(adaptiveTextColor)
                }
                .buttonStyle(GlassButtonStyle())
                .help("Settings")

                // New note button
                Button(action: {
                    let note = notesManager.createNote()
                    openWindow(value: note.id)
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(.selectiveYellow)
                }
                .buttonStyle(PlainButtonStyle())
                .help("Create new note")
            }
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 20)
        .background(
            Rectangle()
                .fill(.ultraThinMaterial)
                .opacity(0.5)
        )
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(adaptiveTextColor.opacity(0.6))

            TextField("Search notes...", text: $searchText)
                .textFieldStyle(.plain)
                .font(.body)
                .foregroundColor(adaptiveTextColor)
                .focused($isFocused)

            if !searchText.isEmpty {
                Button(action: {
                    searchText = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(adaptiveTextColor.opacity(0.6))
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .opacity(0.6)
        )
        .padding(.horizontal, 32)
        .padding(.top, 8)
        .padding(.bottom, 16)
    }

    // MARK: - Carousel Container

    private var carouselContainer: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(Array(displayNotes.enumerated()), id: \.element.id) { index, note in
                    let state = cardState(for: index)
                    let isDeleting = deletingNoteId == note.id

                    IntegratedCarouselCardView(
                        noteData: note,
                        notesManager: notesManager,
                        colorScheme: colorScheme,
                        onFavoriteToggle: {
                            triggerParticleBurst(in: geometry)
                        },
                        onDelete: {
                            // Mark as deleting for animation
                            deletingNoteId = note.id

                            // Adjust current index if needed
                            if currentIndex >= displayNotes.count - 1 && currentIndex > 0 {
                                currentIndex -= 1
                            }

                            // Delete after animation
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                if let noteToDelete = notesManager.notes.first(where: { $0.id == note.id }) {
                                    notesManager.deleteNote(noteToDelete)
                                    deletingNoteId = nil
                                }
                            }
                        }
                    )
                    .scaleEffect(isDeleting ? 0.8 : state.scale)
                    .offset(y: state.zOffset)
                    .opacity(isDeleting ? 0 : state.opacity)
                    .blur(radius: state.blur)
                    .shadow(color: state == .active ? .white.opacity(0.2) : .clear, radius: 20, x: 0, y: 0)
                    .floating(duration: 4.0 + Double(index) * 0.2, distance: 5)
                    .offset(x: dragOffset * 0.3)
                    .animation(.spring(duration: 0.5, bounce: 0.3), value: currentIndex)
                    .animation(.spring(duration: 0.3, bounce: 0.2), value: dragOffset)
                    .animation(.spring(duration: 0.3, bounce: 0.3), value: isDeleting)
                    .zIndex(state == .active ? 10 : Double(displayNotes.count - index))
                }

                // Navigation arrows
                HStack {
                    Button(action: previousCard) {
                        Image(systemName: "chevron.left")
                            .font(.title)
                            .foregroundColor(adaptiveTextColor)
                            .frame(width: 50, height: 50)
                            .background(
                                Circle()
                                    .fill(.ultraThinMaterial)
                                    .opacity(0.6)
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .opacity(currentIndex > 0 ? 1 : 0.3)
                    .disabled(currentIndex == 0)

                    Spacer()

                    Button(action: nextCard) {
                        Image(systemName: "chevron.right")
                            .font(.title)
                            .foregroundColor(adaptiveTextColor)
                            .frame(width: 50, height: 50)
                            .background(
                                Circle()
                                    .fill(.ultraThinMaterial)
                                    .opacity(0.6)
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .opacity(currentIndex < displayNotes.count - 1 ? 1 : 0.3)
                    .disabled(currentIndex == displayNotes.count - 1)
                }
                .padding(.horizontal, 40)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    // MARK: - Progress Dots

    private var progressDots: some View {
        HStack(spacing: 12) {
            ForEach(Array(displayNotes.enumerated()), id: \.element.id) { index, _ in
                Circle()
                    .fill(index == currentIndex ? adaptiveTextColor : adaptiveTextColor.opacity(0.4))
                    .frame(width: index == currentIndex ? 12 : 8, height: index == currentIndex ? 12 : 8)
                    .overlay(
                        Circle()
                            .stroke(adaptiveTextColor.opacity(0.8), lineWidth: index == currentIndex ? 2 : 0)
                            .scaleEffect(index == currentIndex ? 1.3 : 1.0)
                            .opacity(index == currentIndex ? 0.6 : 0)
                    )
                    .shadow(color: adaptiveTextColor.opacity(index == currentIndex ? 0.5 : 0), radius: 8, x: 0, y: 0)
                    .animation(.spring(duration: 0.4, bounce: 0.5), value: currentIndex)
                    .onTapGesture {
                        withAnimation(.spring(duration: 0.5, bounce: 0.3)) {
                            currentIndex = index
                        }
                    }
            }
        }
    }

    // MARK: - Thumbnail Strip

    private var thumbnailStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(Array(displayNotes.enumerated()), id: \.element.id) { index, noteData in
                    IntegratedThumbnailView(noteData: noteData, isActive: index == currentIndex)
                        .onTapGesture {
                            withAnimation(.spring(duration: 0.5, bounce: 0.3)) {
                                currentIndex = index
                            }
                        }
                }
            }
            .padding(.horizontal, 32)
        }
        .frame(height: 100)
    }

    // MARK: - Bottom Bar

    private var bottomBar: some View {
        HStack {
            Text("\(currentIndex + 1) / \(displayNotes.count)")
                .font(.subheadline)
                .foregroundColor(adaptiveTextColor.opacity(0.8))
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(.ultraThinMaterial)
                        .opacity(0.5)
                )

            Spacer()

            Button(action: {}) {
                HStack {
                    Image(systemName: "square.grid.2x2")
                    Text("View All")
                }
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(Color.blueGreen)
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 20)
        .background(
            Rectangle()
                .fill(.ultraThinMaterial)
                .opacity(0.5)
        )
    }

    // MARK: - Helper Methods

    private func cardState(for index: Int) -> CardState {
        let difference = index - currentIndex
        switch difference {
        case 0:
            return .active
        case 1:
            return .behindOne
        case 2:
            return .behindTwo
        default:
            return .hidden
        }
    }

    private func nextCard() {
        guard currentIndex < displayNotes.count - 1 else { return }
        withAnimation(.spring(duration: 0.5, bounce: 0.3)) {
            currentIndex += 1
        }
    }

    private func previousCard() {
        guard currentIndex > 0 else { return }
        withAnimation(.spring(duration: 0.5, bounce: 0.3)) {
            currentIndex -= 1
        }
    }

    private func triggerParticleBurst(in geometry: GeometryProxy) {
        let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2 - 100)
        particleBursts.append(ParticleBurstTrigger(position: center))
    }
}

// MARK: - Integrated Carousel Card View

struct IntegratedCarouselCardView: View {
    let noteData: CarouselNoteData
    let notesManager: NotesManager
    let colorScheme: ColorScheme
    let onFavoriteToggle: () -> Void
    let onDelete: () -> Void

    @Environment(\.openWindow) private var openWindow

    // Adaptive colors based on system appearance
    private var adaptiveTextColor: Color {
        colorScheme == .dark ? .white : .black
    }

    private var adaptiveShadowColor: Color {
        colorScheme == .dark ? .black.opacity(0.3) : .white.opacity(0.3)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            HStack {
                Text(noteData.title)
                    .font(.system(size: 32, weight: .heavy))
                    .foregroundColor(adaptiveTextColor)
                    .shadow(color: adaptiveShadowColor, radius: 2, x: 0, y: 1)

                Spacer()

                // Action buttons
                HStack(spacing: 12) {
                    // Delete button
                    Button(action: {
                        onDelete()
                    }) {
                        Image(systemName: "trash")
                            .font(.title3)
                            .foregroundColor(adaptiveTextColor.opacity(0.8))
                            .shadow(color: adaptiveShadowColor, radius: 2, x: 0, y: 1)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .help("Delete note")

                    // Favorite button
                    Button(action: {
                        // Toggle favorite in actual NotesManager
                        if let note = notesManager.notes.first(where: { $0.id == noteData.id }) {
                            notesManager.toggleFavorite(note)
                        }
                        withAnimation(.spring(duration: 0.3, bounce: 0.6)) {}
                        onFavoriteToggle()
                    }) {
                        Image(systemName: noteData.isFavorite ? "star.fill" : "star")
                            .font(.title2)
                            .foregroundColor(.selectiveYellow)
                            .scaleEffect(noteData.isFavorite ? 1.2 : 1.0)
                            .shadow(color: adaptiveShadowColor, radius: 2, x: 0, y: 1)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .help("Toggle favorite")
                }
            }

            // Note content - scrollable to show all content
            ScrollView(.vertical, showsIndicators: true) {
                Text(noteData.content.isEmpty ? "Empty note" : noteData.content)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(adaptiveTextColor)
                    .shadow(color: adaptiveShadowColor, radius: 2, x: 0, y: 1)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.trailing, 8)
            }
            .frame(maxHeight: 300)
            .scrollIndicators(.visible)

            // Footer metadata and actions
            HStack {
                // Left side - date and folder
                HStack(spacing: 12) {
                    Text(noteData.modifiedAt, style: .date)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(adaptiveTextColor.opacity(0.9))
                        .shadow(color: adaptiveShadowColor, radius: 1, x: 0, y: 1)

                    if let folder = noteData.folder {
                        Text(folder)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(adaptiveTextColor.opacity(0.9))
                            .shadow(color: adaptiveShadowColor, radius: 1, x: 0, y: 1)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(
                                Capsule()
                                    .fill(adaptiveTextColor.opacity(0.15))
                            )
                    }
                }

                Spacer()

                // Right side - edit and copy buttons
                HStack(spacing: 12) {
                    // Copy button
                    Button(action: {
                        // Copy note content to clipboard
                        if let note = notesManager.notes.first(where: { $0.id == noteData.id }) {
                            let plainText = note.content
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(plainText, forType: .string)
                        }
                    }) {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 14))
                            .foregroundColor(adaptiveTextColor.opacity(0.8))
                            .shadow(color: adaptiveShadowColor, radius: 1, x: 0, y: 1)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .help("Copy note content")

                    // Edit button
                    Button(action: {
                        // Open note in edit window
                        notesManager.openNote(noteData.id)
                        openWindow(value: noteData.id)
                    }) {
                        Image(systemName: "pencil")
                            .font(.system(size: 14))
                            .foregroundColor(adaptiveTextColor.opacity(0.8))
                            .shadow(color: adaptiveShadowColor, radius: 1, x: 0, y: 1)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .help("Edit note")
                }
            }
        }
        .padding(32)
        .frame(width: 750, height: 550)
        .glassMorphism(color: noteData.color, opacity: 0.25, borderOpacity: 0.4)
    }
}

// MARK: - CarouselNoteData Model

struct CarouselNoteData: Identifiable {
    let id: UUID
    let title: String
    let content: String
    let color: Color
    let isFavorite: Bool
    let folder: String?
    let modifiedAt: Date
}

// MARK: - Integrated Thumbnail View

struct IntegratedThumbnailView: View {
    let noteData: CarouselNoteData
    let isActive: Bool
    @Environment(\.colorScheme) private var colorScheme

    private var adaptiveTextColor: Color {
        colorScheme == .dark ? .white : .black
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(noteData.title)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(adaptiveTextColor)
                .lineLimit(1)

            // Translucent preview matching carousel background
            Rectangle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.prussianBlue.opacity(0.3),
                            Color.blueGreen.opacity(0.2),
                            Color.skyBlue.opacity(0.3)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 80, height: 60)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.ultraThinMaterial)
                        .opacity(0.4)
                )
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .opacity(isActive ? 0.8 : 0.4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isActive ? adaptiveTextColor : Color.clear, lineWidth: 2)
        )
        .scaleEffect(isActive ? 1.1 : 1.0)
        .shadow(color: isActive ? adaptiveTextColor.opacity(0.5) : .clear, radius: 10)
        .animation(.spring(duration: 0.3, bounce: 0.4), value: isActive)
    }
}

// MARK: - Preview

#Preview {
    CarouselDashboardIntegratedView()
        .environment(NotesManager())
        .frame(width: 1200, height: 800)
}
