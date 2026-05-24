//
//  View+PointerCursor.swift
//  tmp
//

import AppKit
import SwiftUI

extension View {
    func pointerCursorOnHover() -> some View {
        onHover { isHovering in
            if isHovering {
                NSCursor.pointingHand.push()
            } else {
                NSCursor.pop()
            }
        }
    }
}
