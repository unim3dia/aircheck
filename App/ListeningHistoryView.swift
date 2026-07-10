import AircheckCore
import SwiftUI

struct ListeningHistoryView: View {
    @Environment(AudioPlayer.self) private var player
    @Environment(CatalogStore.self) private var catalog
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                PaperBackground()
                if player.history.isEmpty {
                    ContentUnavailableView(
                        "Nothing on the log yet",
                        systemImage: "radio",
                        description: Text("Shows you play will collect here, with your place and listening time remembered.")
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(player.history) { entry in
                                if let show = catalog.show(id: entry.showID) {
                                    HistoryRow(show: show, entry: entry) {
                                        player.play(show, at: entry.lastPosition)
                                        dismiss()
                                    }
                                }
                            }
                        }
                        .padding(20)
                    }
                }
            }
            .navigationTitle("Listening log")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

private struct HistoryRow: View {
    let show: Show
    let entry: ListeningHistoryEntry
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .firstTextBaseline) {
                    Text(show.formattedDate)
                        .font(.system(.title3, design: .serif, weight: .semibold))
                    Spacer()
                    Text(entry.lastListenedAt, style: .relative)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                ProgressView(value: entry.completionFraction)
                    .tint(AircheckTheme.signal)

                HStack {
                    Label("\(Int(entry.completionFraction * 100))% reached", systemImage: "dial.medium")
                    Spacer()
                    Label(entry.secondsListened.timecode + " listened", systemImage: "headphones")
                }
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)

                Text("RESUME AT \(entry.lastPosition.timecode)")
                    .font(.caption.bold())
                    .tracking(1.2)
                    .foregroundStyle(AircheckTheme.signal)
            }
            .foregroundStyle(AircheckTheme.ink)
            .softCard(AircheckTheme.blue)
        }
        .buttonStyle(.plain)
        .accessibilityHint("Resumes this show from your last position")
    }
}
