import Foundation
import AutoMacCore

/// Notes.app 交互封装
/// 使用 open -a Notes 导入 Markdown（Notes 原生渲染）
public struct NotesBridge {
    public init() {}

    /// 导入 Markdown 文件到 Notes.app（Notes 原生解析渲染）
    public func importMarkdown(filePath: String) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        process.arguments = ["-a", "Notes", filePath]

        let stderr = Pipe()
        process.standardError = stderr

        try process.run()
        process.waitUntilExit()

        if process.terminationStatus != 0 {
            let errorData = stderr.fileHandleForReading.readDataToEndOfFile()
            let errorOutput = String(data: errorData, encoding: .utf8)?
                .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            throw AutoMacError.notes(.scriptError(
                errorOutput.isEmpty ? "open exit code \(process.terminationStatus)" : errorOutput
            ))
        }
    }
}
