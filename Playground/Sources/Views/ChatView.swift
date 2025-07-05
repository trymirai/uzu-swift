import Foundation
import Observation
import SFSymbols
import SwiftUI
import Uzu

enum MessageRole {
    case user
    case assistant
}

struct MessageStats: Equatable {
    let timeToFirstToken: Double
    let tokensPerSecond: Double
    let totalTime: Double

    init(
        timeToFirstToken: Double,
        tokensPerSecond: Double,
        totalTime: Double
    ) {
        self.timeToFirstToken = timeToFirstToken
        self.tokensPerSecond = tokensPerSecond
        self.totalTime = totalTime
    }

    init(output: SessionOutput) {
        self.timeToFirstToken = output.stats.prefillStats.duration
        self.tokensPerSecond = output.stats.generateStats?.tokensPerSecond ?? 0.0
        self.totalTime = output.stats.totalStats.duration
    }
}

struct Message: Identifiable, Equatable {
    let id = UUID()
    let role: MessageRole
    var content: String
    var stats: MessageStats? = nil

    static func == (lhs: Message, rhs: Message) -> Bool {
        lhs.id == rhs.id && lhs.content == rhs.content && lhs.role == rhs.role
            && lhs.stats == rhs.stats
    }
}

struct ChatView: View {

    // MARK: - Environment
    @Environment(Router.self) var router
    @Environment(UzuEngine.self) private var engine
    @Environment(AudioController.self) private var audioController

    // MARK: - State
    @State private var viewModel: ChatModel
    @FocusState private var inputFocused: Bool

    // MARK: - Stored Properties
    let modelId: String

    init(modelId: String) {
        self.modelId = modelId
        _viewModel = State(initialValue: ChatModel(modelId: modelId))
    }

    fileprivate init(messages: [Message], modelId: String, viewState: ChatModel.ViewState) {
        self.modelId = modelId
        _viewModel = State(initialValue: ChatModel(modelId: modelId))
        viewModel.messages = messages
        viewModel.viewState = viewState
    }

    private var isInputDisabled: Bool {
        switch viewModel.viewState {
        case .loading, .generating, .error:
            return true
        case .idle:
            return false
        }
    }

    private var inputPlaceholder: String {
        switch viewModel.viewState {
        case .loading:
            return "Loading..."
        case .generating:
            return "Generating..."
        case let .error(error):
            return "Error: \(error.localizedDescription)"
        case .idle:
            return "Message..."
        }
    }

