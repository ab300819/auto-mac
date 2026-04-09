import Testing
@testable import AutoMacCore

@Suite("FrontmatterParser Tests")
struct FrontmatterParserTests {
    let parser = FrontmatterParser()

    @Test("解析基本 frontmatter")
    func parseBasic() throws {
        let content = """
        ---
        to: user@example.com
        subject: 测试邮件
        ---

        这是正文。
        """
        let result = try parser.parse(content)
        #expect(result.metadata.subject == "测试邮件")
        #expect(result.metadata.to.count == 1)
        #expect(result.metadata.to[0].email == "user@example.com")
        #expect(result.body == "这是正文。")
    }

    @Test("解析 RFC 格式地址")
    func parseRFCAddress() throws {
        let content = """
        ---
        to: 张三 <zhangsan@example.com>
        subject: RFC 格式
        ---

        正文
        """
        let result = try parser.parse(content)
        #expect(result.metadata.to[0].name == "张三")
        #expect(result.metadata.to[0].email == "zhangsan@example.com")
    }

    @Test("解析多收件人混用格式")
    func parseMixedAddresses() throws {
        let content = """
        ---
        to:
          - 张三 <zhangsan@example.com>
          - lisi@example.com
        cc:
          - name: 王五
            email: wangwu@example.com
        bcc: secret@example.com
        subject: 混用格式
        account: work@example.com
        ---

        正文
        """
        let result = try parser.parse(content)
        #expect(result.metadata.to.count == 2)
        #expect(result.metadata.to[0].name == "张三")
        #expect(result.metadata.to[1].email == "lisi@example.com")
        #expect(result.metadata.cc.count == 1)
        #expect(result.metadata.cc[0].name == "王五")
        #expect(result.metadata.bcc.count == 1)
        #expect(result.metadata.account == "work@example.com")
    }

    @Test("缺少 subject 应报错")
    func missingSubject() {
        let content = """
        ---
        to: user@example.com
        ---

        正文
        """
        #expect(throws: AutoMacError.self) {
            try parser.parse(content)
        }
    }

    @Test("缺少 to 应报错")
    func missingTo() {
        let content = """
        ---
        subject: 无收件人
        ---

        正文
        """
        #expect(throws: AutoMacError.self) {
            try parser.parse(content)
        }
    }
}
