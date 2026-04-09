import ArgumentParser
import AutoMacCore
import Foundation

/// notes create 子命令 — 将 Markdown 文件导入 Apple Notes（原生渲染）
struct NotesCreate: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "create",
        abstract: "将 Markdown 文件导入 Apple Notes",
        discussion: """
        Notes.app 原生解析 Markdown 并渲染为富文本格式。
        支持标题、加粗、斜体、列表、代码块、链接等。

        示例:
          auto-mac notes create meeting.md
          auto-mac notes create report.md --dry-run --json
        """
    )

    @Argument(help: "Markdown 文件路径")
    var file: String

    @Flag(name: .long, help: "只验证文件，不导入到 Notes")
    var dryRun: Bool = false

    @Flag(name: .long, help: "JSON 格式输出")
    var json: Bool = false

    func run() async throws {
        // 验证文件存在
        guard FileManager.default.fileExists(atPath: file) else {
            let error = AutoMacError.notes(.scriptError("文件不存在: \(file)"))
            if json {
                print(OutputFormatter.jsonError(command: "notes.create", error: error, file: file))
            } else {
                printError("文件不存在: \(file)")
            }
            throw ExitCode.failure
        }

        // 验证是 Markdown 文件
        let url = URL(fileURLWithPath: file)
        guard ["md", "markdown"].contains(url.pathExtension.lowercased()) else {
            let error = AutoMacError.notes(.scriptError("不是 Markdown 文件: \(file)"))
            if json {
                print(OutputFormatter.jsonError(command: "notes.create", error: error, file: file))
            } else {
                printError("不是 Markdown 文件: \(file)")
            }
            throw ExitCode.failure
        }

        let filename = url.deletingPathExtension().lastPathComponent

        if dryRun {
            if json {
                print(OutputFormatter.jsonSuccess(
                    command: "notes.create",
                    file: file,
                    meta: ["title": filename, "dry_run": true]
                ))
            } else {
                print("📝 备忘录导入预检（dry-run）")
                print("  文件: \(file)")
                print("  标题: \(filename)")
            }
            return
        }

        let absolutePath = url.standardizedFileURL.path
        let bridge = NotesBridge()
        do {
            try bridge.importMarkdown(filePath: absolutePath)
        } catch let error as AutoMacError {
            if json {
                print(OutputFormatter.jsonError(command: "notes.create", error: error, file: file))
            } else {
                printError(error.localizedDescription)
            }
            throw ExitCode.failure
        }

        if json {
            print(OutputFormatter.jsonSuccess(
                command: "notes.create",
                file: file,
                meta: ["title": filename]
            ))
        } else {
            print("✓ 已导入到 Apple Notes")
            print("  文件: \(file)")
            print("  标题: \(filename)")
        }
    }

    private func printError(_ message: String) {
        FileHandle.standardError.write("✗ \(message)\n".data(using: .utf8)!)
    }
}
