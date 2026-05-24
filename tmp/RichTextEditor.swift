//
//  RichTextEditor.swift
//  tmp
//

import AppKit
import SwiftUI

struct RichTextEditor: NSViewRepresentable {
    @Binding var attributedText: NSAttributedString

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeNSView(context: Context) -> NSScrollView {
        let textView = BeVietnamTextView()
        textView.isRichText = true
        textView.allowsUndo = true
        textView.isEditable = true
        textView.isSelectable = true
        textView.drawsBackground = false
        textView.textContainerInset = .zero
        textView.textContainer?.lineFragmentPadding = 0
        textView.typingAttributes = Fonts.defaultTextAttributes
        textView.delegate = context.coordinator
        textView.textStorage?.setAttributedString(attributedText)

        let scrollView = NSScrollView()
        scrollView.drawsBackground = false
        scrollView.borderType = .noBorder
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.documentView = textView

        context.coordinator.textView = textView
        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = context.coordinator.textView else { return }
        guard !textView.attributedString().isEqual(to: attributedText) else { return }

        let selection = textView.selectedRange()
        textView.textStorage?.setAttributedString(attributedText)
        let length = textView.string.utf16.count
        textView.setSelectedRange(
            NSRange(
                location: min(selection.location, length),
                length: min(selection.length, max(0, length - selection.location))
            )
        )
    }

    final class Coordinator: NSObject, NSTextViewDelegate {
        var parent: RichTextEditor
        weak var textView: BeVietnamTextView?

        init(parent: RichTextEditor) {
            self.parent = parent
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? BeVietnamTextView else { return }
            parent.attributedText = textView.attributedString()
        }
    }
}

// MARK: - NSTextView

final class BeVietnamTextView: NSTextView {
    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        guard event.modifierFlags.contains(.command) else {
            return super.performKeyEquivalent(with: event)
        }
        switch event.charactersIgnoringModifiers?.lowercased() {
        case "b":
            toggleBold()
            return true
        case "i":
            toggleItalicStyle()
            return true
        default:
            return super.performKeyEquivalent(with: event)
        }
    }

    private enum TextTrait {
        case bold
        case italic
    }

    private func toggleBold() {
        toggle(.bold)
    }

    private func toggleItalicStyle() {
        toggle(.italic)
    }

    private func toggle(_ trait: TextTrait) {
        let range = selectedRange()

        if range.length == 0 {
            let font = typingAttributes[.font] as? NSFont ?? Fonts.nsFont()
            var traits = Fonts.traits(for: font)
            switch trait {
            case .bold: traits.bold.toggle()
            case .italic: traits.italic.toggle()
            }
            typingAttributes[.font] = Fonts.nsFont(size: font.pointSize, isBold: traits.bold, isItalic: traits.italic)
            return
        }

        let applyTrait = shouldApplyTrait(trait, in: range)

        textStorage?.beginEditing()
        textStorage?.enumerateAttribute(.font, in: range) { value, subrange, _ in
            let font = (value as? NSFont) ?? Fonts.nsFont()
            var traits = Fonts.traits(for: font)
            switch trait {
            case .bold: traits.bold = applyTrait
            case .italic: traits.italic = applyTrait
            }
            textStorage?.addAttribute(
                .font,
                value: Fonts.nsFont(size: font.pointSize, isBold: traits.bold, isItalic: traits.italic),
                range: subrange
            )
        }
        textStorage?.endEditing()
        didChangeText()
    }

    private func shouldApplyTrait(_ trait: TextTrait, in range: NSRange) -> Bool {
        var needsTrait = false
        textStorage?.enumerateAttribute(.font, in: range) { value, _, stop in
            let traits = Fonts.traits(for: (value as? NSFont) ?? Fonts.nsFont())
            let isActive = trait == .bold ? traits.bold : traits.italic
            if !isActive {
                needsTrait = true
                stop.pointee = true
            }
        }
        return needsTrait
    }
}
