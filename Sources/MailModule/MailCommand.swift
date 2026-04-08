import ArgumentParser

/// mail 子命令组
public struct MailCommand: AsyncParsableCommand {
    public static let configuration = CommandConfiguration(
        commandName: "mail",
        abstract: "邮件 — 从 Markdown 文件创建 Mail.app 草稿",
        subcommands: [
            MailDraft.self,
            MailPreview.self,
            MailAccounts.self,
        ],
        defaultSubcommand: nil
    )

    public init() {}
}
