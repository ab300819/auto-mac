import Foundation

/// Apple Notes HTML → Markdown 转换器
/// 针对 Notes.app 的 HTML 结构定制，使用 XMLDocument 解析 DOM
public struct HTMLToMarkdown {
    public init() {}

    public func convert(_ html: String) -> String {
        // Pre-process: Apple Notes' AppleScript output uses unterminated entities
        // (e.g., &quot instead of &quot;), normalize them.
        let normalized = normalizeEntities(html)
        // Wrap in root element for valid XML parsing
        let wrapped = "<root>\(normalized)</root>"
        guard let doc = try? XMLDocument(xmlString: wrapped, options: [.documentTidyHTML]) else {
            // Fallback: strip tags
            return stripTags(html)
        }
        guard let root = doc.rootElement() else { return stripTags(html) }

        var output = ""
        walk(root, into: &output, listDepth: 0, ordered: false, itemIndex: 0)
        return cleanUp(output)
    }

    // MARK: - Tree walker

    private func walk(
        _ node: XMLNode,
        into output: inout String,
        listDepth: Int,
        ordered: Bool,
        itemIndex: Int
    ) {
        if let element = node as? XMLElement {
            walkElement(element, into: &output, listDepth: listDepth, ordered: ordered, itemIndex: itemIndex)
        } else if node.kind == .text {
            let text = node.stringValue ?? ""
            if !text.isEmpty {
                output += text
            }
        } else {
            walkChildren(of: node, into: &output, listDepth: listDepth, ordered: ordered)
        }
    }

    private func walkElement(
        _ el: XMLElement,
        into output: inout String,
        listDepth: Int,
        ordered: Bool,
        itemIndex: Int
    ) {
        let tag = el.name?.lowercased() ?? ""

        switch tag {
        case "h1":
            output += "# "
            walkChildren(of: el, into: &output, listDepth: listDepth, ordered: ordered)
            output += "\n\n"
        case "h2":
            output += "## "
            walkChildren(of: el, into: &output, listDepth: listDepth, ordered: ordered)
            output += "\n\n"
        case "h3":
            output += "### "
            walkChildren(of: el, into: &output, listDepth: listDepth, ordered: ordered)
            output += "\n\n"
        case "h4":
            output += "#### "
            walkChildren(of: el, into: &output, listDepth: listDepth, ordered: ordered)
            output += "\n\n"
        case "h5":
            output += "##### "
            walkChildren(of: el, into: &output, listDepth: listDepth, ordered: ordered)
            output += "\n\n"
        case "h6":
            output += "###### "
            walkChildren(of: el, into: &output, listDepth: listDepth, ordered: ordered)
            output += "\n\n"

        case "b", "strong":
            // Apple Notes wraps headings in <b><h1>...</h1></b>; skip the **
            if hasBlockChild(el) {
                walkChildren(of: el, into: &output, listDepth: listDepth, ordered: ordered)
            } else {
                let inner = childrenText(el, listDepth: listDepth, ordered: ordered)
                if !inner.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    output += "**\(inner)**"
                }
            }

        case "i", "em":
            if hasBlockChild(el) {
                walkChildren(of: el, into: &output, listDepth: listDepth, ordered: ordered)
            } else {
                let inner = childrenText(el, listDepth: listDepth, ordered: ordered)
                if !inner.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    output += "*\(inner)*"
                }
            }

        case "del", "s", "strike":
            let inner = childrenText(el, listDepth: listDepth, ordered: ordered)
            output += "~~\(inner)~~"

        case "tt", "code":
            let text = el.stringValue ?? ""
            if text.contains("\n") {
                output += "```\n\(text)\n```\n\n"
            } else {
                output += "`\(text)`"
            }

        case "pre":
            let text = el.stringValue ?? ""
            output += "```\n\(text)\n```\n\n"

        case "a":
            let href = el.attribute(forName: "href")?.stringValue ?? ""
            let text = el.stringValue ?? ""
            if href.isEmpty {
                output += text
            } else {
                output += "[\(text)](\(href))"
            }

        case "br":
            output += "\n"

        case "ul":
            walkList(el, into: &output, listDepth: listDepth, ordered: false)

