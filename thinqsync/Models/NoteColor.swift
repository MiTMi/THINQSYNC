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
            return Color(red: 19/255, green: 81/255, blue: 44/255)
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
        case .white, .yellow, .orange:
            return Color.black // Black text for light backgrounds
        case .green, .blue, .purple:
            return Color.white // White text for dark backgrounds
        }
    }

    var iconColor: Color {
        switch self {
        case .white, .yellow, .orange:
            return Color.black.opacity(0.7) // Slightly transparent black for light backgrounds
        case .green, .blue, .purple:
            return Color.white.opacity(0.9) // Slightly transparent white for dark backgrounds
        }
    }
}
