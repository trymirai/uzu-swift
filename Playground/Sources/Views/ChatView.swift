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

    // MARK: - Type Definitions
    enum ViewState {
        case loading
        case idle
        case error(Swift.Error)
        case generating
    }

    // MARK: - Environment
    @Environment(Router.self) var router
    @Environment(UzuEngine.self) private var engine
    @Environment(AudioController.self) private var audioController

    // MARK: - State
    // Local `Session` instance managed by this view
    @State private var session: Session?
    @State private var messages: [Message] = []
    @State private var inputText: String = ""
    @State private var generationTask: Task<Void, Never>?
    @FocusState private var inputFocused: Bool
    @State private var viewState: ViewState

    // MARK: - Stored Properties
    let modelId: String

    init(modelId: String) {
        self.modelId = modelId
        self._viewState = State(initialValue: .loading)
    }

    fileprivate init(
        messages: [Message], modelId: String, viewState: ViewState
    ) {
        self._viewState = State(initialValue: viewState)
        self.modelId = modelId
        self._messages = State(initialValue: messages)
    }

    private var isInputDisabled: Bool {
        switch viewState {
        case .loading, .generating, .error:
            return true
        case .idle:
            return false
        }
    }

    private var inputPlaceholder: String {
        switch viewState {
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
        !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 20) {
                        ForEach(messages) { messageRow(message: $0) }
                    }
                    .padding()
                }
                .onChange(of: messages) { _, _ in
                    if let last = messages.last {
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
            do {
                let session = try engine.createSession(identifier: modelId)
                try session.load(
                    config: SessionConfig(
                        preset: .general,
                        samplingSeed: .default,
                        contextLength: .custom(1024)
                    )
                )
                await MainActor.run {
                    self.session = session
                    self.viewState = .idle
                }
            } catch {
                await MainActor.run {
                    self.viewState = .error(error)
                }
            }
        }
        .onDisappear {
            generationTask?.cancel()
            generationTask = nil
            session = nil
            viewState = .loading
        }
    }

    @ViewBuilder
    private var sendMessageButton: some View {
        if case .generating = viewState {
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
                SendTextView(text: $inputText) {
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
                    .opacity(inputText.isEmpty ? 1.0 : 0.0)
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
        generationTask?.cancel()
    }

    private func sendMessage() {
        guard case .idle = viewState, let session else { return }

        audioController.pause()
        let userInput = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        inputText = ""
        inputFocused = false

        messages.append(Message(role: .user, content: userInput))

        let assistantMessage = Message(role: .assistant, content: "")
        messages.append(assistantMessage)

        viewState = .generating

        generationTask = Task.detached { [assistantId = assistantMessage.id, messages, session] in

            let inputMessages = messages.dropLast().map { msg -> SessionMessage in
                let role: SessionMessageRole = (msg.role == .user) ? .user : .assistant
                return SessionMessage(role: role, content: msg.content)
            }
            let input = SessionInput.messages(inputMessages)

            let finalOutput = session.run(
                input: input,
                maxTokens: 128,
                progress: { partial in
                    if Task.isCancelled {
                        return false
                    }
                    Task { @MainActor in
                        if let idx = self.messages.firstIndex(where: { $0.id == assistantId }) {
                            self.messages[idx].content = partial.text
                        }
                    }
                    return true
                }
            )

            guard !Task.isCancelled else {
                Task { @MainActor in
                    self.viewState = .idle
                }
                return
            }

            Task { @MainActor in
                if let idx = self.messages.firstIndex(where: { $0.id == assistantId }) {
                    self.messages[idx].content = finalOutput.text
                    self.messages[idx].stats = MessageStats(
                        timeToFirstToken: finalOutput.stats.prefillStats.duration,
                        tokensPerSecond: finalOutput.stats.generateStats?.tokensPerSecond ?? 0.0,
                        totalTime: finalOutput.stats.totalStats.duration
                    )
                }
                self.viewState = .idle
            }
        }
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
            viewState: .idle
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
            viewState: .generating
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
        viewState: .loading
    )
    .environment(Router())
    .environment(UzuEngine(apiKey: APIKey.miraiSDK))
    .environment(AudioController())
}
