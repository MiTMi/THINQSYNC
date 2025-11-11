//
//  CarouselDashboardView.swift
//  thinqsync
//
//  Experimental carousel-style dashboard with glass morphism design
//

import SwiftUI

struct CarouselDashboardView: View {
    @Environment(NotesManager.self) private var notesManager
    @State private var currentIndex: Int = 0
    @State private var particleBursts: [ParticleBurstTrigger] = []
    @State private var isLoading = true
    @State private var dragOffset: CGFloat = 0
    @FocusState private var isFocused: Bool

    // Sample notes for the carousel (will be replaced with real data)
    private var displayNotes: [CarouselNote] {
        [
            CarouselNote(
                title: "Overall Goals",
                items: [
                    "Product launch in Q1 2026",
                    "Focus on Feature X development",
                    "Budget allocation review"
                ],
                color: .blueGreen,
                isFavorite: true
            ),
            CarouselNote(
                title: "Development Tasks",
                items: [
                    "Complete API integration",
                    "Implement user authentication",
                    "Optimize database queries",
                    "Write unit tests"
                ],
                color: .prussianBlue,
                isFavorite: false
            ),
            CarouselNote(
                title: "Design Review",
                items: [
                    "Update color palette",
                    "Refine typography system",
                    "Create component library"
                ],
                color: .selectiveYellow,
                isFavorite: true
            ),
            CarouselNote(
                title: "Marketing Plan",
                items: [
                    "Social media campaign",
                    "Email newsletter design",
                    "Landing page optimization"
                ],
                color: .utOrange,
                isFavorite: false
            ),
            CarouselNote(
                title: "Team Meeting",
                items: [
                    "Q4 retrospective",
                    "Q1 planning session",
                    "Team building activities"
                ],
                color: .skyBlue,
                isFavorite: false
            )
        ]
    }

