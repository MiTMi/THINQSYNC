//
//  FontPickerGrid.swift
//  thinqsync
//
//  Created by Claude on 02/04/2026.
//

import SwiftUI

struct FontOption: Identifiable {
    let id = UUID()
    let name: String
    let fontName: String  // The actual NSFont name

    var nsFont: NSFont? {
        NSFont(name: fontName, size: 22)
    }

    var previewFont: Font {
        if fontName == ".AppleSystemUIFont" {
            return .system(size: 22)
        }
        return .custom(fontName, size: 22)
    }
}

struct FontPickerGrid: View {
    let onFontSelected: (FontOption) -> Void
    let onDismiss: () -> Void

    @State private var selectedFont: String = ".AppleSystemUIFont"
    @State private var hoveredFont: String?
    @State private var appeared = false

    private let columns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8)
    ]

    static let fonts: [FontOption] = [
        FontOption(name: "Default", fontName: ".AppleSystemUIFont"),
        FontOption(name: "Rounded", fontName: ".AppleSystemUIFontRounded-Regular"),
        FontOption(name: "Georgia", fontName: "Georgia"),
        FontOption(name: "Avenir", fontName: "Avenir-Medium"),
        FontOption(name: "Futura", fontName: "Futura-Medium"),
        FontOption(name: "Baskerville", fontName: "Baskerville"),
        FontOption(name: "Didot", fontName: "Didot"),
        FontOption(name: "Palatino", fontName: "Palatino-Roman"),
        FontOption(name: "Typewriter", fontName: "AmericanTypewriter"),
        FontOption(name: "Courier", fontName: "CourierNewPSMT"),
        FontOption(name: "Menlo", fontName: "Menlo-Regular"),
        FontOption(name: "Gill Sans", fontName: "GillSans"),
        FontOption(name: "Optima", fontName: "Optima-Regular"),
        FontOption(name: "Copperplate", fontName: "Copperplate"),
        FontOption(name: "Marker Felt", fontName: "MarkerFelt-Wide"),
        FontOption(name: "Noteworthy", fontName: "Noteworthy-Bold"),
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Choose Font")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color(nsColor: .labelColor))
                Spacer()
                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(Color(nsColor: .tertiaryLabelColor))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 12)
            .padding(.top, 10)
            .padding(.bottom, 8)

            // Font grid
            ScrollView {
                LazyVGrid(columns: columns, spacing: 8) {
                    ForEach(Array(FontPickerGrid.fonts.enumerated()), id: \.element.id) { index, fontOption in
                        FontCard(
                            fontOption: fontOption,
                            isSelected: selectedFont == fontOption.fontName,
                            isHovered: hoveredFont == fontOption.fontName,
                            appeared: appeared,
                            index: index
                        )
                        .onTapGesture {
                            withAnimation(.spring(duration: 0.2, bounce: 0.3)) {
                                selectedFont = fontOption.fontName
                            }
                            onFontSelected(fontOption)
                        }
                        .onHover { hovering in
                            withAnimation(.easeInOut(duration: 0.15)) {
                                hoveredFont = hovering ? fontOption.fontName : nil
                            }
                        }
                    }
                }
                .padding(.horizontal, 10)
                .padding(.bottom, 10)
            }
            .frame(maxHeight: 320)
        }
        .frame(width: 340)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(nsColor: .windowBackgroundColor).opacity(0.95))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.35), radius: 24, x: 0, y: 10)
        .onAppear {
            // Trigger the staggered flip-in animation
            withAnimation(.spring(duration: 0.5, bounce: 0.25)) {
                appeared = true
            }
        }
    }
}

struct FontCard: View {
    let fontOption: FontOption
    let isSelected: Bool
    let isHovered: Bool
    let appeared: Bool
    let index: Int

    // Staggered delay per card based on row/column position
    private var staggerDelay: Double {
        let row = index / 4
        let col = index % 4
        return Double(row + col) * 0.04
    }

