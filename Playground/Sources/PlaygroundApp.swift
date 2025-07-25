import Observation
import SwiftUI
import Uzu

@main
struct PlaygroundApp: App {
    @State private var engine: UzuEngine
    @State private var router: Router

    @State private var audioController: AudioController

    init() {
        let engine = UzuEngine()
        self.engine = engine
        self.router = Router()

        self.audioController = AudioController()
    }

    var body: some Scene {
        WindowGroup {
            NavigationStack(path: $router.navPath) {
                HomeView()
                    .navigationDestination(for: Router.Destination.self) { destination in
                        switch destination {
                        case let .modelSelection(next):
                            ModelListView(mode: .choose(next: next))
                        case let .chat(modelId):
                            ChatView(modelId: modelId)
                        case let .classification(modelId):
                            ClassificationView(modelId: modelId)
                        case let .summarization(modelId):
                            SummarizationView(modelId: modelId)
                        case .about:
                            AboutView()
                        case .modelManagement:
                            ModelListView(mode: .manage)
                        }
                    }
            }
            .environment(engine)
            .environment(router)
            .environment(audioController)
            .tint(Asset.Colors.primary.swiftUIColor)
            .task {
                // Activate license before interacting with models.
                let _ = try? await engine.activate(apiKey: APIKey.miraiSDK)
                let _ = try? await engine.updateRegistry()
            }
        }
    }
}
