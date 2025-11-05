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
    case strikethrough
    case bulletList
    case numberList
    case divider
    case clearFormatting
    case aiImproveWriting
    case aiSummarize
    case aiExpand
    case aiFixGrammar

    var id: String { title }

    var title: String {
        switch self {
        case .heading1: return "Heading 1"
        case .heading2: return "Heading 2"
        case .heading3: return "Heading 3"
        case .bold: return "Bold"
        case .italic: return "Italic"
        case .underline: return "Underline"
        case .strikethrough: return "Strikethrough"
        case .bulletList: return "Bullet List"
        case .numberList: return "Numbered List"
        case .divider: return "Divider"
        case .clearFormatting: return "Clear Formatting"
        case .aiImproveWriting: return "AI: Improve Writing"
        case .aiSummarize: return "AI: Summarize"
        case .aiExpand: return "AI: Expand"
        case .aiFixGrammar: return "AI: Fix Grammar"
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
        case .strikethrough: return "strikethrough"
        case .bulletList: return "list.bullet"
        case .numberList: return "list.number"
        case .divider: return "minus.rectangle"
        case .clearFormatting: return "trash"
        case .aiImproveWriting: return "wand.and.stars"
        case .aiSummarize: return "doc.text.magnifyingglass"
        case .aiExpand: return "arrow.up.left.and.arrow.down.right"
        case .aiFixGrammar: return "checkmark.seal"
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
        case .strikethrough: return "Strikethrough text"
        case .bulletList: return "Create a bulleted list"
        case .numberList: return "Create a numbered list"
        case .divider: return "Insert a horizontal line"
        case .clearFormatting: return "Remove all formatting"
        case .aiImproveWriting: return "Enhance clarity and style"
        case .aiSummarize: return "Create a concise summary"
        case .aiExpand: return "Add more detail and context"
        case .aiFixGrammar: return "Correct grammar and spelling"
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
                        Button(action: {
                            onCommandSelected(command)
                            isPresented = false
                        }) {
                            SlashCommandRow(
                                command: command,
                                isSelected: index == selectedIndex,
                                isHovered: index == hoveredIndex
                            )
                        }
                        .buttonStyle(.plain)
                        .onHover { hovering in
                            hoveredIndex = hovering ? index : nil
                        }
                    }
                }
                .padding(.vertical, 4)
            }
            .frame(maxHeight: 220)
        }
        .frame(width: 220)
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
        HStack(spacing: 9) {
            // Icon on the left
            Image(systemName: command.icon)
                .font(.system(size: 12))
                .foregroundColor(Color(nsColor: .secondaryLabelColor))
                .frame(width: 15)

            // Title
            Text(command.title)
                .font(.system(size: 12.5))
                .foregroundColor(Color(nsColor: .labelColor))

            Spacer()

            // Chevron on the right
            Image(systemName: "chevron.right")
                .font(.system(size: 9, weight: .semibold))
                .foregroundColor(Color(nsColor: .tertiaryLabelColor))
        }
        .padding(.horizontal, 11)
        .padding(.vertical, 7)
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