        case "ol":
            walkList(el, into: &output, listDepth: listDepth, ordered: true)

        case "li":
            let indent = String(repeating: "  ", count: max(0, listDepth - 1))
            if ordered {
                output += "\(indent)\(itemIndex). "
            } else {
                output += "\(indent)- "
            }
            walkChildren(of: el, into: &output, listDepth: listDepth, ordered: ordered)
            output += "\n"

        case "blockquote":
            let inner = childrenText(el, listDepth: listDepth, ordered: ordered)
            let lines = inner.split(separator: "\n", omittingEmptySubsequences: false)
            for line in lines {
                output += "> \(line)\n"
            }
            output += "\n"

        case "img":
            let src = el.attribute(forName: "src")?.stringValue ?? ""
            let alt = el.attribute(forName: "alt")?.stringValue ?? ""
            output += "![\(alt)](\(src))"

        case "hr":
            output += "---\n\n"

        case "table":
            walkTable(el, into: &output)

        case "div", "p":
            // Apple Notes splits titles into consecutive <h1>2026</h1><h1>年</h1>...
            // If all children are headings of same level, merge them into one heading.
            if let mergedLevel = sameHeadingLevel(el) {
                var parts: [String] = []
                for child in el.children ?? [] {
                    if let childEl = child as? XMLElement,
                       childEl.name?.lowercased().hasPrefix("h") == true {
                        let s = (childEl.stringValue ?? "")
                            .trimmingCharacters(in: .whitespacesAndNewlines)
                        if !s.isEmpty { parts.append(s) }
                    }
                }
                let combined = parts.joined()
                if !combined.isEmpty {
                    output += String(repeating: "#", count: mergedLevel) + " \(combined)\n\n"
                }
            } else {
                let inner = childrenText(el, listDepth: listDepth, ordered: ordered)
                let trimmed = inner.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty {
                    output += trimmed + "\n\n"
                }
            }

        case "span", "font":
            // Pass through — just process children
            walkChildren(of: el, into: &output, listDepth: listDepth, ordered: ordered)

