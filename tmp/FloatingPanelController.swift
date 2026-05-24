//
//  FloatingPanelController.swift
//  tmp
//

import AppKit
import Combine
import SwiftUI

@MainActor
final class FloatingPanelController: ObservableObject {
    private weak var window: NSWindow?
    private var isAnimating = false

    func attach(window: NSWindow) {
        guard self.window !== window else { return }
        self.window = window
        configure(window)
        window.setFrame(
            Self.screenAnchoredFrame(for: window, size: PanelState.collapsedSize),
            display: true
        )
        syncSpaceBehavior()
    }

    /// Re-applies Space behavior; SwiftUI may reset `collectionBehavior` after layout updates.
    func syncSpaceBehavior() {
        guard let window else { return }
        window.hasShadow = false
        Self.applySpaceBehavior(to: window)
    }

    func performResize(intent: PanelResizeIntent, panelState: PanelState) {
        guard intent != .none, let window, !isAnimating else { return }
        guard panelState.resizeIntent == intent else { return }
        panelState.resizeIntent = .none

        switch intent {
        case .none:
            break
        case .expand:
            animate(
                window: window,
                to: Self.bottomRightAnchoredFrame(window: window, size: PanelState.expandedSize)
            ) { [weak self] in
                panelState.completeExpand()
                self?.syncSpaceBehavior()
            }
        case .collapse:
            animate(
                window: window,
                to: Self.bottomRightAnchoredFrame(window: window, size: PanelState.collapsedSize)
            ) { [weak self] in
                panelState.completeCollapse()
                self?.syncSpaceBehavior()
            }
        }
    }

    private func configure(_ window: NSWindow) {
        window.styleMask = [.borderless, .fullSizeContentView]
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.isOpaque = false
        window.backgroundColor = .clear
        window.level = .floating
        window.hasShadow = false
        window.isMovableByWindowBackground = true
        window.standardWindowButton(.closeButton)?.isHidden = true
        window.standardWindowButton(.miniaturizeButton)?.isHidden = true
        window.standardWindowButton(.zoomButton)?.isHidden = true
    }

    private func animate(window: NSWindow, to targetFrame: NSRect, completion: @escaping () -> Void) {
        isAnimating = true
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.22
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            window.animator().setFrame(targetFrame, display: true)
        }, completionHandler: { [weak self] in
            self?.isAnimating = false
            completion()
        })
    }

    private static func bottomRightAnchoredFrame(window: NSWindow, size: CGSize) -> NSRect {
        let current = window.frame
        return NSRect(
            x: current.maxX - size.width,
            y: current.minY,
            width: size.width,
            height: size.height
        )
    }

    private static func applySpaceBehavior(to window: NSWindow) {
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
    }

    private static func screenAnchoredFrame(for window: NSWindow, size: CGSize) -> NSRect {
        let visible = (window.screen ?? NSScreen.main)?.visibleFrame
            ?? NSScreen.main?.visibleFrame
            ?? .zero
        return NSRect(
            x: visible.maxX - size.width - PanelState.screenMargin,
            y: visible.minY + PanelState.screenMargin,
            width: size.width,
            height: size.height
        )
    }
}
