import ArgumentParser
import AutoMacCore
import Foundation

/// notes export 子命令 — 列出/导出 Apple Notes 笔记为 Markdown
struct NotesExport: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "export",
        abstract: "列出或导出 Apple Notes 笔记为 Markdown",
        discussion: """
        两种模式：
          --list             列出笔记元数据（供编辑器选择器使用）
          --id <noteId>      导出指定笔记为 Markdown

        示例:
          auto-mac notes export --list --json
          auto-mac notes export --list --search 会议 --json
          auto-mac notes export --id "x-coredata://..." --json
        """
    )

    @Flag(name: .long, help: "列出笔记（不导出内容）")
    var list: Bool = false

    @Option(name: .long, help: "导出指定笔记 ID")
    var id: String?

    @Option(name: .long, help: "标题关键词过滤")
    var search: String?

    @Option(name: .long, help: "最大返回数量（仅 --list）")
    var limit: Int = 50

    @Flag(name: .long, help: "JSON 格式输出")
    var json: Bool = false

    func run() async throws {
        let bridge = NotesBridge()

        if list {
            try await runList(bridge: bridge)
        } else if let noteId = id {
            try await runExport(bridge: bridge, noteId: noteId)
        } else {
            // 默认行为 = 列出
            try await runList(bridge: bridge)
        }
    }

    private func runList(bridge: NotesBridge) async throws {
        let notes: [NoteInfo]
        do {
            notes = try bridge.listNotes(search: search, limit: limit)
        } catch let error as AutoMacError {
            if json {
                print(OutputFormatter.jsonError(command: "notes.export", error: error, file: ""))
            } else {
                printError(error.localizedDescription)
            }
            throw ExitCode.failure
        }

        if json {
            let dicts = notes.map { note -> [String: Any] in
                [
                    "id": note.id,
                    "title": note.title,
                    "snippet": note.snippet,
                    "modified": note.modified,
                ]
            }
            let result: [String: Any] = [
                "status": "ok",
                "command": "notes.export",
                "notes": dicts,
            ]
            print(toJSON(result))
        } else {
            if notes.isEmpty {
                print("（没有找到笔记）")
            } else {
                print("找到 \(notes.count) 条笔记：")
                for note in notes {
                    print("  • \(note.title)")
                    if !note.snippet.isEmpty {
                        let snippet = String(note.snippet.prefix(60))
                        print("    \(snippet)\(note.snippet.count > 60 ? "..." : "")")
                    }
                    print("    id: \(note.id)")
                }
            }
        }
    }

    private func runExport(bridge: NotesBridge, noteId: String) async throws {
        let title: String
        let html: String
        do {
            title = try bridge.getNoteTitle(id: noteId)
            html = try bridge.getNoteBody(id: noteId)
        } catch let error as AutoMacError {
            if json {
                print(OutputFormatter.jsonError(command: "notes.export", error: error, file: ""))
            } else {
                printError(error.localizedDescription)
            }
            throw ExitCode.failure
        }

        let converter = HTMLToMarkdown()
        let markdown = converter.convert(html)

        if json {
            let result: [String: Any] = [
                "status": "ok",
                "command": "notes.export",
                "note": [
                    "id": noteId,
                    "title": title,
                    "markdown": markdown,
                ],
            ]
            print(toJSON(result))
        } else {
            print(markdown)
        }
    }

    private func toJSON(_ dict: [String: Any]) -> String {
        let options: JSONSerialization.WritingOptions = [.prettyPrinted, .sortedKeys]
        guard let data = try? JSONSerialization.data(withJSONObject: dict, options: options),
              let str = String(data: data, encoding: .utf8) else {
            return "{\"status\":\"error\",\"error\":\"JSON serialization failed\"}"
        }
        return str
    }

    private func printError(_ message: String) {
        FileHandle.standardError.write("✗ \(message)\n".data(using: .utf8)!)
    }
}
