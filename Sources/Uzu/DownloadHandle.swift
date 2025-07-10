public struct DownloadHandle: Sendable {
    public let identifier: String
    public let progress: AsyncThrowingStream<Double, Swift.Error>

    private let startImpl: @Sendable () throws -> Void
    private let pauseImpl: @Sendable () -> Void
    private let resumeImpl: @Sendable () -> Void
    private let stopImpl: @Sendable () -> Void
    private let deleteImpl: @Sendable () -> Void

    public init(
        identifier: String,
        progress: AsyncThrowingStream<Double, Swift.Error>,
        startImpl: @Sendable @escaping () throws -> Void,
        pauseImpl: @Sendable @escaping () -> Void,
        resumeImpl: @Sendable @escaping () -> Void,
        stopImpl: @Sendable @escaping () -> Void,
        deleteImpl: @Sendable @escaping () -> Void
    ) {
        self.identifier = identifier
        self.progress = progress
        self.startImpl = startImpl
        self.pauseImpl = pauseImpl
        self.resumeImpl = resumeImpl
        self.stopImpl = stopImpl
        self.deleteImpl = deleteImpl
    }

    public func pause()  { pauseImpl() }
    public func resume() { resumeImpl() }
    public func stop()   { stopImpl() }
    public func delete() { deleteImpl() }

    public func startDownload() throws {
        try startImpl()
    }
} 