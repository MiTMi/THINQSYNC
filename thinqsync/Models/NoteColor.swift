//
//  NoteColor.swift
//  thinqsync
//
//  Created by Michael   on 31/10/2025.
//

import SwiftUI
import AppKit

enum NoteColor: String, Codable, CaseIterable, Sendable {
    case green
    case yellow
    case orange
    case blue
    case purple
    case pink

    var backgroundColor: Color {
        backgroundColor(for: .light)
    }

    // Adaptive background color based on color scheme
    func backgroundColor(for colorScheme: ColorScheme) -> Color {
        if colorScheme == .dark {
            // Darkened colors for dark mode
            switch self {
            case .green:
                return Color(hex: "1a9f4a") // Darker green (unchanged)
            case .yellow:
                return Color(hex: "d4af37") // Softer gold for dark mode (was cc9202)
            case .orange:
                return Color(hex: "e89a5c") // Softer orange for dark mode (was c96a00)
            case .blue:
                return Color(hex: "1a7e96") // Darker blue (unchanged)
            case .purple:
                return Color(hex: "9370db") // Softer purple for dark mode (was 8644c5)
            case .pink:
                return Color(hex: "2a2a2a") // Dark gray (unchanged)
            }
        } else {
            // Colors for light mode - green & blue unchanged, others toned down
            switch self {
            case .green:
                return Color(hex: "22c55e") // Neo-brutalism Green (unchanged)
            case .yellow:
                return Color(hex: "ffd966") // Softer yellow (was ffb703)
            case .orange:
                return Color(hex: "ffb366") // Softer orange (was fb8500)
            case .blue:
                return Color(hex: "219ebc") // Neo-brutalism Blue (unchanged)
            case .purple:
                return Color(hex: "c299ff") // Softer purple (was a855f7)
            case .pink:
                return Color(hex: "fff9f0") // Warm off-white (was pure white)
            }
        }
    }

    // NSColor version for MenuBarExtra rendering
    var nsBackgroundColor: NSColor {
        switch self {
        case .green:
            return NSColor(red: 0x22/255, green: 0xc5/255, blue: 0x5e/255, alpha: 1.0) // #22c55e (unchanged)
        case .yellow:
            return NSColor(red: 0xff/255, green: 0xd9/255, blue: 0x66/255, alpha: 1.0) // #ffd966
        case .orange:
            return NSColor(red: 0xff/255, green: 0xb3/255, blue: 0x66/255, alpha: 1.0) // #ffb366
        case .blue:
            return NSColor(red: 0x21/255, green: 0x9e/255, blue: 0xbc/255, alpha: 1.0) // #219ebc (unchanged)
        case .purple:
            return NSColor(red: 0xc2/255, green: 0x99/255, blue: 0xff/255, alpha: 1.0) // #c299ff
        case .pink:
            return NSColor(red: 0xff/255, green: 0xf9/255, blue: 0xf0/255, alpha: 1.0) // #fff9f0
        }
    }

    // Adaptive text color based on color scheme and note color
    func textColor(for colorScheme: ColorScheme) -> Color {
        if colorScheme == .dark {
            // In dark mode: white text on dark colors, black on bright colors
            switch self {
            case .green, .blue, .purple, .pink:
                return .white
            case .yellow, .orange:
                return .black
            }
        } else {
            // In light mode: black text on all colors
            return .black
        }
    }

    // Adaptive icon color based on color scheme
    func iconColor(for colorScheme: ColorScheme) -> Color {
        if colorScheme == .dark {
            // Match text color in dark mode
            switch self {
            case .green, .blue, .purple, .pink:
                return Color.white.opacity(0.9)
            case .yellow, .orange:
                return Color.black.opacity(0.7)
            }
        } else {
            // Black icons in light mode
            return Color.black.opacity(0.7)
        }
    }

    // Outer border color for two-tone effect
    func outerBorderColor(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color.white.opacity(0.9) : .black
    }

    // Inner border color for two-tone effect
    func innerBorderColor(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color.black.opacity(0.5) : .clear
    }

    // Legacy non-adaptive text color (for backwards compatibility)
    var textColor: Color {
        return .black // Black text for all neo-brutalism colors
    }

    // Legacy non-adaptive icon color (for backwards compatibility)
    var iconColor: Color {
        return Color.black.opacity(0.7) // Black icons for all neo-brutalism colors
    }
}
