import ArgumentParser
import MailModule
import NotesModule

@main
struct AutoMac: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "auto-mac",
        abstract: "macOS 系统应用自动化工具集",
        version: "0.1.0",
        subcommands: [
            MailCommand.self,
            NotesCommand.self,
        ]
    )
}
