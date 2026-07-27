import AircheckCore
import SwiftUI

struct RootView: View {
    @Environment(CatalogStore.self) private var catalog
    @Environment(AudioPlayer.self) private var player
    @State private var path: [Show] = []
    @AppStorage("aircheck.appearance") private var appearance = "light"

    var body: some View {
        NavigationStack(path: $path) {
            LibraryView(path: $path)
                .navigationDestination(for: Show.self) { ShowDetailView(show: $0) }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if player.currentShow != nil { MiniPlayer(path: $path) }
        }
        .sheet(isPresented: Bindable(player).showsFullPlayer) { FullPlayerView() }
        .tint(AircheckTheme.signal)
        .overlay(alignment: .topTrailing) {
            Button { appearance = appearance == "dark" ? "light" : "dark" } label: {
                Image(systemName: appearance == "dark" ? "sun.max.fill" : "moon.fill")
                    .font(.headline.weight(.semibold))
                    .frame(width: 40, height: 40)
                    .background(AircheckTheme.paper.opacity(0.9), in: Circle())
                    .shadow(color: AircheckTheme.ink.opacity(0.12), radius: 5, y: 2)
            }
            .accessibilityLabel(appearance == "dark" ? "Switch to light mode" : "Switch to dark mode")
            .padding(.top, 10)
            .padding(.trailing, 14)
        }
        .onChange(of: catalog.shows) { _, shows in player.restoreLastShow(from: shows) }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)) { _ in
            player.persistHistory()
        }
    }
}
