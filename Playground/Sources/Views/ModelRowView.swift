import SFSymbols
import SwiftUI
import Uzu

struct ModelRowView: View {

    // MARK: - Stored Properties
    let modelId: String
    let isSelected: Bool

    // MARK: - Environment
    @Environment(UzuEngine.self) private var engine

    // MARK: - State
    private var state: ModelState {
        engine.states[modelId] ?? .notDownloaded
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 16) {
                statusIcon

                VStack(alignment: .leading, spacing: 4) {
                    Text(modelNameOnly)
                        .font(.monoHeading14)
                        .foregroundColor(Asset.Colors.primary.swiftUIColor)

                    HStack(spacing: 4) {
                        if let vendor = vendor {
                            badge(text: vendor)
                        }
                        if let precision = precision {
                            badge(text: precision)
                        }
                    }
                }

                Spacer()

                statusText
            }

            if case .downloading(let rawProgress) = state {
                let progress = min(max(rawProgress, 0.0), 1.0)
                ProgressView(value: progress)
                    .progressViewStyle(
                        LinearProgressViewStyle(tint: Asset.Colors.primary.swiftUIColor)
                    )
                    .frame(height: 4)
                    .frame(maxWidth: .infinity)
                    .clipShape(Capsule())
            } else if case .paused(let rawProgress) = state {
                let progress = min(max(rawProgress, 0.0), 1.0)
                ProgressView(value: progress)
                    .progressViewStyle(
                        LinearProgressViewStyle(tint: Asset.Colors.primary.swiftUIColor)
                    )
                    .frame(height: 4)
                    .frame(maxWidth: .infinity)
                    .clipShape(Capsule())
            }
        }
        .padding(16)
        .background(Asset.Colors.card.swiftUIColor)
        .cornerRadius(12)
    }

    @ViewBuilder
    private var statusIcon: some View {
        Image(symbol: isSelected ? .checkmarkCircleFill : .circle)
            .font(.title24Light)
            .foregroundColor(Asset.Colors.primary.swiftUIColor)
    }

    @ViewBuilder
    private var statusText: some View {
        let statusFont = Font.monoHeading14
        switch state {
        case .notDownloaded:
            Text("not installed")
                .font(statusFont)
                .foregroundColor(Asset.Colors.secondary.swiftUIColor)
        case .downloading:
            Text("installing...")
                .font(statusFont)
                .foregroundColor(Asset.Colors.secondary.swiftUIColor)
        case .downloaded:
            Text("installed")
                .font(statusFont)
                .foregroundColor(Asset.Colors.secondary.swiftUIColor)
        case .paused:
            Text("paused")
                .font(statusFont)
                .foregroundColor(Asset.Colors.secondary.swiftUIColor)
        case .error:
            Text("error")
                .font(statusFont)
                .foregroundColor(.red)
        }
    }

    // MARK: - Logic – Metadata helpers

    private var vendor: String? {
        if let meta = engine.info[modelId] {
            return meta.vendor
        }
        return fallbackComponents.first
    }

    private var precision: String? {
        if let meta = engine.info[modelId] {
            return meta.precision
        }
        return fallbackComponents.last
    }

    private var modelNameOnly: String {
        if let meta = engine.info[modelId] {
            return meta.name
        }
        let comps = fallbackComponents
        guard comps.count >= 3 else { return modelId }
        return comps.dropFirst().dropLast().joined(separator: "-")
    }

    private var fallbackComponents: [String] {
        modelId.split(separator: "-").map(String.init)
    }

    // MARK: - Badge helper

    @ViewBuilder
    private func badge(text: String) -> some View {
        Text(text)
            .font(.monoBadge10Semibold)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Asset.Colors.cardBorder.swiftUIColor)
            .foregroundColor(Asset.Colors.secondary.swiftUIColor)
            .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
    }
}

// MARK: - Previews

@preconcurrency @MainActor private func previewRow(
    state: ModelState,
    isSelected: Bool = false
) -> some View {
    let engine = UzuEngine(apiKey: APIKey.mirai)
    let modelId = "Llama-3.2-3B-Instruct-FP16"
    engine.states[modelId] = state
    let comps = modelId.split(separator: "-")
    let vendor = String(comps.first ?? "")
    let precision = String(comps.last ?? "")
    let name = comps.dropFirst().dropLast().joined(separator: "-")
    engine.info[modelId] = (vendor: vendor, name: name, precision: precision)
    return ModelRowView(
        modelId: modelId,
        isSelected: isSelected
    )
    .environment(engine)
    .padding()
    .previewLayout(.sizeThatFits)
}

#Preview("Not Downloaded") {
    previewRow(state: .notDownloaded)
}

#Preview("Downloading 42%") {
    previewRow(state: .downloading(progress: 0.42))
}

#Preview("Downloaded (Selected)") {
    previewRow(state: .downloaded, isSelected: true)
}

#Preview("Paused 42%") {
    previewRow(state: .paused(progress: 0.42))
}

#Preview("Error") {
    previewRow(state: .error(message: "Failed"))
}
