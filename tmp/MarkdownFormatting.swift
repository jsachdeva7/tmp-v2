//
//  MarkdownFormatting.swift
//  tmp
//

import AppKit

extension NSAttributedString.Key {
    static let blockStyle = NSAttributedString.Key("tmp.blockStyle")
}

enum BlockStyle: String {
    case heading1
    case heading2
    case heading3
    case code
}

enum Markdown {
    static let headingSizes: [Int: CGFloat] = [
        1: 22,
        2: 18,
        3: 16,
    ]

    static let codeBackgroundColor = NSColor.quaternaryLabelColor.withAlphaComponent(0.35)

    static func headingLevel(from prefix: String) -> Int? {
        switch prefix {
        case "#": return 1
        case "##": return 2
        case "###": return 3
        default: return nil
        }
    }

    static func blockStyle(forHeading level: Int) -> BlockStyle {
        switch level {
        case 1: return .heading1
        case 2: return .heading2
        default: return .heading3
        }
    }

    static func headingAttributes(level: Int) -> [NSAttributedString.Key: Any] {
        let size = headingSizes[level] ?? Fonts.defaultSize
        let style = NSMutableParagraphStyle()
        style.paragraphSpacingBefore = level == 1 ? 10 : 6
        style.paragraphSpacing = 4

        return [
            .font: Fonts.headingFont(size: size),
            .foregroundColor: NSColor.labelColor,
            .paragraphStyle: style,
            .blockStyle: blockStyle(forHeading: level).rawValue,
        ]
    }

    static var codeParagraphStyle: NSParagraphStyle {
        let style = NSMutableParagraphStyle()
        style.paragraphSpacing = 2
        style.lineSpacing = 2
        return style
    }

    static var codeAttributes: [NSAttributedString.Key: Any] {
        [
            .font: Fonts.codeFont(),
            .foregroundColor: NSColor.labelColor,
            .backgroundColor: codeBackgroundColor,
            .paragraphStyle: codeParagraphStyle,
            .blockStyle: BlockStyle.code.rawValue,
        ]
    }

    static func isCodeBlock(_ attributes: [NSAttributedString.Key: Any]) -> Bool {
        (attributes[.blockStyle] as? String) == BlockStyle.code.rawValue
    }

    static func typingAttributes(from attributes: [NSAttributedString.Key: Any]) -> [NSAttributedString.Key: Any] {
        var merged = Fonts.defaultTextAttributes
        if let font = attributes[.font] { merged[.font] = font }
        if let color = attributes[.foregroundColor] { merged[.foregroundColor] = color }
        if let background = attributes[.backgroundColor] { merged[.backgroundColor] = background }
        if let style = attributes[.paragraphStyle] { merged[.paragraphStyle] = style }
        if let block = attributes[.blockStyle] { merged[.blockStyle] = block }
        return merged
    }
}
