import SwiftUI

@main
struct AircheckApp: App {
    @State private var catalog = CatalogStore()
    @State private var player = AudioPlayer()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(catalog)
                .environment(player)
                .preferredColorScheme(.light)
                .task { await catalog.load() }
        }
    }
}
