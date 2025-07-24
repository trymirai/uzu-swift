import Foundation
import Observation
import Uzu

@Observable
final class SummarizationModel {

    // MARK: - Nested Types
    enum ViewState {
        case loading
        case idle
        case generating
        case error(Swift.Error)
    }

    struct GenerationStats: Equatable {
        let timeToFirstToken: Double
        let tokensPerSecond: Double
        let totalTime: Double

        init(output: SessionOutput) {
            self.timeToFirstToken = output.stats.prefillStats.duration
            self.tokensPerSecond = output.stats.generateStats?.tokensPerSecond ?? 0.0
            self.totalTime = output.stats.totalStats.duration
        }
    }

    // MARK: - Observable Properties
    var viewState: ViewState = .loading
    var inputText: String = ""
    var summaryText: String = ""
    var stats: GenerationStats? = nil

    // MARK: - Private
    private let modelId: String
    private var session: Session?
    private var generationTask: Task<Void, Never>?

    init(modelId: String) {
        self.modelId = modelId
    }

    // MARK: - Public API

    func loadSession(using engine: UzuEngine) async {
        do {
            let session = try await engine.createSession(identifier: modelId)
            try session.load(config: SessionConfig(preset: .summarization,
                                                    samplingSeed: .default,
                                                    contextLength: .default))
            self.session = session
            self.viewState = .idle
        } catch {
            self.viewState = .error(error)
        }
    }

    func summarise() {
        guard case .idle = viewState,
              let session,
              !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        summaryText = ""
        stats = nil
        viewState = .generating
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)

        generationTask?.cancel()
        generationTask = Task.detached { [weak self, text] in
            guard let self else { return }
            let prompt = "Text is: \"\(text)\". Write only summary itself."

            do {
                let output = try session.run(
                    input: .text(prompt),
                    tokensLimit: 1024,
                    progress: { partial in
                        if Task.isCancelled { return false }
                        Task { @MainActor [weak self] in
                            self?.summaryText = partial.text
                        }
                        return true
                    }
                )
                
                if Task.isCancelled {
                    Task { @MainActor [weak self] in
                        guard let self else { return }
                        self.summaryText = output.text
                        self.stats = GenerationStats(output: output)
                        self.viewState = .idle
                        self.generationTask = nil
                    }
                    return
                }

                Task { @MainActor [weak self] in
                    guard let self else { return }
                    self.summaryText = output.text
                    self.stats = GenerationStats(output: output)
                    self.viewState = .idle
                    self.generationTask = nil
                }
            } catch {
                Task { @MainActor [weak self] in
                    guard let self else { return }
                    self.viewState = .error(error)
                    self.generationTask = nil
                }
            }
        }
    }

    func stop() {
        generationTask?.cancel()
        generationTask = nil
        viewState = .idle
    }

    func tearDown() {
        generationTask?.cancel()
        generationTask = nil
        session = nil
        viewState = .loading
    }
} 