    var body: some View {
        VStack(spacing: 4) {
            Text("Abc")
                .font(fontOption.previewFont)
                .foregroundColor(Color(nsColor: .labelColor))
                .frame(height: 36)
                .frame(maxWidth: .infinity)

            Text(fontOption.name)
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(Color(nsColor: .secondaryLabelColor))
                .lineLimit(1)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 4)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(
                    isSelected ? Color.accentColor : Color.white.opacity(isHovered ? 0.15 : 0.06),
                    lineWidth: isSelected ? 2 : 1
                )
        )
        .scaleEffect(isHovered && !isSelected ? 1.06 : 1.0)
        .scaleEffect(isSelected ? 0.96 : 1.0)
        .shadow(color: isHovered ? Color.white.opacity(0.06) : Color.clear, radius: 6, x: 0, y: 2)
        // Flip-in animation: cards start flipped back and rotate into view
        .rotation3DEffect(
            .degrees(appeared ? 0 : -90),
            axis: (x: 1, y: 0, z: 0),
            perspective: 0.4
        )
        .opacity(appeared ? 1 : 0)
        .animation(
            .spring(duration: 0.45, bounce: 0.3).delay(staggerDelay),
            value: appeared
        )
        .animation(.easeInOut(duration: 0.15), value: isHovered)
        .animation(.spring(duration: 0.2, bounce: 0.3), value: isSelected)
    }

    private var cardBackground: Color {
        if isSelected {
            return Color.accentColor.opacity(0.15)
        } else if isHovered {
            return Color(nsColor: .controlBackgroundColor).opacity(1.0)
        } else {
            return Color(nsColor: .controlBackgroundColor).opacity(0.6)
        }
    }
}

// MARK: - Floating Font Picker Panel

/// Shows the FontPickerGrid in a floating NSPanel that isn't clipped by parent views.
@MainActor
class FontPickerPanel {
    private var panel: NSPanel?
    private var eventMonitor: Any?

    func show(relativeTo textView: NSTextView, cursorLocation: NSPoint, onFontSelected: @escaping (FontOption) -> Void) {
        dismiss()

        guard let parentWindow = textView.window else { return }

        // Convert cursor position to screen coordinates
        let textViewPoint = NSPoint(
            x: cursorLocation.x + textView.textContainerInset.width,
            y: cursorLocation.y + textView.textContainerInset.height
        )
        let windowPoint = textView.convert(textViewPoint, to: nil)
        var screenPoint = parentWindow.convertPoint(toScreen: windowPoint)

        let panelWidth: CGFloat = 350
        let panelHeight: CGFloat = 380

        // Position below cursor, or above if not enough space below
        let screenFrame = parentWindow.screen?.visibleFrame ?? NSScreen.main!.visibleFrame
        if screenPoint.y - panelHeight - 10 < screenFrame.minY {
            // Not enough space below, show above
            screenPoint.y += 30
        } else {
            // Show below cursor
            screenPoint.y -= (panelHeight + 10)
        }

        // Keep within horizontal screen bounds
        screenPoint.x = min(screenPoint.x, screenFrame.maxX - panelWidth - 10)
        screenPoint.x = max(screenPoint.x, screenFrame.minX + 10)

        let panel = NSPanel(
            contentRect: NSRect(x: screenPoint.x, y: screenPoint.y, width: panelWidth, height: panelHeight),
            styleMask: [.nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        panel.isFloatingPanel = true
        panel.level = .popUpMenu
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = false
        panel.titlebarAppearsTransparent = true
        panel.titleVisibility = .hidden
        panel.isMovable = false

        let hostingView = NSHostingView(rootView:
            FontPickerGrid(
                onFontSelected: { [weak self] fontOption in
                    onFontSelected(fontOption)
                    self?.dismiss()
                },
                onDismiss: { [weak self] in
                    self?.dismiss()
                }
            )
        )
        panel.contentView = hostingView

        parentWindow.addChildWindow(panel, ordered: .above)
        panel.orderFront(nil)
        self.panel = panel

        // Monitor for clicks outside the panel to dismiss
        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            guard let self, let panel = self.panel else { return event }
            if event.window !== panel {
                self.dismiss()
            }
            return event
        }
    }

    func dismiss() {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
        if let panel = panel {
            panel.parent?.removeChildWindow(panel)
            panel.orderOut(nil)
            self.panel = nil
        }
    }
}

#Preview {
    FontPickerGrid(
        onFontSelected: { _ in },
        onDismiss: {}
    )
    .padding()
    .background(Color.black.opacity(0.5))
}
