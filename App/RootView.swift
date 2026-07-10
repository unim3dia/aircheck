import AircheckCore
import SwiftUI

struct RootView: View {
    @Environment(CatalogStore.self) private var catalog
    @Environment(AudioPlayer.self) private var player
    @State private var path: [Show] = []

    var body: some View {
        NavigationStack(path: $path) {
            LibraryView(path: $path)
                .navigationDestination(for: Show.self) { ShowDetailView(show: $0) }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if player.currentShow != nil { MiniPlayer() }
        }
        .sheet(isPresented: Bindable(player).showsFullPlayer) { FullPlayerView() }
        .tint(AircheckTheme.signal)
        .onChange(of: catalog.shows) { _, shows in player.restoreLastShow(from: shows) }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)) { _ in
            player.persistHistory()
        }
    }
}
