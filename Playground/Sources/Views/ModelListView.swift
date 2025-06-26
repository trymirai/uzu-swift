import Foundation
import Observation
import SFSymbols
import SwiftUI
import Uzu

#if canImport(UIKit)
    import UIKit
#endif

struct ModelListView: View {
    // MARK: - Type Definitions
    enum Mode {
        case choose(next: Router.ModelListDestination)
        case manage
    }

    // MARK: - Stored Properties
    let mode: Mode

    // MARK: - Environment
    @Environment(UzuEngine.self) var engine
    @Environment(Router.self) var router

    // MARK: - State
    @State var selectedModelId: String?
    @State private var selectedModelSection: ModelSection?

    var body: some View {
        VStack(spacing: 0) {
            header
            modelList
            Spacer()
            bottomBar
                .padding(20)
        }
        .background(Asset.Colors.background.swiftUIColor)
        #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            ToolbarItem(placement: .principal) {
                Image(asset: Asset.Icons.logo)
                    .padding(.top, 24)
                    .padding(.bottom, 38)
            }
        }
        .toolbarRole(.editor)
    }

    // MARK: - UI

    // Header
    private var header: some View {
        VStack(spacing: 0) {
            VStack(spacing: 8) {
                Text("Available AI Models")
                    .font(.monoBody16Semibold)
                    .textCase(.uppercase)
                    .foregroundColor(Asset.Colors.primary.swiftUIColor)

                Text("select 1 or multiple to install")
                    .font(.monoCaption12)
                    .foregroundColor(Asset.Colors.secondary.swiftUIColor)
            }
            .padding(.vertical, 28)
        }
    }

    // Model List
    private var modelList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    ForEach(sectionOrder, id: \.self) { section in
                        let models = models(for: section)
                        if !models.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text(section.title)
                                    .font(.monoCaption12Semibold)
                                    .foregroundColor(Asset.Colors.secondary.swiftUIColor)
                                    .textCase(.uppercase)
                                    .padding(.horizontal, 4)
                                ForEach(models, id: \.self) { modelId in
                                    ModelRowView(
                                        modelId: modelId, isSelected: selectedModelId == modelId
                                    )
                                    .id(modelId)
                                    .onTapGesture {
                                        select(modelId: modelId)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
            .onChange(of: engine.states) { _, _ in
                guard let selectedModelId,
                    let state = engine.states[selectedModelId]
                else { return }

                let newSection = section(for: state)

                if newSection != selectedModelSection {
                    selectedModelSection = newSection
                    withAnimation {
                        proxy.scrollTo(selectedModelId, anchor: .center)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var bottomBar: some View {
        switch mode {
        case .choose:
            chooseBottomBar
        case .manage:
            manageBottomBar
        }
    }

    @ViewBuilder
    private var chooseBottomBar: some View {
        if let state = selectedModelState {
            switch state {
            case .notDownloaded, .paused:
                downloadButton
            case .downloading:
                waitingText
            case .error:
                retryButton
            case .downloaded:
                chooseButton
            }
        } else {
            disabledChooseButton
        }
    }
    @ViewBuilder
    private var manageBottomBar: some View {
        if let state = selectedModelState {
            switch state {
            case .notDownloaded, .error:
                downloadButton
            case .downloading:
                pauseButton
            case .paused:
                resumeButton
            case .downloaded:
                deleteButton
            }
        } else {
            disabledManageButton
        }
    }

    // MARK: - Bottom bar buttons & texts

    private var disabledChooseButton: some View {
        Button(action: {}) {
            Text("CHOOSE")
                .font(.monoHeading14Bold)
                .foregroundColor(Asset.Colors.secondary.swiftUIColor)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(Asset.Colors.card.swiftUIColor)
                .cornerRadius(12)
        }
        .disabled(true)
    }

    private var disabledManageButton: some View {
        Button(action: {}) {
            Text("SELECT MODEL")
                .font(.monoHeading14Bold)
                .foregroundColor(Asset.Colors.secondary.swiftUIColor)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(Asset.Colors.card.swiftUIColor)
                .cornerRadius(12)
        }
        .disabled(true)
    }

    private var downloadButton: some View {
        Button(action: {
            downloadSelectedModel()
        }) {
            Text("DOWNLOAD")
                .font(.monoHeading14Bold)
                .foregroundColor(Asset.Colors.contrast.swiftUIColor)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(Asset.Colors.primary.swiftUIColor)
                .cornerRadius(12)
        }
    }

    private var retryButton: some View {
        Button(action: {
            downloadSelectedModel()
        }) {
            Text("RETRY DOWNLOAD")
                .font(.monoHeading14Bold)
                .foregroundColor(Asset.Colors.contrast.swiftUIColor)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(Asset.Colors.primary.swiftUIColor)
                .cornerRadius(12)
        }
    }

    private var chooseButton: some View {
        Button(action: {
            proceed()
        }) {
            Text("CHOOSE")
                .font(.monoHeading14Bold)
                .foregroundColor(Asset.Colors.contrast.swiftUIColor)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(Asset.Colors.primary.swiftUIColor)
                .cornerRadius(12)
        }
    }

    private var waitingText: some View {
        Text("Wait for the models to be installed...")
            .font(.monoHeading14Medium)
            .foregroundColor(Asset.Colors.secondary.swiftUIColor)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .multilineTextAlignment(.center)
    }

    private var deleteButton: some View {
        Button(action: {
            deleteSelectedModel()
        }) {
            Text("DELETE")
                .font(.monoHeading14Bold)
                .foregroundColor(Asset.Colors.contrast.swiftUIColor)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(Asset.Colors.primary.swiftUIColor)
                .cornerRadius(12)
        }
    }

    private var pauseButton: some View {
        Button(action: {
            pauseSelectedModel()
        }) {
            Text("PAUSE")
                .font(.monoHeading14Bold)
                .foregroundColor(Asset.Colors.contrast.swiftUIColor)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(Asset.Colors.primary.swiftUIColor)
                .cornerRadius(12)
        }
    }

    private var resumeButton: some View {
        Button(action: {
            resumeSelectedModel()
        }) {
            Text("RESUME")
                .font(.monoHeading14Bold)
                .foregroundColor(Asset.Colors.contrast.swiftUIColor)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(Asset.Colors.primary.swiftUIColor)
                .cornerRadius(12)
        }
    }

    // MARK: - Helpers
    private var selectedModelState: ModelState? {
        guard let selectedModelId else { return nil }
        return engine.states[selectedModelId]
    }

    private func select(modelId: String) {
        selectedModelId = modelId
        if let state = engine.states[modelId] {
            selectedModelSection = section(for: state)
        }
    }

    private func downloadSelectedModel() {
        guard let selectedModelId else { return }
        engine.download(identifier: selectedModelId)
    }

    private func deleteSelectedModel() {
        guard let selectedModelId else { return }
        engine.delete(identifier: selectedModelId)
    }

    private func proceed() {
        guard let selectedModelId else { return }
        guard case let .choose(next) = mode else { return }
        switch next {
        case .classification:
            router.navigate(to: .classification(modelId: selectedModelId))
        case .summarization:
            router.navigate(to: .summarization(modelId: selectedModelId))
        case .chat:
            router.navigate(to: .chat(modelId: selectedModelId))
        }
    }

    private func pauseSelectedModel() {
        guard let selectedModelId else { return }
        engine.pause(identifier: selectedModelId)
    }

    private func resumeSelectedModel() {
        guard let selectedModelId else { return }
        engine.resume(identifier: selectedModelId)
    }

    // MARK: - Section helpers

    private enum ModelSection: Int {
        case installed
        case installing
        case paused
        case notInstalled

        var title: String {
            switch self {
            case .installed: return "Installed"
            case .installing: return "Installing"
            case .paused: return "Paused"
            case .notInstalled: return "Not Installed"
            }
        }
    }

    private var sectionOrder: [ModelSection] {
        [.installed, .installing, .paused, .notInstalled]
    }

    private func models(for section: ModelSection) -> [String] {
        engine.states
            .filter { (_, state) in
                switch (section, state) {
                case (.installed, .downloaded): return true
                case (.installing, .downloading): return true
                case (.paused, .paused): return true
                case (.notInstalled, .notDownloaded): return true
                default: return false
                }
            }
            .map { $0.key }
            .sorted()
    }

    private func section(for state: ModelState) -> ModelSection {
        switch state {
        case .downloaded: return .installed
        case .downloading: return .installing
        case .paused: return .paused
        case .notDownloaded: return .notInstalled
        case .error: return .notInstalled
        }
    }
}

// MARK: - Previews
#Preview {
    let engine = UzuEngine(apiKey: APIKey.mirai)
    let models = [
        ("Llama-3.2-3B-Instruct-FP16", ModelState.downloaded),
        ("Llama-3.2-1B-Instruct-FP16", ModelState.downloading(progress: 0.32)),
        ("Llama-3.2-8B-Instruct-FP16", ModelState.paused(progress: 0.73)),
        ("Alibaba-Qwen3-4B-FP16", ModelState.notDownloaded),
    ]

    for (id, st) in models {
        engine.states[id] = st
        let comps = id.split(separator: "-")
        let vendor = String(comps.first ?? "")
        let precision = String(comps.last ?? "")
        let name = comps.dropFirst().dropLast().joined(separator: "-")
        engine.info[id] = (vendor: vendor, name: name, precision: precision)
    }

    return NavigationStack {
        ModelListView(mode: .choose(next: .chat))
            .environment(engine)
            .environment(Router())
    }
}
