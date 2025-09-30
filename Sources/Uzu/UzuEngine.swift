import Foundation
import Observation

#if !targetEnvironment(simulator)
    import uzu_plusFFI
#endif

@MainActor
@Observable
public final class UzuEngine: ModelStateHandler, LicenseStatusHandler, CloudModelsHandler {

    // MARK: - Properties

    public private(set) var localModels: Set<LocalModel> = []
    public private(set) var cloudModels: Set<CloudModel> = []
    public private(set) var licenseStatus: LicenseStatus = .notActivated

    private let engine: Engine

    public init() {
        self.engine = Engine.make()

        engine.registerLicenseStatusHandler(handler: self)
        engine.registerModelStateHandler(handler: self)
        engine.registerCloudModelsHandler(handler: self)

        let initialModels = engine.getLocalModels()
        self.localModels = Set(initialModels)
    }

    public func refreshCloudModels() async {
        do {
            let models = try await engine.fetchCloudModels()
            self.cloudModels = Set(models)
        } catch {
            self.cloudModels = []
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

    public func createSession(_ modelId: ModelId, config: Config) throws -> Session {
        try engine.createSession(modelId: modelId, config: config)
    }
    
    public func downloadHandle(identifier: String) throws -> DownloadHandle {
        return engine.downloadHandle(identifier: identifier)
    }

    public func downloadState(identifier: String) -> ModelDownloadState? {
        localModels.first(where: { $0.identifier == identifier })?.state
    }

    public func download(identifier: String) throws {
        try self.engine.download(identifier: identifier)
    }

    public func updateRegistry() async throws {
        _ = try await engine.updateRegistry()
        self.localModels = Set(engine.getLocalModels())
    }

    nonisolated public func onStatus(status: LicenseStatus) {
        Task { @MainActor in
            self.licenseStatus = status
        }
    }

    nonisolated public func onLocalModel(model: LocalModel) {
        Task { @MainActor in
            if let existing = self.localModels.first(where: { $0.identifier == model.identifier }) {
                self.localModels.remove(existing)
            }
            self.localModels.insert(model)
        }
    }

    nonisolated public func onCloudModels(models: [CloudModel]) {
        Task { @MainActor in
            self.cloudModels = Set(models)
        }
    }

    // MARK: - License activation

    @discardableResult
    public func activate(apiKey: String) async throws -> LicenseStatus {
        try await engine.activate(apiKey: apiKey)
    }
}
