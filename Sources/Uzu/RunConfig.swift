import Foundation
import uzu_plusFFI

extension RunConfig {
    public init() {
        self.init(tokensLimit: 1024, enableThinking: true, samplingPolicy: .default)
    }

    public func tokensLimit(_ tokensLimit: Int64) -> RunConfig {
        var result = self;
        result.tokensLimit = tokensLimit;
        return result;
    }

    public func enableThinking(_ enableThinking: Bool) -> RunConfig {
        var result = self;
        result.enableThinking = enableThinking;
        return result;
    }

    public func samplingPolicy(_ samplingPolicy: SamplingPolicy) -> RunConfig {
        var result = self;
        result.samplingPolicy = samplingPolicy;
        return result;
    }
}
