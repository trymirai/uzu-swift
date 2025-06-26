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
    @Environment(SessionRunner.self) private var sessionRunner
    @Environment(AudioController.self) private var audioController

    // MARK: - State – Session is managed globally via SessionRunner

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
        .onAppear {
            Task(priority: .userInitiated) {
                await sessionRunner.ensureLoaded(modelId: modelId, preset: .classification(feature))
            }
        }
        .onChange(of: sessionRunner.state) { _, newState in
            switch newState {
            case .ready:
                viewState = .idle
            case .error(let err):
                viewState = .error(err)
            default:
                viewState = .loading
            }
        }
        .onDisappear {
            generationTask?.cancel()
            generationTask = nil
            sessionRunner.destroy()
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
            Button(action: runClassification) {
                Text(actionButtonTitle)
                    .font(.monoHeading14Bold)
                    .foregroundStyle(buttonTextColor)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(buttonBackgroundColor)
                    .cornerRadius(12)
            }
            .disabled(!isInputValid || isInputDisabled)
            Spacer()
        }
    }

    // MARK: - Logic – Helpers

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
            return "Generating…"
        case let .error(error):
            return "Error: \(error.localizedDescription)"
        case .idle:
            return "CLASSIFY"
        }
    }

    private var buttonTextColor: Color {
        isInputDisabled || !isInputValid
            ? Asset.Colors.secondary.swiftUIColor : Asset.Colors.contrast.swiftUIColor
    }

    private var buttonBackgroundColor: Color {
        isInputDisabled || !isInputValid
            ? Asset.Colors.card.swiftUIColor : Asset.Colors.primary.swiftUIColor
    }

    private func runClassification() {
        guard case .idle = viewState, case .ready = sessionRunner.state else { return }

        inputFocused = false
        audioController.pause()
        resultText = ""
        generationStats = nil

        let textToClassify = inputText.trimmingCharacters(in: .whitespacesAndNewlines)

        viewState = .generating

        let currentFeature = feature

        generationTask = Task.detached { [weak sessionRunner] in
            guard let sessionRunner,
                case .ready = await sessionRunner.state
            else { return }

            let values = currentFeature.values.joined(separator: ", ")
            let prompt =
                "Text is: \"\(textToClassify)\". Choose \(currentFeature.name) from the list: \(values). Answer with one word. Dont't add dot at the end."

            guard
                let finalOutput = try? sessionRunner.run(
                    input: SessionInput.text(prompt),
                    maxTokens: 32,
                    progress: { _ in !Task.isCancelled }
                )
            else { return }

            guard !Task.isCancelled else { return }

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
