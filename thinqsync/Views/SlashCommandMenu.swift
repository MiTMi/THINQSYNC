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
            // Search hint
            if !searchText.isEmpty {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                    Text("Searching for: \(searchText)")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color(nsColor: .controlBackgroundColor))
            }

            // Commands list
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(Array(filteredCommands.enumerated()), id: \.element.id) { index, command in
                        SlashCommandRow(
                            command: command,
                            isSelected: index == selectedIndex
                        )
                        .contentShape(Rectangle())
                        .onTapGesture {
                            onCommandSelected(command)
                            isPresented = false
                        }
                        .background(index == selectedIndex ? Color.accentColor.opacity(0.15) : Color.clear)

                        if index < filteredCommands.count - 1 {
                            Divider()
                                .padding(.leading, 40)
                        }
                    }
                }
            }
            .frame(maxHeight: 250)
        }
        .frame(width: 280)
        .background(Color(nsColor: .windowBackgroundColor))
        .cornerRadius(8)
        .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 5)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(nsColor: .separatorColor), lineWidth: 1)
        )
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

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: command.icon)
                .font(.system(size: 14))
                .foregroundColor(isSelected ? .accentColor : .secondary)
                .frame(width: 16)

            VStack(alignment: .leading, spacing: 2) {
                Text(command.title)
                    .font(.system(size: 13, weight: isSelected ? .medium : .regular))
                    .foregroundColor(.primary)

                Text(command.description)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}

#Preview {
    SlashCommandMenu(
        isPresented: .constant(true),
        searchText: .constant(""),
        onCommandSelected: { _ in }
    )
}
