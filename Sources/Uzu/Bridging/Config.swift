import uzu_plusFFI

extension Config {
    public init(preset: Preset) {
        self.init(
            preset: preset, contextMode: .none, contextLength: .default, prefillStepSize: .default,
            samplingSeed: .default, asyncBatchSize: .default)
    }

    public func contextMode(_ contextMode: ContextMode) -> Self {
        var result = self
        result.contextMode = contextMode
        return result
    }

    public func contextLength(_ contextLength: ContextLength) -> Self {
        var result = self
        result.contextLength = contextLength
        return result
    }

    public func prefillStepSize(_ prefillStepSize: PrefillStepSize) -> Self {
        var result = self
        result.prefillStepSize = prefillStepSize
        return result
    }

    public func samplingSeed(_ samplingSeed: SamplingSeed) -> Self {
        var result = self
        result.samplingSeed = samplingSeed
        return result
    }

    public func asyncBatchSize(_ asyncBatchSize: AsyncBatchSize) -> Self {
        var result = self
        result.asyncBatchSize = asyncBatchSize
        return result
    }
}
