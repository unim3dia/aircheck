import SwiftUI

@main
struct AircheckApp: App {
    @State private var catalog = CatalogStore()
    @State private var player = AudioPlayer()
    @State private var progress = ProgressStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(catalog)
                .environment(player)
                .environment(progress)
                .preferredColorScheme(.light)
                .task { await catalog.load() }
        }
    }
}
