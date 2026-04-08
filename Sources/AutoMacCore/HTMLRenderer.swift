import Foundation
import Markdown

/// Markdown → Mail.app 风格 HTML 渲染器
/// 使用 swift-markdown AST + 自定义 MarkupWalker 生成内联样式 HTML
public struct HTMLRenderer {
    public init() {}

    /// 渲染 Markdown 正文为 Mail.app 风格 HTML
    public func render(_ markdown: String) -> String {
        let document = Document(parsing: markdown)
        var walker = MailHTMLWalker()
        walker.visit(document)
        return walker.html
    }

    /// 渲染完整邮件 HTML（含外层包装，无 subject 标题）
    public func renderEmail(_ markdown: String) -> String {
        let body = render(markdown)
        return "<div style=\"\(Style.body)\">\(body)</div>"
    }

    /// 渲染完整邮件 HTML（重载：subject 仅用于未来扩展，当前不在正文中显示 subject）
    public func renderEmail(_ subject: String, body markdown: String) -> String {
        renderEmail(markdown)
    }
}

// MARK: - Styles

private enum Style {
    static let body = """
        font-family: -apple-system, 'Helvetica Neue', Helvetica, sans-serif; \
        font-size: 14px; \
        line-height: 1.5; \
        color: #1d1d1f;
        """

    static let heading2 = "font-size: 17px; font-weight: 600; margin: 16px 0 8px 0;"
    static let heading3 = "font-size: 15px; font-weight: 600; margin: 12px 0 6px 0;"

    static let paragraph = "margin: 0 0 8px 0;"

    static let list = "margin: 0 0 8px 0; padding-left: 24px;"

    static let link = "color: #0066cc; text-decoration: underline;"

    static let codeInline = """
        font-family: Menlo, Monaco, 'Courier New', monospace; \
        font-size: 13px; \
        background: #f5f5f7; \
        padding: 1px 5px; \
        border-radius: 3px;
        """

    static let codeBlock = """
        font-family: Menlo, Monaco, 'Courier New', monospace; \
        font-size: 13px; \
        background: #f5f5f7; \
        padding: 12px 16px; \
        border-radius: 6px; \
        overflow-x: auto; \
        margin: 0 0 8px 0; \
        white-space: pre-wrap;
        """

    static let blockquote = """
        margin: 0 0 8px 0; \
        padding-left: 12px; \
        border-left: 3px solid #d2d2d7; \
        color: #6e6e73;
        """

    static let hr = "border: none; border-top: 1px solid #d2d2d7; margin: 16px 0;"

    static let table = "border-collapse: collapse; margin: 8px 0; font-size: 14px;"
    static let th = "border: 1px solid #d2d2d7; padding: 6px 12px; background: #f5f5f7; text-align: left; font-weight: 600;"
    static let td = "border: 1px solid #d2d2d7; padding: 6px 12px;"
}

// MARK: - MarkupWalker

private struct MailHTMLWalker: MarkupWalker {
    var html = ""

    // State tracking
    private var isInListItem = false
    private var listItemPrefix = ""

    // MARK: - Block elements

    mutating func visitDocument(_ document: Document) -> () {
        for child in document.children {
            visit(child)
        }
    }

    mutating func visitParagraph(_ paragraph: Paragraph) -> () {
        html += "<p style=\"\(Style.paragraph)\">"
        for child in paragraph.children {
            visit(child)
        }
        html += "</p>\n"
    }

    mutating func visitHeading(_ heading: Heading) -> () {
        let style = heading.level <= 2 ? Style.heading2 : Style.heading3
        let tag = "h\(min(heading.level, 6))"
        html += "<\(tag) style=\"\(style)\">"
        for child in heading.children {
            visit(child)
        }
        html += "</\(tag)>\n"
    }

    mutating func visitBlockQuote(_ blockQuote: BlockQuote) -> () {
        html += "<blockquote style=\"\(Style.blockquote)\">"
        for child in blockQuote.children {
            visit(child)
        }
        html += "</blockquote>\n"
    }

