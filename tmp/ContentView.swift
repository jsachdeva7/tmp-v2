//
//  ContentView.swift
//  tmp
//

import AppKit
import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var panelState: PanelState
    @EnvironmentObject private var panelController: FloatingPanelController
    @State private var didCopy = false

    private var canCopy: Bool {
        !panelState.promptText.string.isEmpty
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            if panelState.usesExpandedLayout {
                expandedPanel
            } else {
                collapsedBubble
            }
        }
        .frame(width: panelState.layoutSize.width, height: panelState.layoutSize.height)
        .clipped()
        .background(FloatingWindowAccessor())
        .onChange(of: panelState.resizeIntent) { _, intent in
            guard intent != .none else { return }
            panelController.performResize(intent: intent, panelState: panelState)
        }
        .onChange(of: panelState.usesExpandedLayout) { _, isExpanded in
            guard isExpanded else { return }
            panelState.requestEditorFocus()
        }
    }

    private var collapsedBubble: some View {
        Button {
            panelState.expand()
        } label: {
            Image(systemName: "square.and.pencil")
                .font(.system(size: 22, weight: .medium))
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .buttonStyle(.plain)
        .pointerCursorOnHover()
        .frame(width: PanelState.collapsedSize.width, height: PanelState.collapsedSize.height)
        .background(.ultraThinMaterial, in: Circle())
        .overlay {
            Circle()
                .strokeBorder(.white.opacity(0.25), lineWidth: 1)
        }
        .help("Open Slate canvas")
    }

    private var expandedPanel: some View {
        VStack(spacing: 0) {
            HStack {
                Text("slate")
                    .font(.semiBoldItalic(13))

                Spacer()

                HStack(spacing: 10) {
                    Button {
                        panelState.clearPrompt()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .pointerCursorOnHover()
                    .help("Clear text")

                    Button {
                        panelState.collapse()
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .font(.system(size: 18))
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .pointerCursorOnHover()
                    .help("Minimize to bubble")
                }
            }
            .padding(.horizontal, 14)
            .padding(.top, 12)
            .padding(.bottom, 8)

            Divider()

            RichTextEditor(
                attributedText: $panelState.promptText,
                focusGeneration: panelState.editorFocusGeneration
            )
            .padding(10)
            .padding(.bottom, 44)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(width: PanelState.expandedSize.width, height: PanelState.expandedSize.height)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(.white.opacity(0.2), lineWidth: 1)
        }
        .overlay(alignment: .bottomTrailing) {
            copyPill
                .padding(14)
                .zIndex(10)
        }
    }

    private var copyPill: some View {
        Button {
            copyPromptToPasteboard()
        } label: {
            Image(systemName: didCopy ? "checkmark" : "doc.on.doc")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.primary)
                .frame(width: 16, height: 16)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay {
            Capsule()
                .strokeBorder(.white.opacity(0.2), lineWidth: 1)
        }
        .contentShape(Capsule())
        .pointerCursorOnHover()
        .help(didCopy ? "Copied" : "Copy as Markdown")
        .disabled(!canCopy)
        .opacity(canCopy ? 1 : 0.45)
        .allowsHitTesting(true)
    }

    private func copyPromptToPasteboard() {
        let markdown = MarkdownExport.markdown(from: panelState.promptText)
        guard !markdown.isEmpty else { return }

        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(markdown, forType: .string)

        didCopy = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            didCopy = false
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(PanelState())
        .environmentObject(FloatingPanelController())
}
