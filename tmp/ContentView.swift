//
//  ContentView.swift
//  tmp
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var panelState: PanelState
    @EnvironmentObject private var panelController: FloatingPanelController

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
        .frame(width: PanelState.collapsedSize.width, height: PanelState.collapsedSize.height)
        .background(.ultraThinMaterial, in: Circle())
        .overlay {
            Circle()
                .strokeBorder(.white.opacity(0.25), lineWidth: 1)
        }
        .help("Open /tmp canvas")
    }

    private var expandedPanel: some View {
        VStack(spacing: 0) {
            HStack {
                Text("/tmp")
                    .font(.headline)

                Spacer()

                Button {
                    panelState.collapse()
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 18))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help("Minimize to bubble")
            }
            .padding(.horizontal, 14)
            .padding(.top, 12)
            .padding(.bottom, 8)

            Divider()

            TextEditor(text: $panelState.promptText)
                .font(.body)
                .scrollContentBackground(.hidden)
                .padding(10)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(width: PanelState.expandedSize.width, height: PanelState.expandedSize.height)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(.white.opacity(0.2), lineWidth: 1)
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(PanelState())
        .environmentObject(FloatingPanelController())
}
