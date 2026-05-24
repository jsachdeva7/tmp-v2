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

        func textView(_ textView: NSTextView, shouldChangeTextIn affectedCharRange: NSRange, replacementString: String?) -> Bool {
            guard let textView = textView as? BeVietnamTextView else { return true }
            return textView.handleMarkdownReplacement(in: affectedCharRange, replacement: replacementString ?? "")
        }

        func textViewDidChangeSelection(_ notification: Notification) {
            guard let textView = notification.object as? BeVietnamTextView else { return }
            textView.syncTypingAttributesToSelection()
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

    /// Returns `true` to allow the edit, `false` to reject it (NSTextView delegate convention).
    func handleMarkdownReplacement(in range: NSRange, replacement: String) -> Bool {
        if replacement == " " {
            if tryApplyHeading(at: range) { return false }
            return true
        }
        if replacement == "`" {
            if tryToggleCodeFence(at: range) { return false }
            return true
        }
        if replacement == "\n", isHeadingTypingAttributes {
            typingAttributes = Fonts.defaultTextAttributes
        }
        return true
    }

    private var isHeadingTypingAttributes: Bool {
        guard let raw = typingAttributes[.blockStyle] as? String else { return false }
        return raw == BlockStyle.heading1.rawValue
            || raw == BlockStyle.heading2.rawValue
            || raw == BlockStyle.heading3.rawValue
    }

    func syncTypingAttributesToSelection() {
        guard selectedRange().length == 0 else { return }
        guard let storage = textStorage, storage.length > 0 else { return }

        let location = selectedRange().location
        // Don't inherit the previous line's body style when starting a fresh line
        // (e.g. right after `#` + space applies heading typing attributes).
        if isCurrentLineEmpty(at: location) {
            return
        }

        let attributeIndex = location == storage.length ? max(0, storage.length - 1) : location
        let attributes = storage.attributes(at: attributeIndex, effectiveRange: nil)
        typingAttributes = Markdown.typingAttributes(from: attributes)
    }

    private func isCurrentLineEmpty(at location: Int) -> Bool {
        let nsString = string as NSString
        let lineRange = nsString.lineRange(for: NSRange(location: location, length: 0))
        let line = nsString.substring(with: lineRange)
        return line.trimmingCharacters(in: .newlines).isEmpty
    }

    /// Returns `true` if the markdown shortcut was applied (caller should reject the default insert).
    private func tryApplyHeading(at range: NSRange) -> Bool {
        let nsString = string as NSString
        let lineRange = nsString.lineRange(for: range)
        let prefixLength = range.location - lineRange.location
        guard prefixLength > 0 else { return false }

        let prefix = nsString.substring(with: NSRange(location: lineRange.location, length: prefixLength))
        guard let level = Markdown.headingLevel(from: prefix) else { return false }

        let headingAttributes = Markdown.headingAttributes(level: level)

        textStorage?.beginEditing()
        textStorage?.deleteCharacters(in: NSRange(location: lineRange.location, length: prefixLength))
        let styledLineRange = NSRange(location: lineRange.location, length: lineRange.length - prefixLength)
        if styledLineRange.length > 0 {
            textStorage?.setAttributes(headingAttributes, range: styledLineRange)
        }
        textStorage?.endEditing()

        typingAttributes = headingAttributes
        setSelectedRange(NSRange(location: lineRange.location, length: 0))
        didChangeText()
        return true
    }

    /// Returns `true` if the code fence was toggled (caller should reject the default insert).
    private func tryToggleCodeFence(at range: NSRange) -> Bool {
        let nsString = string as NSString
        let lineRange = nsString.lineRange(for: range)
        let prefixLength = range.location - lineRange.location
        guard prefixLength == 2 else { return false }

        let prefix = nsString.substring(with: NSRange(location: lineRange.location, length: prefixLength))
        guard prefix == "``" else { return false }

        let closing = isInCodeBlock(at: range.location)

        textStorage?.beginEditing()
        textStorage?.deleteCharacters(in: NSRange(location: lineRange.location, length: prefixLength))
        textStorage?.endEditing()

        typingAttributes = closing ? Fonts.defaultTextAttributes : Markdown.codeAttributes
        setSelectedRange(NSRange(location: lineRange.location, length: 0))
        didChangeText()
        return true
    }

    private func isInCodeBlock(at location: Int) -> Bool {
        if Markdown.isCodeBlock(typingAttributes) {
            return true
        }
        guard let storage = textStorage, storage.length > 0 else { return false }

        let index = min(max(0, location - (location == storage.length ? 1 : 0)), storage.length - 1)
        let attributes = storage.attributes(at: index, effectiveRange: nil)
        return Markdown.isCodeBlock(attributes)
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
