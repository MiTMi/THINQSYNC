//
//  NoteColor.swift
//  thinqsync
//
//  Created by Michael   on 31/10/2025.
//

import SwiftUI

enum NoteColor: String, Codable, CaseIterable, Sendable {
    case green
    case yellow
    case orange
    case blue
    case purple
    case white

    var backgroundColor: Color {
        switch self {
        case .green:
            return Color(red: 0.20, green: 0.38, blue: 0.26)
        case .yellow:
            return Color(red: 0.95, green: 0.85, blue: 0.4)
        case .orange:
            return Color(red: 0.95, green: 0.6, blue: 0.3)
        case .blue:
            return Color(red: 0.3, green: 0.5, blue: 0.8)
        case .purple:
            return Color(red: 0.6, green: 0.4, blue: 0.8)
        case .white:
            return Color(red: 0.95, green: 0.95, blue: 0.95)
        }
    }

    var textColor: Color {
        switch self {
        case .white:
            return Color(red: 0.2, green: 0.2, blue: 0.2) // Dark gray for white
        case .yellow:
            return Color(red: 0.3, green: 0.25, blue: 0.0) // Dark brown for yellow
        case .orange:
            return Color(red: 0.4, green: 0.2, blue: 0.1) // Dark orange-brown
        case .green:
            return Color.white // Pure white for green
        default:
            return Color.white
        }
    }

    var iconColor: Color {
        switch self {
        case .green:
            return Color(red: 0.2, green: 0.5, blue: 0.3)
        case .yellow:
            return Color(red: 0.8, green: 0.7, blue: 0.2)
        case .orange:
            return Color(red: 0.9, green: 0.5, blue: 0.2)
        case .blue:
            return Color(red: 0.3, green: 0.5, blue: 0.8)
        case .purple:
            return Color(red: 0.6, green: 0.4, blue: 0.8)
        case .white:
            return Color(red: 0.7, green: 0.7, blue: 0.7)
        }
    }
}
