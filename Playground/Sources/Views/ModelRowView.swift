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
    private var state: ModelDownloadState {
        engine.states[modelId] ?? .notDownloaded(totalBytes: 0)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
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
                        if let qlabel = quantizationLabel {
                            badge(text: qlabel)
                        }
                    }
                    .fixedSize()
                }
                
                Spacer()
                
                VStack(spacing: 8) {
                    statusText
                    if let bytes = bytesInfo {
                        Text(bytes)
                            .font(.monoCaption12)
                            .foregroundColor(Asset.Colors.secondary.swiftUIColor)
                    }
                }
            }
            
            switch state {
            case .downloading, .paused:
                let progress = min(max(state.progress, 0.0), 1.0)
                VStack(alignment: .leading, spacing: 4) {
                    ProgressView(value: progress)
                        .progressViewStyle(
                            LinearProgressViewStyle(tint: Asset.Colors.primary.swiftUIColor)
                        )
                        .frame(height: 4)
                        .frame(maxWidth: .infinity)
                        .clipShape(Capsule())
                }
            default: EmptyView()
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
        let raw: String? = {
            if let meta = engine.info[modelId] {
                return meta.precision
            }
            return fallbackComponents.last
        }()
        
        guard let value = raw?.lowercased(), !value.isEmpty else { return nil }
        
        switch value {
        case "float16":
            return "fp16"
        case "bfloat16":
            return "bf16"
        default:
            return raw
        }
    }
    
    private var quantizationLabel: String? {
        guard let raw = engine.info[modelId]?.quantization?.lowercased(), !raw.isEmpty else {
            return nil
        }
        
        switch raw {
        case "int4", "uint4":
            return "4-bit"
        case "int8", "uint8":
            return "8bit"
        default:
            return nil
        }
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
    
    // MARK: - Downloaded bytes info
    
    private var bytesInfo: String? {
        switch state {
        case .downloading(let downloaded, let total),
                .paused(let downloaded, let total):
            return "\(formatBytes(downloaded)) / \(formatBytes(total))"
        case .notDownloaded(let total):
            return formatBytes(total)
        default:
            return nil
        }
    }
    
    private func formatBytes(_ bytes: UInt64) -> String {
        let kb: Double = 1024
        let mb = kb * 1024
        let gb = mb * 1024
        
        let value = Double(bytes)
        
        if value >= gb {
            return String(format: "%.1f GB", value / gb)
        } else if value >= mb {
            return String(format: "%.1f MB", value / mb)
        } else if value >= kb {
            return String(format: "%.0f KB", value / kb)
        } else {
            return "\(bytes) B"
        }
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
