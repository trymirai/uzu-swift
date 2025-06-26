import Foundation
import Observation
import Uzu

@MainActor
protocol SessionProvider {
    func createSession(identifier: String) throws -> Session
}

extension UzuEngine: SessionProvider {}

@Observable
public final class SessionRunner {

    // MARK: - Type Definitions

    public typealias ProgressClosure = Session.ProgressClosure

    public enum Error: LocalizedError {
        case notLoaded

        public var errorDescription: String? {
            switch self {
            case .notLoaded:
                "Session has not been loaded yet."
            }
        }
    }

    public enum State: Equatable {
        case idle
        case loading(modelId: String)
        case ready(modelId: String)
        case error(Swift.Error)

        public static func == (lhs: SessionRunner.State, rhs: SessionRunner.State) -> Bool {
            switch (lhs, rhs) {
            case (.idle, .idle): return true
            case let (.loading(a), .loading(b)): return a == b
            case let (.ready(a), .ready(b)): return a == b
            case (.error, .error): return true
            default: return false
            }
        }
    }

    @MainActor
    public private(set) var state: State = .idle

    // MARK: - Private storage

    private let sessionProvider: SessionProvider
    private var session: Session?

    // MARK: - Init

    init(sessionProvider: SessionProvider) {
        self.sessionProvider = sessionProvider
    }

    // MARK: - Private helpers

    private func setState(_ newState: State) {
        Task { @MainActor in
            self.state = newState
        }
    }

    // MARK: - Session lifecycle helpers

    /// Lazily creates a `Session` for `modelId` (if needed) and loads it with the given `preset`.
    /// Safe to call multiple times; it's a no-op when the requested session is already ready.
    public func ensureLoaded(
        modelId: String,
        preset: SessionPreset = .general,
        samplingSeed: SamplingSeed = .default,
        contextLength: ContextLength = .default
    ) async {
        let currentState = await MainActor.run { self.state }
        if case .ready(modelId) = currentState { return }

        setState(.loading(modelId: modelId))

        do {
            let newSession = try await sessionProvider.createSession(identifier: modelId)
            let config = SessionConfig(
                preset: preset,
                samplingSeed: samplingSeed,
                contextLength: contextLength
            )
            try newSession.load(config: config)
            self.session = newSession
            setState(.ready(modelId: modelId))
        } catch {
            self.session = nil
            setState(.error(error))
        }
    }

    @MainActor
    public func destroy() {
        session = nil
        state = .idle
    }

    // MARK: - Running inference

    /// Forwards to the underlying `Session.run`. Throws `.notLoaded` if no session exists.
    /// - Returns: The final `SessionOutput` from the model.
    @discardableResult
    public func run(
        input: SessionInput,
        maxTokens: UInt32 = 128,
        samplingMethod: SamplingConfig = .argmax,
        progress: @escaping ProgressClosure
    ) throws -> SessionOutput {
        guard let session else { throw Error.notLoaded }
        return session.run(
            input: input,
            maxTokens: maxTokens,
            samplingMethod: samplingMethod,
            progress: progress
        )
    }
}
