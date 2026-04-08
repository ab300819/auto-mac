import Foundation
import Yams

/// 解析 Markdown 文件的 YAML frontmatter 和正文
public struct FrontmatterParser {
    public struct EmailMetadata {
        public let to: [Address]
        public let cc: [Address]
        public let bcc: [Address]
        public let subject: String
        public let account: String?
    }

    public struct Address: Equatable {
        public let name: String?
        public let email: String

        public init(name: String? = nil, email: String) {
            self.name = name
            self.email = email
        }
    }

    public struct ParseResult {
        public let metadata: EmailMetadata
        public let body: String
    }

    public init() {}

    /// 从 Markdown 字符串中提取 frontmatter 和正文
    public func parse(_ content: String) throws -> ParseResult {
        let (yamlString, body) = try splitFrontmatter(content)
        let metadata = try parseYAML(yamlString)
        return ParseResult(metadata: metadata, body: body)
    }

    // MARK: - Private

    private func splitFrontmatter(_ content: String) throws -> (yaml: String, body: String) {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.hasPrefix("---") else {
            throw AutoMacError.parse(.missingFrontmatter)
        }

        let lines = content.components(separatedBy: "\n")
        var yamlLines: [String] = []
        var bodyStartIndex = 0
        var foundEnd = false

        for (index, line) in lines.enumerated() {
            if index == 0 { continue } // skip opening ---
            if line.trimmingCharacters(in: .whitespaces) == "---" {
                bodyStartIndex = index + 1
                foundEnd = true
                break
            }
            yamlLines.append(line)
        }

        guard foundEnd else {
            throw AutoMacError.parse(.unclosedFrontmatter)
        }

        let yaml = yamlLines.joined(separator: "\n")
        let body = lines[bodyStartIndex...].joined(separator: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return (yaml, body)
    }

    private func parseYAML(_ yamlString: String) throws -> EmailMetadata {
        guard let yaml = try Yams.load(yaml: yamlString) as? [String: Any] else {
            throw AutoMacError.parse(.invalidYAML)
        }

        guard let subject = yaml["subject"] as? String else {
            throw AutoMacError.parse(.missingField("subject"))
        }

        let to = try parseAddressField(yaml["to"])
        guard !to.isEmpty else {
            throw AutoMacError.parse(.missingField("to"))
        }

        let cc = try parseAddressField(yaml["cc"])
        let bcc = try parseAddressField(yaml["bcc"])
        let account = yaml["account"] as? String

        return EmailMetadata(to: to, cc: cc, bcc: bcc, subject: subject, account: account)
    }

    private func parseAddressField(_ value: Any?) throws -> [Address] {
        guard let value else { return [] }

        if let str = value as? String {
            return [try AddressParser.parse(str)]
        }

        if let array = value as? [Any] {
            return try array.map { item in
                if let str = item as? String {
                    return try AddressParser.parse(str)
                }
                if let dict = item as? [String: String],
                   let email = dict["email"] {
                    return Address(name: dict["name"], email: email)
                }
                throw AutoMacError.parse(.invalidAddress)
            }
        }

        throw AutoMacError.parse(.invalidAddress)
    }
}
