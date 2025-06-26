import Foundation
import Observation
import uzu_plusFFI

@MainActor
@Observable
public final class UzuEngine: ModelStateHandler, LicenseStatusHandler {
    private let engine: Engine
    public var states: [String: ModelState] = [:]
    public var info: [String: (vendor: String, name: String, precision: String)] = [:]
    public var licenseStatus: LicenseStatus = .notActivated

    public init(apiKey: String) {
        self.engine = Engine(apiKey: apiKey)

        engine.registerLicenseStatusHandler(handler: self)
        engine.registerModelStateHandler(handler: self)

        let initialModels = engine.getModels()
        for model in initialModels {
            self.states[model.identifier] = model.state
            self.info[model.identifier] = (model.vendor, model.name, model.precision)
        }
    }

    public func download(identifier: String) {
        engine.download(identifier: identifier)
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
    public func updateRegistry() async throws -> [String: ModelState] {
        _ = try await engine.updateRegistry()

        let modelsSnapshot = engine.getModels()
        var newStates: [String: ModelState] = [:]
        var newInfo: [String: (vendor: String, name: String, precision: String)] = [:]

        for model in modelsSnapshot {
            newStates[model.identifier] = model.state
            newInfo[model.identifier] = (model.vendor, model.name, model.precision)
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

    nonisolated public func onState(identifier: String, state: ModelState) {
        Task { @MainActor in
            self.states[identifier] = state
        }
    }
}
