import SwiftUI

@main
struct AircheckApp: App {
    @State private var catalog = CatalogStore()
    @State private var player = AudioPlayer()
    @State private var progress = ProgressStore()
    @AppStorage("aircheck.appearance") private var appearance = "light"

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(catalog)
                .environment(player)
                .environment(progress)
                .preferredColorScheme(appearance == "dark" ? .dark : .light)
                .task { await catalog.load() }
        }
    }
}
