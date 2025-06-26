import AVFoundation
import SFSymbols
import SwiftUI
import Uzu

#if os(macOS)
    import AppKit
#endif

struct HomeView: View {
    // MARK: - Type Definitions
    private struct Feature: Identifiable {
        let id = UUID()
        let icon: SFSymbol
        let title: String
        let destination: Router.Destination?

        var isComingSoon: Bool { destination == nil }
    }

    // MARK: - Environment
    @Environment(Router.self) private var router
    @Environment(AudioController.self) private var audioController

    // MARK: - Stored Properties
    private var features: [Feature] {
        [
            Feature(
                icon: .bubbleLeftAndBubbleRight,
                title: "General Chat",
                destination: .modelSelection(next: .chat)
            ),
            Feature(
                icon: .circleRighthalfFilled,
                title: "Classification",
                destination: .modelSelection(next: .classification)
            ),
            Feature(
                icon: .docText,
                title: "Summarisation",
                destination: .modelSelection(next: .summarization)
            ),
            // Disabled features – coming soon
            Feature(
                icon: .camera,
                title: "Camera",
                destination: nil
            ),
            Feature(
                icon: .mic,
                title: "Voice",
                destination: nil
            ),
        ]
    }

    init() {}

    var body: some View {
        VStack(spacing: 0) {
            header
            featureList
            Spacer()
            exploreModels
            footer
                .padding(.bottom, 20)
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
        .onAppear {
            if audioController.player == nil,
                let asset = AVURLAsset(Asset.aboutUsPodcast.data)
            {
                audioController.setAsset(asset)
            }
        }
    }

    // MARK: - UI

    // Header
    private var header: some View {
        VStack(spacing: 0) {
            VStack(spacing: 8) {
                Text("Choose AI Usecase")
                    .font(.monoBody16Semibold)
                    .textCase(.uppercase)
                    .foregroundColor(Asset.Colors.primary.swiftUIColor)

                Text("to see Mirai on-device possibilities")
                    .font(.monoCaption12)
                    .foregroundColor(Asset.Colors.secondary.swiftUIColor)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.vertical, 28)
    }

    // Feature List
    private var featureList: some View {
        LazyVStack(spacing: 16) {
            ForEach(features) { feature in
                featureRow(feature)
            }
        }
        .padding(.horizontal, 20)
    }

    @ViewBuilder
    private func featureRow(_ feature: Feature) -> some View {
        Button(action: {
            if let dest = feature.destination {
                router.navigate(to: dest)
            }
        }) {
            HStack(spacing: 16) {
                Image(symbol: feature.icon)
                    .font(.title20)
                    .foregroundStyle(
                        feature.isComingSoon
                            ? Asset.Colors.secondary.swiftUIColor
                            : Asset.Colors.primary.swiftUIColor)

                Text(feature.title)
                    .font(.monoHeading14)
                    .foregroundStyle(Asset.Colors.primary.swiftUIColor)

                Spacer()

                if feature.isComingSoon {
                    Text("COMING SOON")
                        .font(.monoCaption12Semibold)
                        .foregroundStyle(Asset.Colors.secondary.swiftUIColor)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity)
            .background(Asset.Colors.card.swiftUIColor)
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
        .disabled(feature.isComingSoon)
    }

    // Explore Models CTA
    private var exploreModels: some View {
        Button(action: {
            router.navigate(to: .modelManagement)
        }) {
            VStack(spacing: 8) {
                Image(symbol: .chevronLeftChevronRight)
                    .font(.caption12Semibold)
                    .foregroundStyle(Asset.Colors.primary.swiftUIColor)

                Text("Explore our available models")
                    .font(.monoCaption12)
                    .foregroundStyle(Asset.Colors.primary.swiftUIColor)
                    .padding(.bottom)
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(Asset.Colors.primary.swiftUIColor.opacity(0.05))
            }
        }
        .buttonStyle(.plain)
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity)
    }

    // Footer Links
    private var footer: some View {
        HStack(alignment: .center) {
            if audioController.player != nil {
                ourVisionButton
                Spacer()
            }
            aboutButton
            Spacer()
            footerLink(
                title: "Contact us",
                icon: .heartFill,
                url: "mailto:dima@getmirai.co,alexey@getmirai.co?subject=Interested%20in%20Mirai")
        }
        .padding(.horizontal, 20)
    }

    @ViewBuilder
    private var ourVisionButton: some View {
        if audioController.player != nil {
            Button(action: {
                audioController.toggle()
            }) {
                VStack(alignment: .center, spacing: 8) {
                    Image(symbol: audioController.isPlaying ? .pauseFill : .playFill)
                        .font(.caption12)
                        .foregroundStyle(Asset.Colors.primary.swiftUIColor)
                    Text("Our vision")
                        .font(.monoCaption12)
                        .foregroundStyle(Asset.Colors.primary.swiftUIColor)
                }
            }
            .padding(.horizontal)
            .buttonStyle(.plain)
        }
    }

    private var aboutButton: some View {
        Button(action: {
            router.navigate(to: .about)
        }) {
            VStack(alignment: .center, spacing: 8) {
                Image(symbol: .infoCircleFill)
                    .font(.caption12)
                    .foregroundStyle(Asset.Colors.primary.swiftUIColor)
                Text("About us")
                    .font(.monoCaption12)
                    .foregroundStyle(Asset.Colors.primary.swiftUIColor)
            }
        }
        .padding(.horizontal)
        .buttonStyle(.plain)
    }

    private func footerLink(title: String, icon: SFSymbol, url: String) -> some View {
        Button(action: {
            if let link = URL(string: url) {
                #if os(iOS)
                    UIApplication.shared.open(link)
                #else
                    NSWorkspace.shared.open(link)
                #endif
            }
        }) {
            VStack(alignment: .center, spacing: 8) {
                Image(symbol: icon)
                    .font(.caption12)
                    .foregroundStyle(Asset.Colors.primary.swiftUIColor)
                Text(title)
                    .font(.monoCaption12)
                    .foregroundStyle(Asset.Colors.primary.swiftUIColor)
            }
        }
        .padding(.horizontal)
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        HomeView()
            .environment(UzuEngine(apiKey: APIKey.mirai))
            .environment(Router())
            .environment(AudioController())
    }
}
