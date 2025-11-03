//
//  SlashCommandMenu.swift
//  thinqsync
//
//  Created by Claude on 03/11/2025.
//

import SwiftUI
import AppKit

enum SlashCommand: Identifiable, CaseIterable {
    case heading1
    case heading2
    case heading3
    case bold
    case italic
    case underline
    case bulletList
    case numberList
    case divider
    case clearFormatting

    var id: String { title }

    var title: String {
        switch self {
        case .heading1: return "Heading 1"
        case .heading2: return "Heading 2"
        case .heading3: return "Heading 3"
        case .bold: return "Bold"
        case .italic: return "Italic"
        case .underline: return "Underline"
        case .bulletList: return "Bullet List"
        case .numberList: return "Numbered List"
        case .divider: return "Divider"
        case .clearFormatting: return "Clear Formatting"
        }
    }

    var icon: String {
        switch self {
        case .heading1: return "textformat.size.larger"
        case .heading2: return "textformat.size"
        case .heading3: return "textformat.size.smaller"
        case .bold: return "bold"
        case .italic: return "italic"
        case .underline: return "underline"
        case .bulletList: return "list.bullet"
        case .numberList: return "list.number"
        case .divider: return "minus.rectangle"
        case .clearFormatting: return "trash"
        }
    }

    var description: String {
        switch self {
        case .heading1: return "Large section heading"
        case .heading2: return "Medium section heading"
        case .heading3: return "Small section heading"
        case .bold: return "Make text bold"
        case .italic: return "Make text italic"
        case .underline: return "Underline text"
        case .bulletList: return "Create a bulleted list"
        case .numberList: return "Create a numbered list"
        case .divider: return "Insert a horizontal line"
        case .clearFormatting: return "Remove all formatting"
        }
    }
}

struct SlashCommandMenu: View {
    @Binding var isPresented: Bool
    @Binding var searchText: String
    let onCommandSelected: (SlashCommand) -> Void

    @State private var selectedIndex = 0
    @State private var hoveredIndex: Int?

    var filteredCommands: [SlashCommand] {
        if searchText.isEmpty {
            return Array(SlashCommand.allCases)
        } else {
            return SlashCommand.allCases.filter { command in
                command.title.localizedCaseInsensitiveContains(searchText) ||
                command.description.localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Commands list with scrolling
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(Array(filteredCommands.enumerated()), id: \.element.id) { index, command in
                        SlashCommandRow(
                            command: command,
                            isSelected: index == selectedIndex,
                            isHovered: index == hoveredIndex
                        )
                        .contentShape(Rectangle())
                        .onTapGesture {
                            onCommandSelected(command)
                            isPresented = false
                        }
                        .onHover { hovering in
                            hoveredIndex = hovering ? index : nil
                        }
                    }
                }
                .padding(.vertical, 4)
            }
            .frame(maxHeight: 200)
        }
        .frame(width: 200)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(nsColor: .windowBackgroundColor).opacity(0.95))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.3), radius: 24, x: 0, y: 10)
        .onChange(of: searchText) { _, _ in
            selectedIndex = 0
        }
    }

    func moveSelection(by offset: Int) {
        let newIndex = selectedIndex + offset
        if newIndex >= 0 && newIndex < filteredCommands.count {
            selectedIndex = newIndex
        }
    }

    func executeSelectedCommand() {
        guard selectedIndex < filteredCommands.count else { return }
        onCommandSelected(filteredCommands[selectedIndex])
        isPresented = false
    }
}

struct SlashCommandRow: View {
    let command: SlashCommand
    let isSelected: Bool
    let isHovered: Bool

    var body: some View {
        HStack(spacing: 8) {
            // Icon on the left
            Image(systemName: command.icon)
                .font(.system(size: 11))
                .foregroundColor(Color(nsColor: .secondaryLabelColor))
                .frame(width: 14)

            // Title
            Text(command.title)
                .font(.system(size: 11.5))
                .foregroundColor(Color(nsColor: .labelColor))

            Spacer()

            // Chevron on the right
            Image(systemName: "chevron.right")
                .font(.system(size: 8, weight: .semibold))
                .foregroundColor(Color(nsColor: .tertiaryLabelColor))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            isHovered ? Color(nsColor: .controlAccentColor).opacity(0.2) : Color.clear
        )
    }
}

#Preview {
    SlashCommandMenu(
        isPresented: .constant(true),
        searchText: .constant(""),
        onCommandSelected: { _ in }
    )
}
