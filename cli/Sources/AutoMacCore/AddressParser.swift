import Foundation

/// 解析邮件地址的三种格式
public enum AddressParser {
    /// 解析单个地址字符串
    /// 支持：
    /// - 纯地址: "user@example.com"
    /// - RFC 格式: "张三 <zhangsan@example.com>"
    public static func parse(_ string: String) throws -> FrontmatterParser.Address {
        let trimmed = string.trimmingCharacters(in: .whitespaces)

        // RFC 格式: Name <email>
        if let angleBracketRange = trimmed.range(of: "<"),
           let closingRange = trimmed.range(of: ">"),
           angleBracketRange.lowerBound < closingRange.lowerBound {
            let name = String(trimmed[..<angleBracketRange.lowerBound])
                .trimmingCharacters(in: .whitespaces)
            let email = String(trimmed[angleBracketRange.upperBound..<closingRange.lowerBound])
                .trimmingCharacters(in: .whitespaces)
            guard isValidEmail(email) else {
                throw AutoMacError.parse(.invalidAddress)
            }
            return FrontmatterParser.Address(
                name: name.isEmpty ? nil : name,
                email: email
            )
        }

        // 纯地址
        guard isValidEmail(trimmed) else {
            throw AutoMacError.parse(.invalidAddress)
        }
        return FrontmatterParser.Address(email: trimmed)
    }

    private static func isValidEmail(_ email: String) -> Bool {
        email.contains("@") && email.contains(".")
    }
}
