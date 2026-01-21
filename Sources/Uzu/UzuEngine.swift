import Observation
import uzu_plusFFI

@Observable
public final class UzuEngine {
    @MainActor public private(set) var licenseStatus: LicenseStatus = .notActivated
    @MainActor public private(set) var downloadStates: [String: ModelDownloadState] = [:]
    @MainActor public private(set) var chatModels: Set<ChatModel> = []

    private let engine: Engine

    public init() throws {
        let engine = Engine.make()
        self.engine = engine

        try engine.registerLicenseStatusHandler(handler: self)
        try engine.registerModelDownloadStateHandler(handler: self)
        try engine.registerChatModelsHandler(handler: self)
    }

    public static func create(apiKey: String) async throws -> Self {
        let engine = try Self.init();
        let licenseStatus = try await engine.activate(apiKey: apiKey);
        switch licenseStatus {
        case .activated, .gracePeriodActive:
            break;
        case .notActivated, .invalidApiKey, .httpError, .networkError, .paymentRequired, .signatureMismatch, .timeout:
            throw UzuError.licenseNotActivated
        }
        let _ = try await engine.chatModels();
        return engine
    }

    @discardableResult
    public func activate(apiKey: String) async throws -> LicenseStatus {
        return try await engine.activate(apiKey: apiKey)
    }

    public func getDownloadState(repoId: String) throws -> ModelDownloadState {
        return try self.engine.getModelDownloadState(repoId: repoId)
    }

    public func downloadHandle(repoId: String) throws -> ModelDownloadHandle {
        return try self.engine.createModelDownloadHandle(repoId: repoId)
    }

    public func chatModels(types: [ModelType] = [.local, .cloud]) async throws -> [ChatModel] {
        return try await engine.getChatModels(types: types)
    }

    public func chatModel(repoId: String, types: [ModelType] = [.local, .cloud]) async throws -> ChatModel {
        let chatModels = try await self.chatModels(types: types)
        guard let chatModel = chatModels.first(where: { $0.repoId == repoId }) else {
            throw UzuError.modelNotFound
        }
        return chatModel
    }

    @discardableResult
    public func downloadChatModel(_ model: ChatModel, progressBlock: (ProgressUpdate) -> Void = {_ in}) async throws -> ModelDownloadState {
        switch model.type {
        case .local:
            break;
        case .cloud:
            throw UzuError.unexpectedModelType
        }

        let downloadHandle = try self.downloadHandle(repoId: model.repoId)
        let state = try await downloadHandle.state();
        switch state.phase {
        case .downloaded:
            break;
        case .paused, .notDownloaded, .downloading, .error, .locked:
            try await downloadHandle.download();
            let progressStream = downloadHandle.progress()
            while let progressUpdate = await progressStream.next() {
                progressBlock(progressUpdate)
            }
            break;
        }

        let finalState = try await downloadHandle.state();
        return finalState;
    }

    public func chatSession(_ chatModel: ChatModel, config: Config = Config(preset: .general)) throws -> ChatSession {
        #if targetEnvironment(simulator)
            throw SimulatorError.notSupported
        #endif
        
        return try engine.createChatSession(model: chatModel, config: config)
    }

    public func benchmark(_ task: BenchmarksTask, prefillStepSize: Int64? = nil) async throws -> [BenchmarksResult] {
        return try await self.engine.benchmark(task: task, prefillStepSize: prefillStepSize)
    }
}

extension UzuEngine: LicenseStatusHandler {
    public func onLicenseStatusChanged(status: LicenseStatus) {
        Task { @MainActor [weak self] in
            guard let self else {
                return
            }
            self.licenseStatus = status
        }
    }
}

extension UzuEngine: ModelDownloadStateHandler {
    public func onModelDownloadStateChanged(repoId: String, state: ModelDownloadState) {
        Task { @MainActor [weak self] in
            guard let self else {
                return
            }
            self.downloadStates[repoId] = state;
        }
    }
}

extension UzuEngine: ChatModelsHandler {
    public func onChatModelsChanged(models: [ChatModel]) {
        Task { @MainActor [weak self] in
            guard let self else {
                return
            }
            self.chatModels = Set(models)
        }
    }
}
