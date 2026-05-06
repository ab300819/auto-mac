import ArgumentParser

/// notes 子命令组
public struct NotesCommand: AsyncParsableCommand {
    public static let configuration = CommandConfiguration(
        commandName: "notes",
        abstract: "备忘录 — 从 Markdown 文件创建 Apple Notes 笔记",
        subcommands: [
            NotesCreate.self,
            NotesExport.self,
        ],
        defaultSubcommand: nil
    )

    public init() {}
}
