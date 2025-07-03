import Foundation
import Observation
import SFSymbols
import SwiftUI
import Uzu

#if canImport(UIKit)
    import UIKit
#endif

struct ClassificationView: View {

    // MARK: - Type Definitions

    private enum ViewState {
        case loading
        case idle
        case error(Swift.Error)
        case generating
    }

    // MARK: - Environment

    @Environment(Router.self) private var router
    @Environment(UzuEngine.self) private var engine
    @Environment(AudioController.self) private var audioController
    @State private var session: Session?

    // MARK: - State

    @State private var inputText: String = ClassificationView.textsToClassify.randomElement()!
    @State private var resultText: String = ""
    @State private var generationStats: MessageStats? = nil
    @State private var generationTask: Task<Void, Never>?
    @FocusState private var inputFocused: Bool
    @State private var viewState: ViewState = .loading

    // MARK: - Stored Properties

    let modelId: String

    static let textsToClassify = [
        "Today's been awesome! Everything just feels right, and I can't stop smiling."
    ]

    static let sentiments = [
        "Happy",
        "Sad",
        "Angry",
        "Fearful",
        "Surprised",
        "Disgusted",
    ]

    private var feature: SessionClassificationFeature {
        SessionClassificationFeature(name: "sentiment", values: Self.sentiments)
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 20) {
                        input
                        if !resultText.isEmpty {
                            result
                        }

                        Color.clear
                            .frame(height: 1)
                            .id("bottom")
                    }
                    .padding()
                }
                .onChange(of: resultText) { _, _ in
                    withAnimation {
                        proxy.scrollTo("bottom", anchor: .bottom)
                    }
                }
            }
            Divider()
            bottomBar
                .padding()
        }
        .background(Asset.Colors.background.swiftUIColor)
        #if os(iOS)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Text(modelId)
                    .font(.monoCaption12Semibold)
                    .foregroundColor(.secondary)
                }
            }
        #endif
        .toolbarRole(.editor)
        .task(id: modelId, priority: .userInitiated) {
            do {
                let session = try engine.createSession(identifier: modelId)
                try session.load(
                    config: SessionConfig(
                        preset: .classification(feature),
                        samplingSeed: .default,
                        contextLength: .custom(8192)
                    )
                )
                await MainActor.run {
                    self.session = session
                    self.viewState = .idle
                }
            } catch {
                await MainActor.run {
                    self.viewState = .error(error)
                }
            }
        }
        .onDisappear {
            generationTask?.cancel()
            generationTask = nil
            session = nil
            viewState = .loading
        }
    }

    // MARK: - UI

    private var input: some View {
        ZStack(alignment: .topLeading) {
            TextField("Enter text to classify…", text: $inputText, axis: .vertical)
                .textFieldStyle(.plain)
                .focused($inputFocused)
                .font(.monoBody16)
                .disabled(isInputDisabled)
                .lineLimit(10)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .topLeading)
                .background(Asset.Colors.card.swiftUIColor)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            if inputText.isEmpty {
                Text("Enter text to classify…")
                    .font(.monoBody16)
                    .foregroundStyle(Asset.Colors.secondary.swiftUIColor)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .allowsHitTesting(false)
            }
        }
    }

    private var result: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(LocalizedStringKey(resultText))
                .font(.monoBody16Semibold)
                .textSelection(.enabled)

            if let stats = generationStats {
                Rectangle()
                    .fill(Asset.Colors.cardBorder.swiftUIColor)
                    .frame(height: 1)
                    .padding(.vertical, 4)

                VStack(alignment: .leading, spacing: 4) {
                    metricRow(
                        label: "Time to first token:",
                        value: String(format: "%.3f s", stats.timeToFirstToken)
                    )
                    if stats.tokensPerSecond > 0 {
                        metricRow(
                            label: "Tokens per second:",
                            value: String(format: "%.3f t/s", stats.tokensPerSecond)
                        )
                    }
                    metricRow(
                        label: "Total time:",
                        value: String(format: "%.3f s", stats.totalTime)
                    )
                }
            }
        }
        .padding(.leading, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var bottomBar: some View {
        HStack {
            Spacer()
            Button(action: {
                if case .generating = viewState {
                    stopClassification()
                } else {
                    runClassification()
                }
            }) {
                Text(actionButtonTitle)
                    .font(.monoHeading14Bold)
                    .foregroundStyle(buttonTextColor)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(buttonBackgroundColor)
                    .cornerRadius(12)
            }
            .disabled(isActionDisabled)
            Spacer()
        }
    }

    // MARK: - Logic – Helpers

    private var isActionDisabled: Bool {
        if case .generating = viewState {
            return false
        }
        return !isInputValid || isInputDisabled
    }

    private var isInputDisabled: Bool {
        switch viewState {
        case .loading, .generating, .error:
            return true
        case .idle:
            return false
        }
    }

    private var isInputValid: Bool {
        !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var actionButtonTitle: String {
        switch viewState {
        case .loading:
            return "Loading…"
        case .generating:
            return "STOP"
        case let .error(error):
            return "Error: \(error.localizedDescription)"
        case .idle:
            return "CLASSIFY"
        }
    }

    private var buttonTextColor: Color {
        if case .generating = viewState {
            return Asset.Colors.contrast.swiftUIColor
        }
        return isInputDisabled || !isInputValid
            ? Asset.Colors.secondary.swiftUIColor : Asset.Colors.contrast.swiftUIColor
    }

    private var buttonBackgroundColor: Color {
        if case .generating = viewState {
            return Asset.Colors.primary.swiftUIColor
        }
        return isInputDisabled || !isInputValid
            ? Asset.Colors.card.swiftUIColor : Asset.Colors.primary.swiftUIColor
    }

    private func stopClassification() {
        generationTask?.cancel()
    }

    private func runClassification() {
        guard case .idle = viewState, let session else { return }

        inputFocused = false
        audioController.pause()
        resultText = ""
        generationStats = nil

        let textToClassify = inputText.trimmingCharacters(in: .whitespacesAndNewlines)

        viewState = .generating

        let currentFeature = feature

        generationTask = Task.detached { [session, currentFeature, textToClassify] in

            let values = currentFeature.values.joined(separator: ", ")
            let prompt =
            "Text is: \"\(textToClassify)\". Choose \(currentFeature.name) from the list: \(values). Answer with one word. Dont't add dot at the end."

            let finalOutput = session.run(
                input: SessionInput.text(prompt),
                maxTokens: 32,
                progress: { _ in !Task.isCancelled }
            )

            guard !Task.isCancelled else {
                Task { @MainActor in
                    viewState = .idle
                }
                return
            }

            Task { @MainActor in
                resultText = finalOutput.text.trimmingCharacters(in: .whitespacesAndNewlines)
                generationStats = MessageStats(
                    timeToFirstToken: finalOutput.stats.prefillStats.duration,
                    tokensPerSecond: finalOutput.stats.generateStats?.tokensPerSecond ?? 0.0,
                    totalTime: finalOutput.stats.totalStats.duration
                )
                viewState = .idle
            }
        }
    }

    // MARK: - Metric row helper

    @ViewBuilder
    private func metricRow(label: String, value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Text(label)
                .font(.monoCaption12)
            Text(value)
                .font(.monoBody16)
        }
    }
}

#Preview {
    NavigationStack {
        ClassificationView(modelId: "Llama-3.2-3B-Instruct")
            .environment(UzuEngine(apiKey: APIKey.miraiSDK))
            .environment(Router())
            .environment(AudioController())
    }
}