    var body: some View {
        ZStack {
            // Gradient background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.prussianBlue.opacity(0.3),
                    Color.blueGreen.opacity(0.2),
                    Color.skyBlue.opacity(0.3)
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
                VStack(spacing: 0) {
                    // Top Bar
                    topBar
                        .transition(.move(edge: .top).combined(with: .opacity))

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
                    .foregroundColor(.white)
                Text("ThinqSync")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }

            Spacer()

            // Actions
            HStack(spacing: 12) {
                Button(action: {}) {
                    Image(systemName: "magnifyingglass")
                        .font(.title3)
                        .foregroundColor(.white)
                }
                .buttonStyle(GlassButtonStyle())

                Button(action: {}) {
                    Image(systemName: "gearshape")
                        .font(.title3)
                        .foregroundColor(.white)
                }
                .buttonStyle(GlassButtonStyle())

                Button(action: {}) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(.selectiveYellow)
                }
                .buttonStyle(PlainButtonStyle())
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

    // MARK: - Carousel Container

    private var carouselContainer: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(Array(displayNotes.enumerated()), id: \.offset) { index, note in
                    let state = cardState(for: index)

                    CarouselCardView(
                        note: note,
                        onFavoriteToggle: {
                            triggerParticleBurst(in: geometry)
                        }
                    )
                    .scaleEffect(state.scale)
                    .offset(y: state.zOffset)
                    .opacity(state.opacity)
                    .blur(radius: state.blur)
                    .floating(duration: 4.0 + Double(index) * 0.2, distance: 5)
                    .offset(x: dragOffset * 0.3)
                    .animation(.spring(duration: 0.5, bounce: 0.3), value: currentIndex)
                    .animation(.spring(duration: 0.3, bounce: 0.2), value: dragOffset)
                    .zIndex(state == .active ? 10 : Double(displayNotes.count - index))
                }

                // Navigation arrows
                HStack {
                    Button(action: previousCard) {
                        Image(systemName: "chevron.left")
                            .font(.title)
                            .foregroundColor(.white)
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
                            .foregroundColor(.white)
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
            ForEach(0..<displayNotes.count, id: \.self) { index in
                Circle()
                    .fill(index == currentIndex ? Color.selectiveYellow : Color.white.opacity(0.4))
                    .frame(width: index == currentIndex ? 12 : 8, height: index == currentIndex ? 12 : 8)
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.6), lineWidth: index == currentIndex ? 2 : 0)
                            .scaleEffect(index == currentIndex ? 1.5 : 1.0)
                            .opacity(index == currentIndex ? 0.8 : 0)
                    )
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
                ForEach(Array(displayNotes.enumerated()), id: \.offset) { index, note in
                    ThumbnailView(note: note, isActive: index == currentIndex)
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
                .foregroundColor(.white.opacity(0.8))
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

// MARK: - Carousel Note Model

struct CarouselNote: Identifiable {
    let id = UUID()
    let title: String
    let items: [String]
    let color: Color
    var isFavorite: Bool
}

// MARK: - Carousel Card View

struct CarouselCardView: View {
    let note: CarouselNote
    let onFavoriteToggle: () -> Void
    @State private var isFavorite: Bool

    init(note: CarouselNote, onFavoriteToggle: @escaping () -> Void) {
        self.note = note
        self.onFavoriteToggle = onFavoriteToggle
        self._isFavorite = State(initialValue: note.isFavorite)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            HStack {
                Text(note.title)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                Spacer()

                Button(action: {
                    withAnimation(.spring(duration: 0.3, bounce: 0.6)) {
                        isFavorite.toggle()
                    }
                    onFavoriteToggle()
                }) {
                    Image(systemName: isFavorite ? "star.fill" : "star")
                        .font(.title2)
                        .foregroundColor(.selectiveYellow)
                        .scaleEffect(isFavorite ? 1.2 : 1.0)
                        .animation(.spring(duration: 0.3, bounce: 0.6), value: isFavorite)
                }
                .buttonStyle(PlainButtonStyle())
            }

            // List items
            VStack(alignment: .leading, spacing: 16) {
                ForEach(Array(note.items.enumerated()), id: \.offset) { index, item in
                    HStack(alignment: .top, spacing: 12) {
                        Circle()
                            .fill(Color.white.opacity(0.8))
                            .frame(width: 8, height: 8)
                            .padding(.top, 6)

                        Text(item)
                            .font(.body)
                            .foregroundColor(.white.opacity(0.95))
                            .multilineTextAlignment(.leading)
                    }
                    .transition(.asymmetric(
                        insertion: .move(edge: .leading).combined(with: .opacity),
                        removal: .opacity
                    ))
                    .animation(.spring(duration: 0.4, bounce: 0.3).delay(Double(index) * 0.1), value: item)
                }
            }

            Spacer()
        }
        .padding(32)
        .frame(width: 450, height: 500)
        .glassMorphism(color: note.color, opacity: 0.2, borderOpacity: 0.3)
    }
}

// MARK: - Thumbnail View

struct ThumbnailView: View {
    let note: CarouselNote
    let isActive: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(note.title)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .lineLimit(1)

            Rectangle()
                .fill(note.color.opacity(0.6))
                .frame(width: 80, height: 60)
                .cornerRadius(8)
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .opacity(isActive ? 0.8 : 0.4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isActive ? Color.selectiveYellow : Color.clear, lineWidth: 2)
        )
        .scaleEffect(isActive ? 1.1 : 1.0)
        .shadow(color: isActive ? Color.selectiveYellow.opacity(0.5) : .clear, radius: 10)
        .animation(.spring(duration: 0.3, bounce: 0.4), value: isActive)
    }
}

// MARK: - Glass Button Style

struct GlassButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(12)
            .background(
                Circle()
                    .fill(.ultraThinMaterial)
                    .opacity(configuration.isPressed ? 0.8 : 0.6)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(duration: 0.2, bounce: 0.5), value: configuration.isPressed)
    }
}

// MARK: - Preview

#Preview {
    CarouselDashboardView()
        .environment(NotesManager())
        .frame(width: 1200, height: 800)
}
