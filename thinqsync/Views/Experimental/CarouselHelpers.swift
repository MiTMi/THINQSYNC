//
//  CarouselHelpers.swift
//  thinqsync
//
//  Helper types and extensions for the Carousel Dashboard
//

import SwiftUI

// MARK: - Color Extensions

extension Color {
    // Glass Morphism Theme Colors (from HTML prototype)
    static let skyBlue = Color(hex: "8ecae6")
    static let blueGreen = Color(hex: "219ebc")
    static let prussianBlue = Color(hex: "023047")
    static let selectiveYellow = Color(hex: "ffb703")
    static let utOrange = Color(hex: "fb8500")

    // Initialize from hex string
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Animation Values

struct AnimationValues {
    var scale: Double = 1.0
    var rotation: Angle = .zero
    var verticalOffset: Double = 0
    var horizontalOffset: Double = 0
    var opacity: Double = 1.0
}

// MARK: - Particle System

struct Particle: Identifiable {
    let id = UUID()
    var position: CGPoint
    var angle: Double
    var distance: Double
    var opacity: Double = 1.0
}

// MARK: - Card Position States

enum CardState {
    case active
    case behindOne
    case behindTwo
    case hidden

    var scale: Double {
        switch self {
        case .active: return 1.0
        case .behindOne: return 0.95
        case .behindTwo: return 0.9
        case .hidden: return 0.85
        }
    }

    var zOffset: Double {
        switch self {
        case .active: return 0
        case .behindOne: return -20
        case .behindTwo: return -40
        case .hidden: return -60
        }
    }

    var opacity: Double {
        switch self {
        case .active: return 1.0
        case .behindOne: return 0.5
        case .behindTwo: return 0.3
        case .hidden: return 0.0
        }
    }

    var blur: Double {
        switch self {
        case .active: return 0
        case .behindOne: return 8
        case .behindTwo: return 12
        case .hidden: return 15
        }
    }
}

// MARK: - Glass Morphism Modifier

struct GlassMorphismModifier: ViewModifier {
    var color: Color
    var opacity: Double = 0.15
    var blur: Double = 15
    var borderOpacity: Double = 0.25
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    // Use the actual color parameter
                    RoundedRectangle(cornerRadius: 20)
                        .fill(color)

                    // Subtle gradient overlay for depth
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.1),
                                    Color.clear
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
            )
            .overlay(
                // Border with subtle transparency
                RoundedRectangle(cornerRadius: 20)
                    .strokeBorder(
                        Color.black.opacity(0.15),
                        lineWidth: 1
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(
                color: Color.black.opacity(0.15),
                radius: 20,
                x: 0,
                y: 10
            )
            .shadow(
                color: Color.black.opacity(0.08),
                radius: 8,
                x: 0,
                y: 4
            )
    }
}

extension View {
    func glassMorphism(color: Color, opacity: Double = 0.15, blur: Double = 15, borderOpacity: Double = 0.25) -> some View {
        modifier(GlassMorphismModifier(color: color, opacity: opacity, blur: blur, borderOpacity: borderOpacity))
    }
}

// MARK: - Ripple Effect Modifier

struct RippleEffect: ViewModifier {
    @State private var ripples: [UUID] = []

    func body(content: Content) -> some View {
        content
            .overlay(
                ZStack {
                    ForEach(ripples, id: \.self) { id in
                        Circle()
                            .stroke(Color.white.opacity(0.5), lineWidth: 2)
                            .scaleEffect(0)
                            .opacity(1)
                            .onAppear {
                                withAnimation(.easeOut(duration: 0.6)) {
                                    // Animation is implicit through the removal
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                                    ripples.removeAll { $0 == id }
                                }
                            }
                    }
                }
            )
    }

    func trigger() {
        ripples.append(UUID())
    }
}

// MARK: - Floating Animation Modifier

struct FloatingModifier: ViewModifier {
    @State private var isFloating = false
    let duration: Double
    let distance: Double

    func body(content: Content) -> some View {
        content
            .offset(y: isFloating ? -distance : 0)
            .onAppear {
                withAnimation(
                    .easeInOut(duration: duration)
                    .repeatForever(autoreverses: true)
                ) {
                    isFloating = true
                }
            }
    }
}

extension View {
    func floating(duration: Double = 4.0, distance: Double = 5) -> some View {
        modifier(FloatingModifier(duration: duration, distance: distance))
    }
}

// MARK: - Glass Button Style

struct GlassButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) private var colorScheme

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(12)
            .background(
                Circle()
                    .fill(colorScheme == .dark ?
                          Color(white: 0.2) :
                          Color(white: 0.96))
                    .overlay(
                        Circle()
                            .strokeBorder(
                                colorScheme == .dark ?
                                    Color.white.opacity(0.1) :
                                    Color.black.opacity(0.06),
                                lineWidth: 1
                            )
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .opacity(configuration.isPressed ? 0.7 : 1.0)
            .animation(.spring(duration: 0.2, bounce: 0.5), value: configuration.isPressed)
    }
}
