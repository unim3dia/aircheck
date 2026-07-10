import AircheckCore
import SwiftUI

struct SearchView: View {
    @Environment(CatalogStore.self) private var catalog
    @Environment(AudioPlayer.self) private var player
    @Environment(\.dismiss) private var dismiss
    @Binding var path: [Show]
    @State private var query = ""

    private var hits: [SearchHit] { CatalogSearch.search(query: query, shows: catalog.shows) }
    private var dateMatches: [Show] {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else { return [] }
        return catalog.shows.filter { $0.formattedDate.localizedCaseInsensitiveContains(query) || $0.shortDate.localizedCaseInsensitiveContains(query) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                PaperBackground()
                List {
                    if query.isEmpty {
                        Section { Text("Search a person, phrase, team, or broadcast date. Every result becomes an audio jump point as transcripts finish processing.").foregroundStyle(.secondary) }
                    }
                    if !dateMatches.isEmpty {
                        Section("Broadcasts") { ForEach(dateMatches) { show in Button(show.formattedDate) { open(show) } } }
                    }
                    if !hits.isEmpty {
                        Section("Inside the shows") {
                            ForEach(hits) { hit in
                                Button {
                                    guard let show = catalog.show(id: hit.showID) else { return }
                                    player.play(show, at: hit.time); dismiss()
                                } label: {
                                    VStack(alignment: .leading, spacing: 5) {
                                        HStack { Text(hit.title).font(.headline); Spacer(); Text(hit.time.timecode).font(.caption.monospacedDigit()) }
                                        Text(hit.excerpt).font(.subheadline).foregroundStyle(.secondary).lineLimit(3)
                                    }
                                }
                            }
                        }
                    } else if !query.isEmpty && dateMatches.isEmpty {
                        ContentUnavailableView.search(text: query)
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Search the year")
            .searchable(text: $query, prompt: "Rosie O’Donnell, Knicks, a phrase…")
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }
    }

    private func open(_ show: Show) { dismiss(); path.append(show) }
}
