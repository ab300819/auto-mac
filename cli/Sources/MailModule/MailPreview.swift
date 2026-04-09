import ArgumentParser
import AutoMacCore

/// mail preview 子命令 — 启动浏览器预览
struct MailPreview: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "preview",
        abstract: "启动浏览器预览（支持实时热重载）",
        discussion: """
        示例:
          auto-mac mail preview meeting.md
          auto-mac mail preview meeting.md --port 3456
          auto-mac mail preview meeting.md --no-watch
        """
    )

    @Argument(help: "Markdown 文件路径")
    var file: String

    @Option(name: .long, help: "指定预览服务器端口（默认自动分配）")
    var port: Int?

    @Flag(name: .long, help: "不监听文件变化，只启动一次预览")
    var noWatch: Bool = false

    @Flag(name: .long, help: "JSON 格式输出")
    var json: Bool = false

    func run() async throws {
        // TODO: Phase 3 — PreviewServer + HTMLRenderer 实现
        print("⚠️ preview 命令尚未实现。")
    }
}
