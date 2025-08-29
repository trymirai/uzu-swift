import ArgumentParser
import Foundation

@available(macOS 10.15, macCatalyst 13, iOS 13, tvOS 13, watchOS 6, *)
@main
struct Example: AsyncParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "example",
        abstract: "Uzu example CLI",
        version: "1.0.0"
    )

    @Argument(help: "Mode: chat | summarisation | classification", transform: { $0.lowercased() })
    var mode: String = "chat"

    mutating func run() async throws {
        switch mode {
        case "chat":
            try await runChat()
        case "summarisation":
            try await runSummarisation()
        case "classification":
            try await runClassification()
        default:
            throw ValidationError("Unknown mode: \(mode)")
        }
    }
}