        default:
            // Unknown tags: process children
            walkChildren(of: el, into: &output, listDepth: listDepth, ordered: ordered)
        }
    }

    // MARK: - Lists

    private func walkList(_ el: XMLElement, into output: inout String, listDepth: Int, ordered: Bool) {
        let children = el.children ?? []
        var idx = 1
        for child in children {
            if let li = child as? XMLElement, li.name?.lowercased() == "li" {
                walkElement(li, into: &output, listDepth: listDepth + 1, ordered: ordered, itemIndex: idx)
                idx += 1
            }
        }
        output += "\n"
    }

    // MARK: - Tables

    private func walkTable(_ el: XMLElement, into output: inout String) {
        var rows: [[String]] = []
        for child in el.children ?? [] {
            guard let rowEl = child as? XMLElement else { continue }
            let tag = rowEl.name?.lowercased() ?? ""
            if tag == "tr" {
                rows.append(parseTableRow(rowEl))
            } else if tag == "thead" || tag == "tbody" {
                for subChild in rowEl.children ?? [] {
                    if let tr = subChild as? XMLElement, tr.name?.lowercased() == "tr" {
                        rows.append(parseTableRow(tr))
                    }
                }
            }
        }

        guard !rows.isEmpty else { return }

        // Header row
        output += "| \(rows[0].joined(separator: " | ")) |\n"
        output += "| \(rows[0].map { _ in "---" }.joined(separator: " | ")) |\n"

        // Data rows
        for row in rows.dropFirst() {
            output += "| \(row.joined(separator: " | ")) |\n"
        }
        output += "\n"
    }

    private func parseTableRow(_ tr: XMLElement) -> [String] {
        (tr.children ?? []).compactMap { child in
            guard let cell = child as? XMLElement else { return nil }
            let tag = cell.name?.lowercased() ?? ""
            if tag == "td" || tag == "th" {
                return cell.stringValue?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            }
            return nil
        }
    }

    // MARK: - Helpers

    private func walkChildren(
        of node: XMLNode,
        into output: inout String,
        listDepth: Int,
        ordered: Bool
    ) {
        for child in node.children ?? [] {
            walk(child, into: &output, listDepth: listDepth, ordered: ordered, itemIndex: 0)
        }
    }

    private func childrenText(_ el: XMLElement, listDepth: Int, ordered: Bool) -> String {
        var result = ""
        walkChildren(of: el, into: &result, listDepth: listDepth, ordered: ordered)
        return result
    }

    /// 如果所有非空白子节点都是相同级别的 heading（h1-h6），返回该级别；否则 nil
    private func sameHeadingLevel(_ el: XMLElement) -> Int? {
        var foundLevel: Int?
        for child in el.children ?? [] {
            if child.kind == .text,
               let s = child.stringValue,
               s.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                continue
            }
            guard let childEl = child as? XMLElement,
                  let name = childEl.name?.lowercased(),
                  name.count == 2, name.first == "h",
                  let level = Int(String(name.last!)),
                  (1...6).contains(level) else {
                return nil
            }
            // Skip empty heading (e.g., <h1><br></h1>)
            let content = childEl.stringValue?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if content.isEmpty { continue }

            if let existing = foundLevel {
                if existing != level { return nil }
            } else {
                foundLevel = level
            }
        }
        return foundLevel
    }

    private func hasBlockChild(_ el: XMLElement) -> Bool {
        let blockTags: Set<String> = [
            "h1", "h2", "h3", "h4", "h5", "h6",
            "div", "p", "ul", "ol", "li",
            "blockquote", "pre", "table", "hr",
        ]
        for child in el.children ?? [] {
            if let childEl = child as? XMLElement,
               let name = childEl.name?.lowercased(),
               blockTags.contains(name) {
                return true
            }
        }
        return false
    }

    /// 规范化 Apple Notes AppleScript 输出中的 &quot/&amp/&lt/&gt（缺少分号）
    /// AppleScript 用这些不带分号的 entity 表示对应字符
    private func normalizeEntities(_ html: String) -> String {
        var result = html
        // First fix the common case: missing-semicolon entities → with semicolon
        // Need to handle &amp first to avoid double-replacement
        let entities: [(String, String)] = [
            ("&amp;", "\u{0001}AMP\u{0001}"),  // protect already-correct &amp;
            ("&quot;", "\u{0001}QUOT\u{0001}"),
            ("&lt;", "\u{0001}LT\u{0001}"),
            ("&gt;", "\u{0001}GT\u{0001}"),
            ("&quot", "\""),
            ("&apos", "'"),
            ("&nbsp", " "),
            // &amp/&lt/&gt without semicolon are kept as-is to avoid breaking nested HTML
            ("\u{0001}AMP\u{0001}", "&amp;"),
            ("\u{0001}QUOT\u{0001}", "&quot;"),
            ("\u{0001}LT\u{0001}", "&lt;"),
            ("\u{0001}GT\u{0001}", "&gt;"),
        ]
        for (from, to) in entities {
            result = result.replacingOccurrences(of: from, with: to)
        }
        return result
    }

    private func stripTags(_ html: String) -> String {
        html.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
    }

    private func cleanUp(_ text: String) -> String {
        var result = text
        // Strip redundant emphasis inside headings (Apple Notes wraps headings in <b>)
        result = result.replacingOccurrences(
            of: #"^(#{1,6} )\*\*(.+?)\*\*(\s*)$"#,
            with: "$1$2$3",
            options: [.regularExpression, .anchored]
        )
        // Apply line-by-line for multi-line content
        let lines = result.components(separatedBy: "\n").map { line -> String in
            var l = line
            if let match = l.range(of: #"^(#{1,6} )\*\*(.+?)\*\*\s*$"#, options: .regularExpression) {
                let captured = l[match]
                l = captured.replacingOccurrences(of: "**", with: "")
            }
            if let match = l.range(of: #"^(#{1,6} )\*(.+?)\*\s*$"#, options: .regularExpression) {
                let captured = l[match]
                l = captured.replacingOccurrences(of: "*", with: "")
            }
            return l
        }
        result = lines.joined(separator: "\n")
        // Collapse 3+ newlines into 2
        while result.contains("\n\n\n") {
            result = result.replacingOccurrences(of: "\n\n\n", with: "\n\n")
        }
        return result.trimmingCharacters(in: .whitespacesAndNewlines) + "\n"
    }
}
