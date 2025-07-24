import Foundation
import Observation

#if !targetEnvironment(simulator)
    import uzu_plusFFI
#endif

@MainActor
@Observable
public final class UzuEngine: ModelStateHandler, LicenseStatusHandler {
    // MARK: - Support Types

    public struct ModelInfo {
        public let vendor: String
        public let name: String
        public let precision: String
        public let quantization: String?

        init(vendor: String, name: String, precision: String, quantization: String?) {
            self.vendor = vendor
            self.name = name
            self.precision = precision
            self.quantization = quantization
        }
    }

    // MARK: - Properties
    
    public private(set) var states: [String: ModelDownloadState] = [:]
    public private(set) var info: [String: ModelInfo] = [:]
    public private(set) var licenseStatus: LicenseStatus = .notActivated

    private let engine: Engine
    private var downloadContinuations:
        [String: AsyncThrowingStream<Double, Swift.Error>.Continuation] = [:]

    public func downloadHandle(identifier: String) throws -> DownloadHandle {
        let stream = AsyncThrowingStream<Double, Swift.Error> { continuation in
            if let current = self.states[identifier] {
                continuation.yield(current.progress)
            }

            self.downloadContinuations[identifier] = continuation

            continuation.onTermination = { @Sendable _ in
                Task { @MainActor in
                    self.downloadContinuations.removeValue(forKey: identifier)
                }
            }
        }

        return DownloadHandle(
            identifier: identifier,
            progress: stream,
            startImpl: { [weak self] in try self?.engine.download(identifier: identifier) },
            pauseImpl: { [weak self] in Task { @MainActor in self?.pause(identifier: identifier) }
            },
            resumeImpl: { [weak self] in Task { @MainActor in self?.resume(identifier: identifier) }
            },
            stopImpl: { [weak self] in Task { @MainActor in self?.stop(identifier: identifier) } },
            deleteImpl: { [weak self] in Task { @MainActor in self?.delete(identifier: identifier) }
            }
        )
    }

    public func download(identifier: String) {
        try? self.engine.download(identifier: identifier)
    }

    public init() {
        self.engine = Engine()

        engine.registerLicenseStatusHandler(handler: self)
        engine.registerModelStateHandler(handler: self)

        let initialModels = engine.getModels()
        for model in initialModels {
            self.states[model.identifier] = model.state
            self.info[model.identifier] = ModelInfo(
                vendor: model.vendor,
                name: model.name,
                precision: model.precision,
                quantization: model.quantization
            )
        }
    }

    public func pause(identifier: String) {
        engine.pause(identifier: identifier)
    }

    public func resume(identifier: String) {
        engine.resume(identifier: identifier)
    }

    public func stop(identifier: String) {
        engine.stop(identifier: identifier)
    }

    public func delete(identifier: String) {
        engine.delete(identifier: identifier)
    }

    public func createSession(identifier: String) throws -> Session {
        try engine.createSession(modelId: identifier)
    }

    @discardableResult
    public func updateRegistry() async throws -> [String: ModelDownloadState] {
        _ = try await engine.updateRegistry()

        let modelsSnapshot = engine.getModels()
        var newStates: [String: ModelDownloadState] = [:]
        var newInfo: [String: ModelInfo] = [:]

        for model in modelsSnapshot {
            newStates[model.identifier] = model.state
            newInfo[model.identifier] = ModelInfo(
                vendor: model.vendor,
                name: model.name,
                precision: model.precision,
                quantization: model.quantization
            )
        }

        self.states = newStates
        self.info = newInfo
        return newStates
    }

    nonisolated public func onStatus(status: LicenseStatus) {
        Task { @MainActor in
            self.licenseStatus = status
        }
    }

    nonisolated public func onState(identifier: String, state: ModelDownloadState) {
        Task { @MainActor in
            self.states[identifier] = state

            if let continuation = self.downloadContinuations[identifier] {
                switch state {
                case .downloaded:
                    continuation.yield(state.progress)
                    continuation.finish()
                    self.downloadContinuations.removeValue(forKey: identifier)
                case .error(let err):
                    continuation.yield(state.progress)
                    continuation.finish(throwing: err)
                    self.downloadContinuations.removeValue(forKey: identifier)
                default:
                    // Yield intermediate states (.downloading, .paused)
                    continuation.yield(state.progress)
                }
            }
        }
    }

    // MARK: - License activation

    @discardableResult
    public func activate(apiKey: String) async throws -> LicenseStatus {
        try await engine.activate(apiKey: apiKey)
    }
}
