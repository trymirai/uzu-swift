import Foundation
import uzu_plusFFI

extension Config {
    public init(preset: Preset) {
        self.init(preset: preset, prefillStepSize: .default, contextLength: .default, samplingSeed: .default)
    }

    public func prefillStepSize(_ prefillStepSize: PrefillStepSize) -> Self {
        var result = self;
        result.prefillStepSize = prefillStepSize;
        return result;
    }

    public func contextLength(_ contextLength: ContextLength) -> Self {
        var result = self;
        result.contextLength = contextLength;
        return result;
    }

    public func samplingSeed(_ samplingSeed: SamplingSeed) -> Self {
        var result = self;
        result.samplingSeed = samplingSeed;
        return result;
    }
}
