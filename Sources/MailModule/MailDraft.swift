import ArgumentParser
import AutoMacCore
import Foundation

/// mail draft 子命令 — 推送到 Mail.app 创建草稿
struct MailDraft: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "draft",
        abstract: "解析 Markdown 文件并在 Mail.app 中创建草稿",
        discussion: """
        FRONTMATTER 字段:
          to        收件人（必填）
          cc        抄送
          bcc       密送
          subject   主题（必填）
          account   发件账户（邮箱地址）

        地址格式:
          纯地址:     user@example.com
          带名称:     张三 <zhangsan@example.com>
          YAML 对象:  {name: 张三, email: zhangsan@example.com}

        示例:
          auto-mac mail draft meeting.md
          auto-mac mail draft report.md --account work@example.com
          auto-mac mail draft notice.md --dry-run --json
        """
    )

    @Argument(help: "Markdown 文件路径")
    var file: String

    @Option(name: .long, help: "覆盖 frontmatter 中的发件账户（邮箱地址）")
    var account: String?

    @Flag(name: .long, help: "只解析不创建草稿，输出解析结果")
    var dryRun: Bool = false

    @Flag(name: .long, help: "JSON 格式输出")
    var json: Bool = false

    func run() async throws {
        let content: String
        do {
            content = try String(contentsOfFile: file, encoding: .utf8)
        } catch {
            if json {
                print(OutputFormatter.jsonError(
                    command: "mail.draft",
                    error: .parse(.missingFrontmatter),
                    file: file
                ))
            } else {
                printError("无法读取文件: \(file)")
            }
            throw ExitCode.failure
        }

        let parser = FrontmatterParser()
        let result: FrontmatterParser.ParseResult
        do {
            result = try parser.parse(content)
        } catch let error as AutoMacError {
            if json {
                print(OutputFormatter.jsonError(command: "mail.draft", error: error, file: file))
            } else {
                printError(error.localizedDescription)
            }
            throw ExitCode.failure
        }

        let senderAccount = account ?? result.metadata.account

        if dryRun {
            if json {
                print(OutputFormatter.jsonSuccess(
                    command: "mail.draft",
                    file: file,
                    meta: formatMeta(result.metadata, sender: senderAccount)
                ))
            } else {
                printHumanReadable(result.metadata, sender: senderAccount)
            }
            return
        }

        // 渲染 HTML
        let renderer = HTMLRenderer()
        let htmlContent = renderer.renderEmail(result.metadata.subject, body: result.body)

        // 创建草稿
        let bridge = MailBridge()
        do {
            try bridge.createDraft(
                to: result.metadata.to,
                cc: result.metadata.cc,
                bcc: result.metadata.bcc,
                subject: result.metadata.subject,
                htmlContent: htmlContent,
                sender: senderAccount
            )
        } catch let error as AutoMacError {
            if json {
                print(OutputFormatter.jsonError(command: "mail.draft", error: error, file: file))
            } else {
                printError(error.localizedDescription)
            }
            throw ExitCode.failure
        }

        if json {
            print(OutputFormatter.jsonSuccess(
                command: "mail.draft",
                file: file,
                meta: formatMeta(result.metadata, sender: senderAccount)
            ))
        } else {
            printSuccess(result.metadata, sender: senderAccount)
        }
    }

    // MARK: - Output helpers

    private func formatMeta(_ meta: FrontmatterParser.EmailMetadata, sender: String?) -> [String: Any] {
        var dict: [String: Any] = [
            "to": meta.to.map { formatAddress($0) },
            "subject": meta.subject,
        ]
        if !meta.cc.isEmpty {
            dict["cc"] = meta.cc.map { formatAddress($0) }
        }
        if !meta.bcc.isEmpty {
            dict["bcc"] = meta.bcc.map { formatAddress($0) }
        }
        if let sender {
            dict["account"] = sender
        }
        return dict
    }

    private func formatAddress(_ addr: FrontmatterParser.Address) -> [String: String] {
        var dict: [String: String] = ["email": addr.email]
        if let name = addr.name { dict["name"] = name }
        return dict
    }

    private func formatAddressString(_ addr: FrontmatterParser.Address) -> String {
        if let name = addr.name { return "\(name) <\(addr.email)>" }
        return addr.email
    }

    private func printSuccess(_ meta: FrontmatterParser.EmailMetadata, sender: String?) {
        print("✓ Mail.app 草稿已创建")
        print("  主题: \(meta.subject)")
        print("  收件人: \(meta.to.map { formatAddressString($0) }.joined(separator: ", "))")
        if !meta.cc.isEmpty {
            print("  抄送: \(meta.cc.map { formatAddressString($0) }.joined(separator: ", "))")
        }
        if let sender { print("  发件账户: \(sender)") }
    }

    private func printHumanReadable(_ meta: FrontmatterParser.EmailMetadata, sender: String?) {
        print("📧 邮件解析结果（dry-run）")
        print("  主题: \(meta.subject)")
        print("  收件人: \(meta.to.map { formatAddressString($0) }.joined(separator: ", "))")
        if !meta.cc.isEmpty {
            print("  抄送: \(meta.cc.map { formatAddressString($0) }.joined(separator: ", "))")
        }
        if !meta.bcc.isEmpty {
            print("  密送: \(meta.bcc.map { formatAddressString($0) }.joined(separator: ", "))")
        }
        if let sender { print("  发件账户: \(sender)") }
    }

    private func printError(_ message: String) {
        FileHandle.standardError.write("✗ \(message)\n".data(using: .utf8)!)
    }
}
