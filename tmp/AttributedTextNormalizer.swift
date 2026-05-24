//
//  AttributedTextNormalizer.swift
//  tmp
//

import AppKit

enum AttributedTextNormalizer {
    /// Re-styles pasted (or foreign) rich text to Slate fonts while keeping bold/italic intent.
    static func normalized(
        _ source: NSAttributedString,
        typingAttributes: [NSAttributedString.Key: Any]
    ) -> NSAttributedString {
        if Markdown.isCodeBlock(typingAttributes) {
            return NSAttributedString(string: source.string, attributes: Markdown.codeAttributes)
        }

        let contextBase = Markdown.typingAttributes(from: typingAttributes)
        let baseFont = (contextBase[.font] as? NSFont) ?? Fonts.nsFont()
        let size = baseFont.pointSize
        let isHeadingContext = isHeadingBlock(contextBase)

        let result = NSMutableAttributedString()
        let fullRange = NSRange(location: 0, length: source.length)
        guard fullRange.length > 0 else { return NSAttributedString() }

        source.enumerateAttributes(in: fullRange, options: []) { attributes, range, _ in
            let text = source.attributedSubstring(from: range).string
            guard !text.isEmpty else { return }

            var runAttributes = contextBase
            let traits = traitsFromSourceFont(attributes[.font] as? NSFont)

            if isHeadingContext {
                runAttributes[.font] = headingFont(size: size, italic: traits.italic)
            } else {
                runAttributes[.font] = Fonts.nsFont(size: size, isBold: traits.bold, isItalic: traits.italic)
            }

            runAttributes[.foregroundColor] = NSColor.labelColor
            runAttributes.removeValue(forKey: .backgroundColor)

            result.append(NSAttributedString(string: text, attributes: runAttributes))
        }

        return result
    }

    private static func isHeadingBlock(_ attributes: [NSAttributedString.Key: Any]) -> Bool {
        guard let raw = attributes[.blockStyle] as? String else { return false }
        return raw == BlockStyle.heading1.rawValue
            || raw == BlockStyle.heading2.rawValue
            || raw == BlockStyle.heading3.rawValue
    }

    private static func headingFont(size: CGFloat, italic: Bool) -> NSFont {
        if italic {
            return NSFont(name: Fonts.semiBoldItalic, size: size)
                ?? Fonts.nsFont(size: size, isBold: true, isItalic: true)
        }
        return Fonts.headingFont(size: size)
    }

    private static func traitsFromSourceFont(_ font: NSFont?) -> Fonts.Traits {
        guard let font else { return Fonts.Traits(bold: false, italic: false) }

        let manager = NSFontManager.shared
        var bold = manager.traits(of: font).contains(.boldFontMask)
        var italic = manager.traits(of: font).contains(.italicFontMask)

        let symbolic = font.fontDescriptor.symbolicTraits
        if !bold { bold = symbolic.contains(.bold) }
        if !italic { italic = symbolic.contains(.italic) }

        if !bold,
           let traits = font.fontDescriptor.object(forKey: .traits) as? [NSFontDescriptor.TraitKey: Any],
           let weight = traits[.weight] as? CGFloat {
            bold = weight >= 0.23
        }

        return Fonts.Traits(bold: bold, italic: italic)
    }
}
