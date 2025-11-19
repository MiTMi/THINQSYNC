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
            // Darkened colors for dark mode (25% darker)
            switch self {
            case .green:
                return Color(hex: "1a9f4a") // Darker green
            case .yellow:
                return Color(hex: "cc9202") // Darker yellow
            case .orange:
                return Color(hex: "c96a00") // Darker orange
            case .blue:
                return Color(hex: "1a7e96") // Darker blue
            case .purple:
                return Color(hex: "8644c5") // Darker purple
            case .pink:
                return Color(hex: "2a2a2a") // Dark gray instead of white
            }
        } else {
            // Original vibrant colors for light mode
            switch self {
            case .green:
                return Color(hex: "22c55e") // Neo-brutalism Green
            case .yellow:
                return Color(hex: "ffb703") // Neo-brutalism Yellow
            case .orange:
                return Color(hex: "fb8500") // Neo-brutalism Orange
            case .blue:
                return Color(hex: "219ebc") // Neo-brutalism Blue
            case .purple:
                return Color(hex: "a855f7") // Neo-brutalism Purple
            case .pink:
                return .white // Neo-brutalism White
            }
        }
    }

    // NSColor version for MenuBarExtra rendering
    var nsBackgroundColor: NSColor {
        switch self {
        case .green:
            return NSColor(red: 0x22/255, green: 0xc5/255, blue: 0x5e/255, alpha: 1.0) // #22c55e
        case .yellow:
            return NSColor(red: 0xff/255, green: 0xb7/255, blue: 0x03/255, alpha: 1.0) // #ffb703
        case .orange:
            return NSColor(red: 0xfb/255, green: 0x85/255, blue: 0x00/255, alpha: 1.0) // #fb8500
        case .blue:
            return NSColor(red: 0x21/255, green: 0x9e/255, blue: 0xbc/255, alpha: 1.0) // #219ebc
        case .purple:
            return NSColor(red: 0xa8/255, green: 0x55/255, blue: 0xf7/255, alpha: 1.0) // #a855f7
        case .pink:
            return NSColor.white // White
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
