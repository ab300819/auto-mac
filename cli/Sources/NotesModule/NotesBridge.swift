import Foundation
import AutoMacCore

/// 笔记元数据（用于列表展示）
public struct NoteInfo {
    public let id: String
    public let title: String
    public let snippet: String
    public let modified: String

    public init(id: String, title: String, snippet: String, modified: String) {
        self.id = id
        self.title = title
        self.snippet = snippet
        self.modified = modified
    }
}

/// Notes.app 交互封装
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

    /// 列出 Notes.app 中的笔记（默认账户，按修改时间倒序）
    /// - Parameter search: 标题关键词过滤（可选）
    /// - Parameter limit: 最大返回数量
    public func listNotes(search: String? = nil, limit: Int = 50) throws -> [NoteInfo] {
        let separator = "<<<<>>>>"
        let recordSep = "@@@@"

        let whereClause: String
        if let search, !search.isEmpty {
            let escaped = escapeAS(search)
            whereClause = "(every note of default account whose name contains \"\(escaped)\")"
        } else {
            whereClause = "(every note of default account)"
        }

        let script = """
        tell application "Notes"
            set theNotes to \(whereClause)
            set output to ""
            set counter to 0
            repeat with n in theNotes
                if counter ≥ \(limit) then exit repeat
                set noteId to id of n
                set noteName to name of n
                set noteModified to (modification date of n) as string
                set notePlain to plaintext of n
                if (length of notePlain) > 100 then
                    set noteSnippet to text 1 thru 100 of notePlain
                else
                    set noteSnippet to notePlain
                end if
                -- Strip newlines from snippet
                set AppleScript's text item delimiters to {linefeed, return}
                set snippetParts to text items of noteSnippet
                set AppleScript's text item delimiters to " "
                set noteSnippet to snippetParts as string
                set AppleScript's text item delimiters to ""
                set output to output & noteId & "\(separator)" & noteName & "\(separator)" & noteModified & "\(separator)" & noteSnippet & "\(recordSep)"
                set counter to counter + 1
            end repeat
            return output
        end tell
        """

        let result = try runOsascript(script)
        return parseNoteList(result, separator: separator, recordSep: recordSep)
    }

    /// 获取指定笔记的 HTML body
    public func getNoteBody(id: String) throws -> String {
        let escapedId = escapeAS(id)
        let script = """
        tell application "Notes"
            try
                set n to note id "\(escapedId)"
                return body of n
            on error errMsg
                error "NOTE_NOT_FOUND: " & errMsg
            end try
        end tell
        """
        do {
            return try runOsascript(script)
        } catch let error as AutoMacError {
            if case .notes(.scriptError(let msg)) = error, msg.contains("NOTE_NOT_FOUND") {
                throw AutoMacError.notes(.noteNotFound(id))
            }
            throw error
        }
    }

    /// 获取笔记标题
    public func getNoteTitle(id: String) throws -> String {
        let escapedId = escapeAS(id)
        let script = """
        tell application "Notes"
            try
                set n to note id "\(escapedId)"
                return name of n
            on error
                error "NOTE_NOT_FOUND"
            end try
        end tell
        """
        do {
            return try runOsascript(script)
        } catch let error as AutoMacError {
            if case .notes(.scriptError(let msg)) = error, msg.contains("NOTE_NOT_FOUND") {
                throw AutoMacError.notes(.noteNotFound(id))
            }
            throw error
        }
    }

    // MARK: - Private

    private func parseNoteList(_ raw: String, separator: String, recordSep: String) -> [NoteInfo] {
        let records = raw.components(separatedBy: recordSep).filter { !$0.isEmpty }
        return records.compactMap { record in
            let parts = record.components(separatedBy: separator)
            guard parts.count >= 4 else { return nil }
            return NoteInfo(
                id: parts[0].trimmingCharacters(in: .whitespacesAndNewlines),
                title: parts[1].trimmingCharacters(in: .whitespacesAndNewlines),
                snippet: parts[3].trimmingCharacters(in: .whitespacesAndNewlines),
                modified: parts[2].trimmingCharacters(in: .whitespacesAndNewlines)
            )
        }
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
        let output = String(data: outputData, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let errorOutput = String(data: errorData, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        if process.terminationStatus != 0 {
            throw AutoMacError.notes(.scriptError(
                errorOutput.isEmpty ? "osascript exit \(process.terminationStatus)" : errorOutput
            ))
        }

        return output
    }

    private func escapeAS(_ string: String) -> String {
        string
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
    }
}
