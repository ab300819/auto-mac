import Foundation

/// JSON / human-readable 输出格式化
public enum OutputFormatter {
    public static func jsonSuccess(command: String, file: String, meta: [String: Any]) -> String {
        let result: [String: Any] = [
            "status": "ok",
            "command": command,
            "file": file,
            "meta": meta,
        ]
        return toJSON(result)
    }

    public static func jsonError(command: String, error: AutoMacError, file: String) -> String {
        var result: [String: Any] = [
            "status": "error",
            "command": command,
            "code": error.code,
            "error": error.localizedDescription,
            "file": file,
        ]
        if case .mail(.accountNotFound(_, let available)) = error {
            result["available_accounts"] = available
        }
        if case .notes(.accountNotFound(_, let available)) = error {
            result["available_accounts"] = available
        }
        return toJSON(result)
    }

    private static func toJSON(_ dict: [String: Any]) -> String {
        guard let data = try? JSONSerialization.data(withJSONObject: dict, options: [.prettyPrinted, .sortedKeys]),
              let string = String(data: data, encoding: .utf8) else {
            return "{\"status\":\"error\",\"error\":\"JSON serialization failed\"}"
        }
        return string
    }
}
