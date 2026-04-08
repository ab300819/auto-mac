import Foundation

/// auto-mac 统一错误类型
public enum AutoMacError: LocalizedError {
    case parse(ParseError)
    case render(String)
    case mail(MailError)

    public enum ParseError {
        case missingFrontmatter
        case unclosedFrontmatter
        case invalidYAML
        case missingField(String)
        case invalidAddress
    }

    public enum MailError {
        case notInstalled
        case accountNotFound(requested: String, available: [String])
        case scriptError(String)
    }

    /// 错误码映射
    public var code: String {
        switch self {
        case .parse(let e):
            switch e {
            case .missingFrontmatter, .unclosedFrontmatter, .invalidYAML: return "E001"
            case .missingField: return "E001"
            case .invalidAddress: return "E002"
            }
        case .render: return "E003"
        case .mail(let e):
            switch e {
            case .notInstalled: return "E005"
            case .accountNotFound: return "E006"
            case .scriptError: return "E007"
            }
        }
    }

    public var errorDescription: String? {
        switch self {
        case .parse(let e):
            switch e {
            case .missingFrontmatter: return "Markdown 文件缺少 YAML frontmatter"
            case .unclosedFrontmatter: return "Frontmatter 未正确闭合（缺少结束 ---）"
            case .invalidYAML: return "Frontmatter YAML 格式无效"
            case .missingField(let field): return "缺少必填字段：\(field)"
            case .invalidAddress: return "地址格式无法识别"
            }
        case .render(let msg): return "Markdown 渲染失败：\(msg)"
        case .mail(let e):
            switch e {
            case .notInstalled: return "Mail.app 未安装或无法启动"
            case .accountNotFound(let req, let avail):
                return "发件账户 '\(req)' 不存在。可用账户：\(avail.joined(separator: ", "))"
            case .scriptError(let msg):
                return "AppleScript 执行失败：\(msg)"
            }
        }
    }
}
