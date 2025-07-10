import Foundation
import Observation
import Uzu

@Observable
final class ClassificationModel {
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
    var resultText: String = ""
    var stats: GenerationStats? = nil

    // MARK: - Private
    private let modelId: String
    private let feature: SessionClassificationFeature
    private var session: Session?
    private var generationTask: Task<Void, Never>?

    init(modelId: String, feature: SessionClassificationFeature) {
        self.modelId = modelId
        self.feature = feature
    }

    // MARK: - Public API
    @MainActor
    func loadSession(using engine: UzuEngine) async {
        do {
            let session = try engine.createSession(identifier: modelId)
            try session.load(config: SessionConfig(preset: .classification(feature),
                                                    samplingSeed: .default,
                                                    contextLength: .default))
            self.session = session
            self.viewState = .idle
        } catch {
            self.viewState = .error(error)
        }
    }

    func classify() {
        guard case .idle = viewState,
              let session,
              !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        resultText = ""
        stats = nil
        viewState = .generating
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        let values = feature.values.joined(separator: ", ")
        let prompt = "Text is: \"\(text)\". Choose \(feature.name) from the list: \(values). Answer with one word. Dont't add dot at the end."

        generationTask?.cancel()
        generationTask = Task.detached { [weak self] in
            guard let self else { return }
            let output = session.run(input: .text(prompt),
                                     tokensLimit: 32,
                                      progress: { _ in !Task.isCancelled })

            if Task.isCancelled {
                Task { @MainActor [weak self] in
                    guard let self else { return }
                    self.resultText = output.text.trimmingCharacters(in: .whitespacesAndNewlines)
                    self.stats = GenerationStats(output: output)
                    self.viewState = .idle
                    self.generationTask = nil
                }
                return
            }

            Task { @MainActor [weak self] in
                guard let self else { return }
                self.resultText = output.text.trimmingCharacters(in: .whitespacesAndNewlines)
                self.stats = GenerationStats(output: output)
                self.viewState = .idle
                self.generationTask = nil
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
