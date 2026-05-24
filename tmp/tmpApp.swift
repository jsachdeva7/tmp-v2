//
//  tmpApp.swift
//  tmp
//

import Sparkle
import SwiftUI

@main
struct tmpApp: App {
    @StateObject private var panelState = PanelState()
    @StateObject private var panelController = FloatingPanelController()
    
    private let updaterController: SPUStandardUpdaterController

    init() {
        updaterController = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(panelState)
                .environmentObject(panelController)
                .font(.regular(13))
        }
        .commands {
            CommandGroup(after: .appInfo) {
                CheckForUpdatesView(updater: updaterController.updater)
            }
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize( 
            width: PanelState.collapsedSize.width,
            height: PanelState.collapsedSize.height
        )
    }
}
