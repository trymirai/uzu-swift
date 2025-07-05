import Foundation
import Observation
import Uzu

// MARK: - Supporting Types

extension ChatModel {
    enum ViewState {
        case loading
        case idle
        case generating
        case error(Swift.Error)
    }
}

@Observable
final class ChatModel {

    // MARK: - Publicly observed properties
    var viewState: ViewState = .loading
    var messages: [Message] = []
    var inputText: String = ""

    // MARK: - Private
    private let modelId: String
    private var session: Session?
    private var generationTask: Task<Void, Never>?

    init(modelId: String) {
        self.modelId = modelId
    }

    // MARK: - Lifecycle
    @MainActor
    func loadSession(using engine: UzuEngine) async {
        do {
            let session = try engine.createSession(identifier: modelId)
            try session.load(config: SessionConfig(preset: .general,
                                                   samplingSeed: .default,
                                                   contextLength: .default))
            self.session = session
            self.viewState = .idle
        } catch {
            self.viewState = .error(error)
        }
    }

    func tearDown() {
        generationTask?.cancel()
        generationTask = nil
        session = nil
    }

    // MARK: - User intents
    func sendMessage() {
        guard case .idle = viewState,
              let session,
              !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        let userInput = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        inputText = ""

        messages.append(Message(role: .user, content: userInput))
        let assistantMessage = Message(role: .assistant, content: "")
        messages.append(assistantMessage)
        viewState = .generating

        generationTask?.cancel()
        generationTask = Task.detached { [weak self, assistantId = assistantMessage.id] in
            guard let self else { return }
            let inputMessages = self.messages.dropLast().map { msg -> SessionMessage in
                let role: SessionMessageRole = msg.role == .user ? .user : .assistant
                return SessionMessage(role: role, content: msg.content)
            }
            let input = SessionInput.messages(inputMessages)

            let output = session.run(
                input: input,
                tokensLimit: 1024,
                progress: { partial in
                    if Task.isCancelled { return false }
                    Task { @MainActor [weak self] in
                        guard let self,
                              let idx = self.messages.firstIndex(where: { $0.id == assistantId }) else { return }
                        self.messages[idx].content = partial.text
                    }
                    return true
                })

            if Task.isCancelled {
                Task { @MainActor [weak self] in
                    self?.viewState = .idle
                    self?.generationTask = nil
                }
                return
            }

            Task { @MainActor [weak self] in
                guard let self,
                      let idx = self.messages.firstIndex(where: { $0.id == assistantId }) else { return }
                self.messages[idx].content = output.text
                self.messages[idx].stats = MessageStats(output: output)
                self.viewState = .idle
            }
        }
    }

    func stopGeneration() {
        generationTask?.cancel()
        generationTask = nil
        viewState = .idle
    }
} 