    mutating func visitCodeBlock(_ codeBlock: CodeBlock) -> () {
        let escaped = escapeHTML(codeBlock.code.trimmingCharacters(in: .whitespacesAndNewlines))
        html += "<pre style=\"\(Style.codeBlock)\"><code>\(escaped)</code></pre>\n"
    }

    mutating func visitOrderedList(_ orderedList: OrderedList) -> () {
        html += "<ol style=\"\(Style.list)\">\n"
        for child in orderedList.children {
            visit(child)
        }
        html += "</ol>\n"
    }

    mutating func visitUnorderedList(_ unorderedList: UnorderedList) -> () {
        html += "<ul style=\"\(Style.list)\">\n"
        for child in unorderedList.children {
            visit(child)
        }
        html += "</ul>\n"
    }

    mutating func visitListItem(_ listItem: ListItem) -> () {
        html += "<li>"
        for child in listItem.children {
            // List items contain paragraphs, render inline without <p> wrapper
            if let para = child as? Paragraph {
                for inlineChild in para.children {
                    visit(inlineChild)
                }
            } else {
                visit(child)
            }
        }
        html += "</li>\n"
    }

    mutating func visitThematicBreak(_ thematicBreak: ThematicBreak) -> () {
        html += "<hr style=\"\(Style.hr)\">\n"
    }

    mutating func visitHTMLBlock(_ htmlBlock: HTMLBlock) -> () {
        html += htmlBlock.rawHTML
    }

    mutating func visitTable(_ table: Table) -> () {
        html += "<table style=\"\(Style.table)\">\n"
        // Head
        if let head = table.head as? Table.Head {
            html += "<thead><tr>\n"
            for cell in head.children {
                html += "<th style=\"\(Style.th)\">"
                if let tableCell = cell as? Table.Cell {
                    for child in tableCell.children {
                        visit(child)
                    }
                }
                html += "</th>\n"
            }
            html += "</tr></thead>\n"
        }
        // Body
        html += "<tbody>\n"
        if let body = table.body as? Table.Body {
            for row in body.children {
                html += "<tr>\n"
                if let tableRow = row as? Table.Row {
                    for cell in tableRow.children {
                        html += "<td style=\"\(Style.td)\">"
                        if let tableCell = cell as? Table.Cell {
                            for child in tableCell.children {
                                visit(child)
                            }
                        }
                        html += "</td>\n"
                    }
                }
                html += "</tr>\n"
            }
        }
        html += "</tbody></table>\n"
    }

    // MARK: - Inline elements

    mutating func visitText(_ text: Text) -> () {
        html += escapeHTML(text.string)
    }

    mutating func visitStrong(_ strong: Strong) -> () {
        html += "<strong>"
        for child in strong.children {
            visit(child)
        }
        html += "</strong>"
    }

    mutating func visitEmphasis(_ emphasis: Emphasis) -> () {
        html += "<em>"
        for child in emphasis.children {
            visit(child)
        }
        html += "</em>"
    }

    mutating func visitInlineCode(_ inlineCode: InlineCode) -> () {
        html += "<code style=\"\(Style.codeInline)\">\(escapeHTML(inlineCode.code))</code>"
    }

    mutating func visitLink(_ link: Markdown.Link) -> () {
        let dest = link.destination ?? ""
        html += "<a href=\"\(escapeHTML(dest))\" style=\"\(Style.link)\">"
        for child in link.children {
            visit(child)
        }
        html += "</a>"
    }

    mutating func visitImage(_ image: Markdown.Image) -> () {
        // Images not supported in current version
        html += "[图片: \(image.title ?? image.source ?? "")]"
    }

    mutating func visitLineBreak(_ lineBreak: LineBreak) -> () {
        html += "<br>"
    }

    mutating func visitSoftBreak(_ softBreak: SoftBreak) -> () {
        html += "\n"
    }

    mutating func visitStrikethrough(_ strikethrough: Strikethrough) -> () {
        html += "<del>"
        for child in strikethrough.children {
            visit(child)
        }
        html += "</del>"
    }

    mutating func visitInlineHTML(_ inlineHTML: InlineHTML) -> () {
        html += inlineHTML.rawHTML
    }

    // MARK: - Helpers

    private func escapeHTML(_ string: String) -> String {
        string
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
    }
}
