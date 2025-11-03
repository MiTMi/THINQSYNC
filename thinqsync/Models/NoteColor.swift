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
        switch self {
        case .green:
            return Color(red: 0x4D/255, green: 0xD0/255, blue: 0x91/255) // #4DD091 Mint Green
        case .yellow:
            return Color(red: 0xFF/255, green: 0xEC/255, blue: 0x59/255) // #FFEC59 Bright Yellow
        case .orange:
            return Color(red: 0xFF/255, green: 0xA2/255, blue: 0x3A/255) // #FFA23A Orange
        case .blue:
            return Color(red: 0x00/255, green: 0xA5/255, blue: 0xE3/255) // #00A5E3 Bright Blue
        case .purple:
            return Color(red: 0xC0/255, green: 0x57/255, blue: 0x80/255) // #C05780 Mauve Purple
        case .pink:
            return Color(red: 0xFF/255, green: 0x96/255, blue: 0xC5/255) // #FF96C5 Soft Pink
        }
    }

    // NSColor version for MenuBarExtra rendering
    var nsBackgroundColor: NSColor {
        switch self {
        case .green:
            return NSColor(red: 0x4D/255, green: 0xD0/255, blue: 0x91/255, alpha: 1.0) // #4DD091
        case .yellow:
            return NSColor(red: 0xFF/255, green: 0xEC/255, blue: 0x59/255, alpha: 1.0) // #FFEC59
        case .orange:
            return NSColor(red: 0xFF/255, green: 0xA2/255, blue: 0x3A/255, alpha: 1.0) // #FFA23A
        case .blue:
            return NSColor(red: 0x00/255, green: 0xA5/255, blue: 0xE3/255, alpha: 1.0) // #00A5E3
        case .purple:
            return NSColor(red: 0xC0/255, green: 0x57/255, blue: 0x80/255, alpha: 1.0) // #C05780
        case .pink:
            return NSColor(red: 0xFF/255, green: 0x96/255, blue: 0xC5/255, alpha: 1.0) // #FF96C5
        }
    }

    var textColor: Color {
        switch self {
        case .green, .yellow, .orange, .pink:
            return Color.black // Black text for bright backgrounds
        case .blue, .purple:
            return Color.white // White text for darker backgrounds
        }
    }

    var iconColor: Color {
        switch self {
        case .green, .yellow, .orange, .pink:
            return Color.black.opacity(0.7) // Slightly transparent black for bright backgrounds
        case .blue, .purple:
            return Color.white.opacity(0.9) // Slightly transparent white for darker backgrounds
        }
    }
}
