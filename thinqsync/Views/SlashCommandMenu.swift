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
            // Commands list
            ScrollView {
                VStack(spacing: 2) {
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
                .padding(.vertical, 6)
            }
            .frame(maxHeight: 280)
        }
        .frame(width: 300)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color(nsColor: .separatorColor).opacity(0.5), lineWidth: 0.5)
        )
        .shadow(color: Color.black.opacity(0.25), radius: 20, x: 0, y: 8)
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
        HStack(spacing: 14) {
            // Icon on the left
            Image(systemName: command.icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.primary)
                .frame(width: 24, height: 24)

            // Title
            Text(command.title)
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(.primary)

            Spacer()

            // Chevron on the right
            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.secondary.opacity(0.6))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isHovered ? Color(nsColor: .controlAccentColor).opacity(0.12) :
                      isSelected ? Color(nsColor: .controlAccentColor).opacity(0.08) :
                      Color.clear)
        )
        .padding(.horizontal, 6)
    }
}

#Preview {
    SlashCommandMenu(
        isPresented: .constant(true),
        searchText: .constant(""),
        onCommandSelected: { _ in }
    )
}
