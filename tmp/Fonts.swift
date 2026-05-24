//
//  Fonts.swift
//  tmp
//

import AppKit
import SwiftUI

/// Be Vietnam Pro PostScript names for `Font.custom` / `NSFont`.
enum Fonts {
    static let thin = "BeVietnamPro-Thin"
    static let thinItalic = "BeVietnamPro-ThinItalic"
    static let extraLight = "BeVietnamPro-ExtraLight"
    static let extraLightItalic = "BeVietnamPro-ExtraLightItalic"
    static let light = "BeVietnamPro-Light"
    static let lightItalic = "BeVietnamPro-LightItalic"
    static let regular = "BeVietnamPro-Regular"
    static let italic = "BeVietnamPro-Italic"
    static let medium = "BeVietnamPro-Medium"
    static let mediumItalic = "BeVietnamPro-MediumItalic"
    static let semiBold = "BeVietnamPro-SemiBold"
    static let semiBoldItalic = "BeVietnamPro-SemiBoldItalic"
    static let bold = "BeVietnamPro-Bold"
    static let boldItalic = "BeVietnamPro-BoldItalic"
    static let extraBold = "BeVietnamPro-ExtraBold"
    static let extraBoldItalic = "BeVietnamPro-ExtraBoldItalic"
    static let black = "BeVietnamPro-Black"
    static let blackItalic = "BeVietnamPro-BlackItalic"
    static let code = "SourceCodePro-ExtraLight"
}

extension Font {
    static func thin(_ size: CGFloat) -> Font { .custom(Fonts.thin, size: size) }
    static func thinItalic(_ size: CGFloat) -> Font { .custom(Fonts.thinItalic, size: size) }
    static func extraLight(_ size: CGFloat) -> Font { .custom(Fonts.extraLight, size: size) }
    static func extraLightItalic(_ size: CGFloat) -> Font { .custom(Fonts.extraLightItalic, size: size) }
    static func light(_ size: CGFloat) -> Font { .custom(Fonts.light, size: size) }
    static func lightItalic(_ size: CGFloat) -> Font { .custom(Fonts.lightItalic, size: size) }
    static func regular(_ size: CGFloat) -> Font { .custom(Fonts.regular, size: size) }
    static func italic(_ size: CGFloat) -> Font { .custom(Fonts.italic, size: size) }
    static func medium(_ size: CGFloat) -> Font { .custom(Fonts.medium, size: size) }
    static func mediumItalic(_ size: CGFloat) -> Font { .custom(Fonts.mediumItalic, size: size) }
    static func semiBold(_ size: CGFloat) -> Font { .custom(Fonts.semiBold, size: size) }
    static func semiBoldItalic(_ size: CGFloat) -> Font { .custom(Fonts.semiBoldItalic, size: size) }
    static func bold(_ size: CGFloat) -> Font { .custom(Fonts.bold, size: size) }
    static func boldItalic(_ size: CGFloat) -> Font { .custom(Fonts.boldItalic, size: size) }
    static func extraBold(_ size: CGFloat) -> Font { .custom(Fonts.extraBold, size: size) }
    static func extraBoldItalic(_ size: CGFloat) -> Font { .custom(Fonts.extraBoldItalic, size: size) }
    static func black(_ size: CGFloat) -> Font { .custom(Fonts.black, size: size) }
    static func blackItalic(_ size: CGFloat) -> Font { .custom(Fonts.blackItalic, size: size) }
    static func code(_ size: CGFloat) -> Font { .custom(Fonts.code, size: size) }
}

extension Fonts {
    static let defaultSize: CGFloat = 13

    static func nsFont(size: CGFloat = defaultSize, isBold: Bool = false, isItalic: Bool = false) -> NSFont {
        let name: String
        switch (isBold, isItalic) {
        case (false, false): name = regular
        case (true, false): name = bold
        case (false, true): name = italic
        case (true, true): name = boldItalic
        }
        return NSFont(name: name, size: size) ?? .systemFont(ofSize: size)
    }

    struct Traits: Equatable {
        var bold: Bool
        var italic: Bool
    }

    static func traits(for font: NSFont) -> Traits {
        switch font.fontName {
        case bold, boldItalic:
            return Traits(bold: true, italic: font.fontName == boldItalic)
        case italic:
            return Traits(bold: false, italic: true)
        default:
            return Traits(bold: false, italic: false)
        }
    }

    static var defaultTextAttributes: [NSAttributedString.Key: Any] {
        [
            .font: nsFont(),
            .foregroundColor: NSColor.labelColor,
        ]
    }

    static func codeFont(size: CGFloat = defaultSize) -> NSFont {
        NSFont(name: code, size: size) ?? .monospacedSystemFont(ofSize: size, weight: .regular)
    }

    static func headingFont(size: CGFloat) -> NSFont {
        NSFont(name: semiBold, size: size) ?? nsFont(size: size)
    }
}
