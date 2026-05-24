//
//  MarkdownExport.swift
//  tmp
//

import AppKit
import Foundation

enum MarkdownExport {
    static func markdown(from attributed: NSAttributedString) -> String {
        let string = attributed.string as NSString
        let length = string.length
        guard length > 0 else { return "" }

        var lines: [String] = []
        var codeBlockLines: [String] = []
        var index = 0

        func flushCodeBlock() {
            guard !codeBlockLines.isEmpty else { return }
            lines.append("```")
            lines.append(contentsOf: codeBlockLines)
            lines.append("```")
            codeBlockLines = []
        }

        while index < length {
            let paragraphRange = string.paragraphRange(for: NSRange(location: index, length: 0))
            let paragraphText = string.substring(with: paragraphRange)
            let content = paragraphText.hasSuffix("\n")
                ? String(paragraphText.dropLast())
                : paragraphText

            let attributes = attributed.attributes(at: paragraphRange.location, effectiveRange: nil)
            let blockStyle = attributes[.blockStyle] as? String

            let contentRange = NSRange(
                location: paragraphRange.location,
                length: (content as NSString).length
            )

            if blockStyle == BlockStyle.code.rawValue {
                codeBlockLines.append(inlineMarkdown(in: attributed, range: contentRange))
                index = NSMaxRange(paragraphRange)
                continue
            }

            flushCodeBlock()

            let prefix = headingPrefix(for: blockStyle)
            let inline = inlineMarkdown(in: attributed, range: contentRange)
            lines.append(prefix + inline)
            index = NSMaxRange(paragraphRange)
        }

        flushCodeBlock()
        return lines.joined(separator: "\n")
    }

    private static func headingPrefix(for blockStyle: String?) -> String {
        switch blockStyle {
        case BlockStyle.heading1.rawValue: return "# "
        case BlockStyle.heading2.rawValue: return "## "
        case BlockStyle.heading3.rawValue: return "### "
        default: return ""
        }
    }

    private static func inlineMarkdown(in attributed: NSAttributedString, range: NSRange) -> String {
        guard range.length > 0 else { return "" }

        let string = attributed.string as NSString
        var parts: [String] = []
        var index = range.location
        let end = NSMaxRange(range)

        while index < end {
            var runRange = NSRange(location: 0, length: 0)
            let attributes = attributed.attributes(at: index, effectiveRange: &runRange)
            runRange = NSIntersectionRange(runRange, range)
            guard runRange.length > 0 else { break }

            let text = string.substring(with: runRange)
            let font = attributes[.font] as? NSFont ?? Fonts.nsFont()
            let traits = Fonts.traits(for: font)

            let wrapped: String
            if traits.bold && traits.italic {
                wrapped = "***\(text)***"
            } else if traits.bold {
                wrapped = "**\(text)**"
            } else if traits.italic {
                wrapped = "*\(text)*"
            } else {
                wrapped = text
            }
            parts.append(wrapped)
            index = NSMaxRange(runRange)
        }

        return parts.joined()
    }
}
