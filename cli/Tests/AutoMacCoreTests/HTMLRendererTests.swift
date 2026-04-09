import Testing
@testable import AutoMacCore

@Suite("HTMLRenderer Tests")
struct HTMLRendererTests {
    let renderer = HTMLRenderer()

    @Test("渲染加粗和斜体")
    func renderBoldItalic() {
        let html = renderer.render("**加粗** 和 *斜体*")
        #expect(html.contains("<strong>加粗</strong>"))
        #expect(html.contains("<em>斜体</em>"))
    }

    @Test("渲染标题")
    func renderHeadings() {
        let html = renderer.render("## 二级标题\n\n### 三级标题")
        #expect(html.contains("<h2"))
        #expect(html.contains("二级标题"))
        #expect(html.contains("<h3"))
        #expect(html.contains("三级标题"))
    }

    @Test("渲染有序列表")
    func renderOrderedList() {
        let html = renderer.render("1. 第一项\n2. 第二项\n3. 第三项")
        #expect(html.contains("<ol"))
        #expect(html.contains("<li>第一项</li>"))
        #expect(html.contains("<li>第三项</li>"))
    }

    @Test("渲染无序列表")
    func renderUnorderedList() {
        let html = renderer.render("- 项目 A\n- 项目 B")
        #expect(html.contains("<ul"))
        #expect(html.contains("<li>项目 A</li>"))
    }

    @Test("渲染链接")
    func renderLink() {
        let html = renderer.render("[示例](https://example.com)")
        #expect(html.contains("<a href=\"https://example.com\""))
        #expect(html.contains("示例</a>"))
    }

    @Test("渲染行内代码")
    func renderInlineCode() {
        let html = renderer.render("使用 `let x = 42` 声明")
        #expect(html.contains("<code"))
        #expect(html.contains("let x = 42"))
        #expect(html.contains("Menlo"))
    }

    @Test("渲染代码块")
    func renderCodeBlock() {
        let md = "```\nfunc hello() {\n    print(\"hi\")\n}\n```"
        let html = renderer.render(md)
        #expect(html.contains("<pre"))
        #expect(html.contains("<code>"))
        #expect(html.contains("func hello()"))
    }

    @Test("渲染表格")
    func renderTable() {
        let md = "| 时间 | 内容 |\n|------|------|\n| 2:00 | 开场 |\n| 2:30 | 讨论 |"
        let html = renderer.render(md)
        #expect(html.contains("<table"))
        #expect(html.contains("<th"))
        #expect(html.contains("时间"))
        #expect(html.contains("<td"))
        #expect(html.contains("2:00"))
    }

    @Test("HTML 转义")
    func escapeHTML() {
        let html = renderer.render("a < b && c > d")
        #expect(html.contains("&lt;"))
        #expect(html.contains("&amp;&amp;"))
        #expect(html.contains("&gt;"))
    }

    @Test("renderEmail 包含外层样式")
    func renderEmailWrapper() {
        let html = renderer.renderEmail("hello")
        #expect(html.contains("font-family: -apple-system"))
        #expect(html.contains("font-size: 14px"))
    }

    @Test("渲染删除线")
    func renderStrikethrough() {
        let html = renderer.render("~~已删除~~")
        #expect(html.contains("<del>已删除</del>"))
    }
}
