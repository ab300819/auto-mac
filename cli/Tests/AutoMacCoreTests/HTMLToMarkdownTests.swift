import Testing
@testable import AutoMacCore

@Suite("HTMLToMarkdown Tests")
struct HTMLToMarkdownTests {
    let conv = HTMLToMarkdown()

    @Test("简单段落")
    func paragraph() {
        let html = "<div>Hello world</div>"
        let md = conv.convert(html)
        #expect(md.contains("Hello world"))
    }

    @Test("标题层级")
    func headings() {
        let html = "<h1>One</h1><h2>Two</h2><h3>Three</h3>"
        let md = conv.convert(html)
        #expect(md.contains("# One"))
        #expect(md.contains("## Two"))
        #expect(md.contains("### Three"))
    }

    @Test("加粗与斜体")
    func boldItalic() {
        let html = "<div>这是<b>加粗</b>和<i>斜体</i></div>"
        let md = conv.convert(html)
        #expect(md.contains("**加粗**"))
        #expect(md.contains("*斜体*"))
    }

    @Test("无序列表")
    func unorderedList() {
        let html = "<ul><li>列表1</li><li>列表2</li></ul>"
        let md = conv.convert(html)
        #expect(md.contains("- 列表1"))
        #expect(md.contains("- 列表2"))
    }

    @Test("Apple Notes 破折号列表")
    func appleDashList() {
        let html = """
        <ul class="Apple-dash-list">
        <li>第一项</li>
        <li>第二项</li>
        </ul>
        """
        let md = conv.convert(html)
        #expect(md.contains("- 第一项"))
        #expect(md.contains("- 第二项"))
    }

    @Test("有序列表")
    func orderedList() {
        let html = "<ol><li>A</li><li>B</li><li>C</li></ol>"
        let md = conv.convert(html)
        #expect(md.contains("1. A"))
        #expect(md.contains("2. B"))
        #expect(md.contains("3. C"))
    }

    @Test("链接")
    func link() {
        let html = "<a href=\"https://example.com\">Example</a>"
        let md = conv.convert(html)
        #expect(md.contains("[Example](https://example.com)"))
    }

    @Test("行内代码 tt 标签")
    func inlineCodeTT() {
        let html = "<div><tt>winetricks corefonts</tt></div>"
        let md = conv.convert(html)
        #expect(md.contains("`winetricks corefonts`"))
    }

    @Test("Apple Notes 完整笔记样本")
    func realAppleNotesSample() {
        let html = """
        <div><b><h1>文件夹测试</h1></b></div>
        <div><br></div>
        <div>这是<b>加粗</b>和<i>斜体</i><br></div>
        <div><br></div>
        <ul class="Apple-dash-list">
        <li>列表1</li>
        <li>列表2</li>
        </ul>
        """
        let md = conv.convert(html)
        #expect(md.contains("# 文件夹测试"))
        #expect(md.contains("**加粗**"))
        #expect(md.contains("*斜体*"))
        #expect(md.contains("- 列表1"))
        #expect(md.contains("- 列表2"))
    }

    @Test("Wine 配置样本")
    func wineConfigSample() {
        let html = """
        <div><h1>Wine 配置</h1></div>
        <div><h2>winetricks 配置</h2></div>
        <div><tt>export WINEDEBUG=-all</tt></div>
        <div><tt>winetricks corefonts</tt></div>
        """
        let md = conv.convert(html)
        #expect(md.contains("# Wine 配置"))
        #expect(md.contains("## winetricks 配置"))
        #expect(md.contains("`export WINEDEBUG=-all`"))
        #expect(md.contains("`winetricks corefonts`"))
    }

    @Test("删除线")
    func strikethrough() {
        let html = "<del>deleted</del>"
        let md = conv.convert(html)
        #expect(md.contains("~~deleted~~"))
    }

    @Test("br 换行")
    func lineBreak() {
        let html = "<div>line1<br>line2</div>"
        let md = conv.convert(html)
        #expect(md.contains("line1"))
        #expect(md.contains("line2"))
    }
}
