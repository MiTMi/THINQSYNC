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

    // Text color - always black for neo-brutalism style (good contrast on all vibrant colors)
    func textColor(for colorScheme: ColorScheme) -> Color {
        return .black
    }

    // Icon color - always black for neo-brutalism style
    func iconColor(for colorScheme: ColorScheme) -> Color {
        return Color.black.opacity(0.7)
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
