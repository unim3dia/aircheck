import AircheckCore
import SwiftUI

struct LibraryView: View {
    @Environment(CatalogStore.self) private var catalog
    @Environment(AudioPlayer.self) private var player
    @Binding var path: [Show]
    @State private var selectedMonth = 1
    @State private var showsSearch = false

    var body: some View {
        ZStack {
            PaperBackground()
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 24) {
                    masthead
                    if let current = player.currentShow { continueCard(current) }
                    monthRail
                    showList
                    sourceNote
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showsSearch) { SearchView(path: $path) }
    }

    private var masthead: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 0) {
                    Text("AIRCHECK")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .tracking(4)
                    Text("’06")
                        .font(.system(size: 76, weight: .black, design: .serif))
                        .tracking(-6)
                }
                Spacer()
                Button { showsSearch = true } label: {
                    Image(systemName: "text.magnifyingglass")
                        .font(.title3.weight(.semibold))
                        .frame(width: 48, height: 48)
                        .background(.white.opacity(0.7), in: Circle())
                }
                .accessibilityLabel("Search the archive")
            }
            Text("THE FIRST SATELLITE YEAR")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .tracking(2.2)
                .foregroundStyle(AircheckTheme.signal)
            Text("A year of radio, remapped as stories.")
                .font(.system(size: 24, weight: .medium, design: .serif))
                .padding(.top, 8)
        }
        .padding(.top, 12)
    }

    private func continueCard(_ show: Show) -> some View {
        Button { player.showsFullPlayer = true } label: {
            HStack(spacing: 16) {
                SignalGlyph(isActive: player.isPlaying)
                VStack(alignment: .leading, spacing: 4) {
                    Text("ON YOUR DIAL").font(.caption.bold()).tracking(1.6)
                    Text(show.shortDate).font(.system(.title2, design: .serif, weight: .semibold))
                    ProgressView(value: player.progress(for: show)).tint(AircheckTheme.ink)
                }
                Spacer()
                Image(systemName: "arrow.up.right").font(.headline)
            }
            .foregroundStyle(AircheckTheme.ink)
            .softCard(AircheckTheme.peach)
        }
        .buttonStyle(.plain)
    }

    private var monthRail: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("2006 / SELECT A MONTH").font(.caption.bold()).tracking(1.5)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(1...12, id: \.self) { month in
                        Button { withAnimation(.snappy) { selectedMonth = month } } label: {
                            Text(monthName(month))
                                .font(.subheadline.weight(.semibold))
                                .padding(.horizontal, 16).padding(.vertical, 10)
                                .foregroundStyle(selectedMonth == month ? AircheckTheme.paper : AircheckTheme.ink)
                                .background(selectedMonth == month ? AircheckTheme.ink : .white.opacity(0.52), in: Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    @ViewBuilder private var showList: some View {
        if catalog.isLoading && catalog.shows.isEmpty {
            HStack { Spacer(); ProgressView("Tuning the archive…"); Spacer() }.padding(.vertical, 60)
        } else if let error = catalog.errorMessage, catalog.shows.isEmpty {
            ContentUnavailableView("Signal lost", systemImage: "antenna.radiowaves.left.and.right.slash", description: Text(error))
        } else {
            LazyVStack(spacing: 10) {
                ForEach(catalog.shows(in: selectedMonth)) { show in
                    Button { path.append(show) } label: { ShowRow(show: show) }
                        .buttonStyle(.plain)
                }
            }
        }
    }

    private var sourceNote: some View {
        Text("STREAMED FROM A USER-CONFIGURED INTERNET ARCHIVE ITEM · RIGHTS STATUS NOT ASSERTED")
            .font(.system(size: 9, weight: .semibold, design: .rounded))
            .tracking(1.2).foregroundStyle(.secondary).padding(.vertical, 20)
    }

    private func monthName(_ month: Int) -> String {
        Calendar.current.monthSymbols[month - 1].prefix(3).uppercased()
    }
}

private struct ShowRow: View {
    @Environment(AudioPlayer.self) private var player
    let show: Show

    var body: some View {
        HStack(spacing: 16) {
            VStack(spacing: -4) {
                Text(show.dayNumber).font(.system(size: 38, weight: .bold, design: .serif))
                Text(show.weekday).font(.caption2.bold()).tracking(1.5)
            }.frame(width: 62)
            Rectangle().fill(AircheckTheme.ink.opacity(0.16)).frame(width: 1, height: 54)
            VStack(alignment: .leading, spacing: 6) {
                Text(show.displayTitle).font(.headline)
                HStack { Text(show.durationText); Text("·"); Text(show.topics.isEmpty ? "Index pending" : "\(show.topics.count) stories") }
                    .font(.caption).foregroundStyle(.secondary)
                if player.progress(for: show) > 0 { ProgressView(value: player.progress(for: show)).tint(AircheckTheme.signal) }
            }
            Spacer()
            Image(systemName: "chevron.right").font(.caption.bold()).foregroundStyle(.secondary)
        }
        .foregroundStyle(AircheckTheme.ink)
        .padding(14)
        .background(.white.opacity(0.55), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}
