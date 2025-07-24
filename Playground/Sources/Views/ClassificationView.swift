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

    // ViewState comes from ClassificationModel.ViewState

    // MARK: - Environment

    @Environment(Router.self) private var router
    @Environment(UzuEngine.self) private var engine
    @Environment(AudioController.self) private var audioController
    @State private var viewModel: ClassificationModel

    // MARK: - State

    @FocusState private var inputFocused: Bool

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
                        if !viewModel.resultText.isEmpty {
                            result
                        }

                        Color.clear
                            .frame(height: 1)
                            .id("bottom")
                    }
                    .padding()
                }
                .onChange(of: viewModel.resultText) { _, _ in
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
            await viewModel.loadSession(using: engine)
        }
        .onDisappear {
            viewModel.tearDown()
        }
    }

    // MARK: - UI

    private var input: some View {
        ZStack(alignment: .topLeading) {
            TextField("Enter text to classify…", text: $viewModel.inputText, axis: .vertical)
                .textFieldStyle(.plain)
                .focused($inputFocused)
                .font(.monoBody16)
                .disabled(isInputDisabled)
                .lineLimit(10)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .topLeading)
                .background(Asset.Colors.card.swiftUIColor)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            if viewModel.inputText.isEmpty {
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
            Text(LocalizedStringKey(viewModel.resultText))
                .font(.monoBody16Semibold)
                .textSelection(.enabled)

            if let stats = viewModel.stats {
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
                if case .generating = viewModel.viewState {
                    viewModel.stop()
                } else {
                    viewModel.classify()
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
        if case .generating = viewModel.viewState {
            return false
        }
        return !isInputValid || isInputDisabled
    }

    private var isInputDisabled: Bool {
        switch viewModel.viewState {
        case .loading, .generating, .error:
            return true
        case .idle:
            return false
        }
    }

    private var isInputValid: Bool {
        !viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var actionButtonTitle: String {
        switch viewModel.viewState {
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
        if case .generating = viewModel.viewState {
            return Asset.Colors.contrast.swiftUIColor
        }
        return isInputDisabled || !isInputValid
            ? Asset.Colors.secondary.swiftUIColor : Asset.Colors.contrast.swiftUIColor
    }

    private var buttonBackgroundColor: Color {
        if case .generating = viewModel.viewState {
            return Asset.Colors.primary.swiftUIColor
        }
        return isInputDisabled || !isInputValid
            ? Asset.Colors.card.swiftUIColor : Asset.Colors.primary.swiftUIColor
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

    init(modelId: String) {
        self.modelId = modelId
        let feat = SessionClassificationFeature(name: "sentiment", values: Self.sentiments)
        _viewModel = State(initialValue: ClassificationModel(modelId: modelId, feature: feat))
        viewModel.inputText = Self.textsToClassify.randomElement()!
    }
}

#Preview {
    NavigationStack {
        ClassificationView(modelId: "Llama-3.2-3B-Instruct")
            .environment(UzuEngine())
            .environment(Router())
            .environment(AudioController())
    }
}
