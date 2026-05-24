//
//  PanelState.swift
//  tmp
//

import AppKit
import Combine
import SwiftUI

enum PanelResizeIntent: Equatable {
    case none
    case expand
    case collapse
}

@MainActor
final class PanelState: ObservableObject {
    @Published var isExpanded = false
    /// Drives SwiftUI chrome; stays expanded until the collapse window animation finishes.
    @Published private(set) var usesExpandedLayout = false
    @Published var promptText = NSAttributedString(string: "", attributes: Fonts.defaultTextAttributes)
    @Published var resizeIntent: PanelResizeIntent = .none

    static let collapsedSize = CGSize(width: 56, height: 56)
    static let expandedSize = CGSize(width: 400, height: 480)
    static let screenMargin: CGFloat = 24

    var layoutSize: CGSize {
        usesExpandedLayout ? Self.expandedSize : Self.collapsedSize
    }

    func expand() {
        usesExpandedLayout = true
        isExpanded = true
        resizeIntent = .expand
    }

    func collapse() {
        guard isExpanded else { return }
        resizeIntent = .collapse
    }

    func completeExpand() {
        resizeIntent = .none
    }

    func completeCollapse() {
        isExpanded = false
        usesExpandedLayout = false
        resizeIntent = .none
    }
}
