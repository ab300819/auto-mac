import Foundation
import AutoMacCore

/// Mail.app AppleScript 交互封装
/// 使用 osascript 子进程执行，避免 NSAppleScript 在 async 上下文中的 RunLoop 问题
public struct MailBridge {
    public init() {}

    /// 创建 Mail.app 草稿
    public func createDraft(
        to: [FrontmatterParser.Address],
        cc: [FrontmatterParser.Address],
        bcc: [FrontmatterParser.Address],
        subject: String,
        htmlContent: String,
        sender: String? = nil
    ) throws {
        let script = buildCreateDraftScript(
            to: to, cc: cc, bcc: bcc,
            subject: subject,
            htmlContent: htmlContent,
            sender: sender
        )
        try runOsascript(script)
    }

    /// 列出 Mail.app 所有账户
    public func listAccounts() throws -> [(name: String, email: String)] {
        let script = """
        tell application "Mail"
            set output to ""
            repeat with acct in accounts
                set acctName to name of acct
                set addrs to email addresses of acct
                repeat with addr in addrs
                    set output to output & acctName & "|||" & addr & linefeed
                end repeat
            end repeat
            return output
        end tell
        """

        let result = try runOsascript(script)
        return result
            .components(separatedBy: "\n")
            .filter { !$0.isEmpty }
            .map { line in
                let parts = line.components(separatedBy: "|||")
                return (name: parts.first ?? "", email: parts.last ?? "")
            }
    }

    // MARK: - Private

    private func buildCreateDraftScript(
        to: [FrontmatterParser.Address],
        cc: [FrontmatterParser.Address],
        bcc: [FrontmatterParser.Address],
        subject: String,
        htmlContent: String,
        sender: String?
    ) -> String {
        var lines: [String] = []
        lines.append("tell application \"Mail\"")
        lines.append("    activate")
        lines.append("    set newMsg to make new outgoing message with properties {subject:\"\(escapeAS(subject))\", visible:true}")
        lines.append("    tell newMsg")

        for addr in to {
            lines.append(recipientLine("to", addr))
        }
        for addr in cc {
            lines.append(recipientLine("cc", addr))
        }
        for addr in bcc {
            lines.append(recipientLine("bcc", addr))
        }

        lines.append("    end tell")

        if let sender {
            lines.append("    set sender of newMsg to \"\(escapeAS(sender))\"")
        }

        lines.append("    set html content of newMsg to \"\(escapeAS(htmlContent))\"")
        lines.append("end tell")

        return lines.joined(separator: "\n")
    }

    private func recipientLine(_ type: String, _ addr: FrontmatterParser.Address) -> String {
        if let name = addr.name {
            return "        make new \(type) recipient with properties {name:\"\(escapeAS(name))\", address:\"\(escapeAS(addr.email))\"}"
        }
        return "        make new \(type) recipient with properties {address:\"\(escapeAS(addr.email))\"}"
    }

    @discardableResult
    private func runOsascript(_ script: String) throws -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = ["-e", script]

        let stdout = Pipe()
        let stderr = Pipe()
        process.standardOutput = stdout
        process.standardError = stderr

        try process.run()
        process.waitUntilExit()

        let outputData = stdout.fileHandleForReading.readDataToEndOfFile()
        let errorData = stderr.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: outputData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let errorOutput = String(data: errorData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        if process.terminationStatus != 0 {
            throw AutoMacError.mail(.scriptError(errorOutput.isEmpty ? "osascript exit code \(process.terminationStatus)" : errorOutput))
        }

        return output
    }

    private func escapeAS(_ string: String) -> String {
        string
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: "\\n")
    }
}
