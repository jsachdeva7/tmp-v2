//
//  FloatingPanelController.swift
//  tmp
//

import AppKit
import Combine
import QuartzCore
import SwiftUI

@MainActor
final class FloatingPanelController: ObservableObject {
    private weak var window: NSWindow?
    private var isAnimating = false
    private let animationDuration: TimeInterval = 0.22
    private let animationTiming = CAMediaTimingFunction(name: .easeInEaseOut)
    private let expandedCornerRadius: CGFloat = 16

    private var collapsedCornerRadius: CGFloat {
        min(PanelState.collapsedSize.width, PanelState.collapsedSize.height) / 2
    }

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
                to: Self.bottomRightAnchoredFrame(window: window, size: PanelState.expandedSize),
                cornerRadius: expandedCornerRadius
            ) { [weak self] in
                panelState.completeExpand()
                self?.syncSpaceBehavior()
            }
        case .collapse:
            animate(
                window: window,
                to: Self.bottomRightAnchoredFrame(window: window, size: PanelState.collapsedSize),
                cornerRadius: collapsedCornerRadius
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
        configureContentMask(for: window)
    }

    private func animate(
        window: NSWindow,
        to targetFrame: NSRect,
        cornerRadius: CGFloat,
        completion: @escaping () -> Void
    ) {
        isAnimating = true
        animateContentMask(for: window, to: cornerRadius)

        NSAnimationContext.runAnimationGroup({ context in
            context.duration = animationDuration
            context.timingFunction = animationTiming
            window.animator().setFrame(targetFrame, display: true)
        }, completionHandler: { [weak self] in
            self?.isAnimating = false
            completion()
        })
    }

    private func configureContentMask(for window: NSWindow) {
        window.contentView?.wantsLayer = true
        window.contentView?.layer?.masksToBounds = true
        window.contentView?.layer?.cornerCurve = .continuous
        window.contentView?.layer?.cornerRadius = collapsedCornerRadius
    }

    private func animateContentMask(for window: NSWindow, to cornerRadius: CGFloat) {
        guard let layer = window.contentView?.layer else { return }

        let animation = CABasicAnimation(keyPath: "cornerRadius")
        animation.fromValue = layer.presentation()?.cornerRadius ?? layer.cornerRadius
        animation.toValue = cornerRadius
        animation.duration = animationDuration
        animation.timingFunction = animationTiming

        CATransaction.begin()
        CATransaction.setDisableActions(true)
        layer.cornerRadius = cornerRadius
        CATransaction.commit()

        layer.add(animation, forKey: "cornerRadius")
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
