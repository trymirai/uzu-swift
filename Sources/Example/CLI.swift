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

    @Argument(
        help: "Mode: chat | chat-static-context | chat-dynamic-context | summarization | classification | quick-start | snippets | cloud",
        transform: { $0.lowercased() })
    var mode: String = "chat"

    mutating func run() async throws {
        switch mode {
        case "chat":
            try await runChat()
        case "chat-static-context":
            try await runChatStaticContext()
        case "chat-dynamic-context":
            try await runChatDynamicContext()
        case "summarization":
            try await runSummarization()
        case "classification":
            try await runClassification()
        case "quick-start":
            try await runQuickStart()
        case "snippets":
            try await runSnippets()
        case "cloud":
            try await runCloud()
        default:
            throw ValidationError("Unknown mode: \(mode)")
        }
    }
}
