//
//  FloatingWindowAccessor.swift
//  tmp
//

import AppKit
import SwiftUI

/// Finds the host `NSWindow` and hands it to `FloatingPanelController` (no state mutations here).
struct FloatingWindowAccessor: NSViewRepresentable {
    @EnvironmentObject private var panelController: FloatingPanelController

    func makeNSView(context: Context) -> NSView {
        let view = NSView(frame: .zero)
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.clear.cgColor
        context.coordinator.bindWindow(from: view, panelController: panelController)
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        context.coordinator.bindWindow(from: nsView, panelController: panelController)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    final class Coordinator {
        func bindWindow(from view: NSView, panelController: FloatingPanelController) {
            DispatchQueue.main.async {
                guard let window = view.window else { return }
                panelController.attach(window: window)
                panelController.syncSpaceBehavior()
            }
        }
    }
}
