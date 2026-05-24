//
//  tmpApp.swift
//  tmp
//

import SwiftUI

@main
struct tmpApp: App {
    @StateObject private var panelState = PanelState()
    @StateObject private var panelController = FloatingPanelController()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(panelState)
                .environmentObject(panelController)
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(
            width: PanelState.collapsedSize.width,
            height: PanelState.collapsedSize.height
        )
    }
}
