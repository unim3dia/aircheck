import AircheckCore
import SwiftUI

struct LibraryView: View {
    @Environment(CatalogStore.self) private var catalog
    @Environment(AudioPlayer.self) private var player
    @Binding var path: [Show]
    @State private var selectedMonth = 1
    @State private var showsSearch = false
    @State private var showsHistory = false

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
        .sheet(isPresented: $showsHistory) { ListeningHistoryView() }
    }

    private var masthead: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 0) {
                    Text("AIRHCHECK")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .tracking(4)
                    Text("’06")
                        .font(.system(size: 76, weight: .black, design: .serif))
                        .tracking(-6)
                }
                Spacer()
                Button { showsHistory = true } label: {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.title3.weight(.semibold))
                        .frame(width: 48, height: 48)
                        .background(.white.opacity(0.7), in: Circle())
                }
                .accessibilityLabel("Listening history")
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
        Button { player.toggle() } label: {
            TunedDialCard(show: show, isPlaying: player.isPlaying)
            .foregroundStyle(AircheckTheme.ink)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Tuned to \(show.formattedDate)")
        .accessibilityHint(player.isPlaying ? "Pause playback" : "Start playback")
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

private struct TunedDialCard: View {
    let show: Show
    let isPlaying: Bool

    var body: some View {
        HStack(spacing: 15) {
            DialKnob(isActive: isPlaying)

            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 7) {
                    Text("TUNED IN")
                    Circle().fill(AircheckTheme.signal).frame(width: 5, height: 5)
                    Text("2006 ARCHIVE")
                }
                .font(.caption2.bold())
                .tracking(1.15)
                .foregroundStyle(AircheckTheme.ink.opacity(0.68))

                HStack(alignment: .lastTextBaseline) {
                    Text(show.shortDate.uppercased())
                        .font(.system(size: 30, weight: .bold, design: .serif))
                    Spacer(minLength: 0)
                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                        .font(.subheadline.bold())
                        .frame(width: 34, height: 34)
                        .foregroundStyle(AircheckTheme.paper)
                        .background(AircheckTheme.ink, in: Circle())
                }

                Text("THE PERFECT STATION")
                    .font(.caption2.bold())
                    .tracking(1.2)
                    .foregroundStyle(AircheckTheme.signal)

                RadioScale()
            }
        }
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(AircheckTheme.peach)
                .overlay {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(.white.opacity(0.42), lineWidth: 1)
                }
        }
        .shadow(color: AircheckTheme.ink.opacity(0.07), radius: 14, y: 7)
    }
}

private struct DialKnob: View {
    let isActive: Bool

    var body: some View {
        ZStack {
            ForEach(0..<12, id: \.self) { tick in
                Capsule()
                    .fill(AircheckTheme.ink.opacity(tick.isMultiple(of: 3) ? 0.48 : 0.22))
                    .frame(width: tick.isMultiple(of: 3) ? 2 : 1, height: tick.isMultiple(of: 3) ? 8 : 5)
                    .offset(y: -35)
                    .rotationEffect(.degrees(Double(tick) * 30))
            }
            Circle()
                .fill(LinearGradient(
                    colors: [Color(white: 0.94), Color(white: 0.59), Color(white: 0.82)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .overlay(Circle().stroke(AircheckTheme.ink.opacity(0.33), lineWidth: 1))
                .shadow(color: AircheckTheme.ink.opacity(0.18), radius: 3, y: 2)
            Capsule()
                .fill(isActive ? AircheckTheme.signal : AircheckTheme.ink)
                .frame(width: 3, height: 21)
                .offset(y: -10)
                .rotationEffect(.degrees(-28))
            Circle().fill(Color.white.opacity(0.32)).frame(width: 15, height: 15)
        }
        .frame(width: 72, height: 72)
        .accessibilityHidden(true)
    }
}

private struct RadioScale: View {
    var body: some View {
        VStack(spacing: 3) {
            GeometryReader { proxy in
                let needleX = proxy.size.width * 0.62
                ZStack(alignment: .leading) {
                    Capsule().fill(AircheckTheme.ink.opacity(0.34)).frame(height: 1)
                    HStack(spacing: 0) {
                        ForEach(0..<17, id: \.self) { tick in
                            Rectangle()
                                .fill(AircheckTheme.ink.opacity(tick.isMultiple(of: 4) ? 0.48 : 0.22))
                                .frame(width: 1, height: tick.isMultiple(of: 4) ? 8 : 4)
                            if tick < 16 { Spacer(minLength: 0) }
                        }
                    }
                    Rectangle()
                        .fill(AircheckTheme.signal)
                        .frame(width: 2, height: 20)
                        .position(x: needleX, y: 7)
                }
            }
            .frame(height: 15)
            HStack {
                Text("88")
                Spacer()
                Text("92")
                Spacer()
                Text("96")
                Spacer()
                Text("100")
            }
            .font(.system(size: 8, weight: .bold, design: .monospaced))
            .foregroundStyle(AircheckTheme.ink.opacity(0.55))
        }
        .accessibilityHidden(true)
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
                HStack {
                    Text(show.durationText)
                    if show.topics.isEmpty { Text("·"); Text("Index pending") }
                }
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