    private var isInputValid: Bool {
        !viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 20) {
                        ForEach(viewModel.messages) { messageRow(message: $0) }
                    }
                    .padding()
                }
                .onChange(of: viewModel.messages) { _, _ in
                    if let last = viewModel.messages.last {
                        withAnimation {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }
            }
            Divider()
            inputView
                .padding()
        }
        #if os(iOS)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Text(modelId)
                    .font(.monoCaption12Semibold)
                    .foregroundColor(.secondary)
                }
            }
        #endif
        .toolbarRole(.editor)
        .task(id: modelId, priority: .userInitiated) {
            await viewModel.loadSession(using: engine)
        }
        .onDisappear {
            viewModel.tearDown()
        }
    }

    @ViewBuilder
    private var sendMessageButton: some View {
        if case .generating = viewModel.viewState {
            Button(action: stopMessage) {
                Image(systemName: "square.fill")
                    .font(.body16Semibold)
                    .foregroundStyle(.white)
                    .frame(width: 28, height: 28)
                    .background(Color.black)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
            .buttonStyle(.plain)
        } else {
            Button(action: sendMessage) {
                Image(symbol: .arrowUp)
                    .font(.body16Semibold)
                    .foregroundStyle(
                        isInputValid && !isInputDisabled ? .white : Asset.Colors.secondary.swiftUIColor
                    )
                    .frame(width: 28, height: 28)
                    .background(
                        isInputValid && !isInputDisabled ? .black : Asset.Colors.cardBorder.swiftUIColor
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
            .disabled(!isInputValid || isInputDisabled)
            .buttonStyle(.plain)
            #if os(macOS)
                .keyboardShortcut(.defaultAction)
            #endif
        }
    }

    @ViewBuilder
    private var inputView: some View {
        HStack(alignment: .center, spacing: 12) {
            ZStack(alignment: .topLeading) {
                SendTextView(text: $viewModel.inputText) {
                    if isInputValid && !isInputDisabled {
                        sendMessage()
                    }
                }
                .focused($inputFocused)
                .frame(maxWidth: .infinity, alignment: .topLeading)
                .fixedSize(horizontal: false, vertical: true)
                .disabled(isInputDisabled)

                Text(inputPlaceholder)
                    .font(.monoBody16)
                    .foregroundStyle(Asset.Colors.secondary.swiftUIColor)
                    .opacity(viewModel.inputText.isEmpty ? 1.0 : 0.0)
                    .allowsHitTesting(false)
            }
            sendMessageButton
        }
        .padding(12)
        .background(Asset.Colors.card.swiftUIColor)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    @ViewBuilder
    private func messageRow(message: Message) -> some View {
        if message.role == .user {
            userMessageView(message: message)
        } else {
            assistantMessageView(message: message)
        }
    }

    @ViewBuilder
    private func userMessageView(message: Message) -> some View {
        HStack {
            Spacer(minLength: 64)
            Text(LocalizedStringKey(message.content))
                .font(.monoBody16)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Asset.Colors.card.swiftUIColor)
                .foregroundStyle(.primary)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .textSelection(.enabled)
        }
    }

    @ViewBuilder
    private func assistantMessageView(message: Message) -> some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(LocalizedStringKey(message.content))
                    .font(.monoBody16)
                    .textSelection(.enabled)
                if let stats = message.stats {
                    Rectangle()
                        .fill(Asset.Colors.cardBorder.swiftUIColor)
                        .frame(height: 1)
                        .padding(.vertical, 4)
                    VStack(alignment: .leading, spacing: 4) {
                        metricRow(
                            label: "Time to first token:",
                            value: String(format: "%.3f s", stats.timeToFirstToken)
                        )
                        if stats.tokensPerSecond > 0 {
                            metricRow(
                                label: "Tokens per second:",
                                value: String(format: "%.3f t/s", stats.tokensPerSecond)
                            )
                        }
                        metricRow(
                            label: "Total time:",
                            value: String(format: "%.3f s", stats.totalTime)
                        )
                    }
                }
            }
            Spacer(minLength: 64)
        }
    }

    private func stopMessage() {
        viewModel.stopGeneration()
    }

    private func sendMessage() {
        audioController.pause()
        inputFocused = false
        viewModel.sendMessage()
    }

    // MARK: - Metric row helper

    @ViewBuilder
    private func metricRow(label: String, value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Text(label)
                .font(.monoCaption12)
                .foregroundStyle(Asset.Colors.secondary.swiftUIColor)
            Text(value)
                .font(.monoBody16)
        }
    }

}

#Preview("Completed") {
    NavigationStack {
        ChatView(
            messages: [
                Message(role: .user, content: "Hello! How can I help you?"),
                Message(
                    role: .assistant,
                    content:
                        "Hi! I am great, and you? It seems you want to start a conversation. I'll do my best to respond.",
                    stats: MessageStats(
                        timeToFirstToken: 0.234,
                        tokensPerSecond: 89,
                        totalTime: 2.189
                    )
                ),
            ],
            modelId: "Llama-3.2-3B-Instruct",
            viewState: ChatModel.ViewState.idle
        )
        .environment(Router())
        .environment(UzuEngine(apiKey: APIKey.miraiSDK))
        .environment(AudioController())
    }
}

#Preview("Generating") {
    NavigationStack {
        ChatView(
            messages: [
                Message(role: .user, content: "Tell me about SwiftUI."),
                Message(
                    role: .assistant,
                    content:
                        "SwiftUI is a modern way to declare user interfaces for any Apple platform. Create beautiful, dynamic apps faster than ever before. SwiftUI is a declarative framework, which means you can write your code in a way that is easy to read and understand."
                ),
                Message(role: .user, content: "And Combine?"),
                Message(
                    role: .assistant,
                    content:
                        "Combine is a declarative Swift API for processing values over time. These values can represent many kinds of asynchronous events. Combine is built into Swift and is easy to use with SwiftUI. It provides a powerful way to manage asynchronous operations in your apps."
                ),
                Message(role: .user, content: "Thanks!"),
                Message(
                    role: .assistant,
                    content: "You're welcome! Let me know if you have any other questions."),
            ],
            modelId: "Llama-3.2-3B-Instruct",
            viewState: ChatModel.ViewState.generating
        )
        .environment(Router())
        .environment(UzuEngine(apiKey: APIKey.miraiSDK))
        .environment(AudioController())
    }
}

#Preview("Loading Model") {
    ChatView(
        messages: [],
        modelId: "Llama-3.2-3B-Instruct",
        viewState: ChatModel.ViewState.loading
    )
    .environment(Router())
    .environment(UzuEngine(apiKey: APIKey.miraiSDK))
    .environment(AudioController())
}
