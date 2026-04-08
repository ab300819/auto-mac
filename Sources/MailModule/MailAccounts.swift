import ArgumentParser
import AutoMacCore
import Foundation

/// mail accounts 子命令 — 列出 Mail.app 可用发件账户
struct MailAccounts: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "accounts",
        abstract: "列出 Mail.app 可用发件账户",
        discussion: """
        示例:
          auto-mac mail accounts
          auto-mac mail accounts --json
        """
    )

    @Flag(name: .long, help: "JSON 格式输出")
    var json: Bool = false

    func run() async throws {
        let bridge = MailBridge()
        let accounts: [(name: String, email: String)]
        do {
            accounts = try bridge.listAccounts()
        } catch let error as AutoMacError {
            if json {
                print(OutputFormatter.jsonError(command: "mail.accounts", error: error, file: ""))
            } else {
                FileHandle.standardError.write("✗ \(error.localizedDescription)\n".data(using: .utf8)!)
            }
            throw ExitCode.failure
        }

        if json {
            let accountDicts = accounts.map { ["name": $0.name, "email": $0.email] }
            let result: [String: Any] = [
                "status": "ok",
                "command": "mail.accounts",
                "accounts": accountDicts,
            ]
            let options: JSONSerialization.WritingOptions = [.prettyPrinted, .sortedKeys]
            if let data = try? JSONSerialization.data(withJSONObject: result, options: options),
               let str = String(data: data, encoding: .utf8) {
                print(str)
            }
        } else {
            if accounts.isEmpty {
                print("Mail.app 中没有配置账户")
            } else {
                print("Mail.app 发件账户：")
                for acct in accounts {
                    print("  \(acct.name): \(acct.email)")
                }
            }
        }
    }
}
