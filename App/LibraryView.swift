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
                    Text("AIRCHECK 2006")
                        .font(.system(size: 34, weight: .black, design: .serif))
                        .tracking(-1.5)
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
            Text("WELCOME TO THE ARCHIVE")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .tracking(2.2)
                .foregroundStyle(AircheckTheme.ink.opacity(0.62))
                .padding(.top, 8)
            Image(uiImage: UIImage(named: "Howard1") ?? UIImage())
                .resizable()
                .scaledToFill()
                .frame(height: 190)
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(AircheckTheme.ink.opacity(0.16), lineWidth: 1)
                }
                .accessibilityLabel("Howard Stern at the microphone")
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

                RadioScale()
            }
        }
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(LinearGradient(
                    colors: [
                        Color(red: 0.65, green: 0.31, blue: 0.19),
                        Color(red: 0.78, green: 0.45, blue: 0.28),
                        Color(red: 0.56, green: 0.25, blue: 0.16)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .overlay {
                    RusticRadioTexture()
                        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(Color(red: 0.32, green: 0.14, blue: 0.09).opacity(0.64), lineWidth: 1.5)
                }
        }
        .shadow(color: AircheckTheme.ink.opacity(0.18), radius: 14, y: 8)
    }
}

private struct RusticRadioTexture: View {
    var body: some View {
        Canvas { context, size in
            for index in 0..<84 {
                let x = CGFloat((index * 47 + 19) % 101) / 100 * size.width
                let y = CGFloat((index * 31 + 7) % 97) / 96 * size.height
                let length = CGFloat(2 + (index * 13) % 13)
                var grain = Path()
                grain.move(to: CGPoint(x: x, y: y))
                grain.addLine(to: CGPoint(x: min(x + length, size.width), y: y + CGFloat((index % 3) - 1)))
                context.stroke(
                    grain,
                    with: .color(index.isMultiple(of: 4) ? .white.opacity(0.10) : AircheckTheme.ink.opacity(0.10)),
                    lineWidth: index.isMultiple(of: 5) ? 1.2 : 0.6
                )
            }

            for index in 0..<9 {
                let x = CGFloat(12 + (index * 41) % 88) / 100 * size.width
                let y = CGFloat(8 + (index * 23) % 82) / 100 * size.height
                var scratch = Path()
                scratch.move(to: CGPoint(x: x, y: y))
                scratch.addQuadCurve(
                    to: CGPoint(x: min(x + CGFloat(18 + index * 5), size.width), y: y + CGFloat(index % 2 == 0 ? 2 : -3)),
                    control: CGPoint(x: x + 9, y: y - 2)
                )
                context.stroke(scratch, with: .color(.white.opacity(0.16)), lineWidth: 0.8)
            }

            let wornAreas = [
                CGRect(x: -10, y: -7, width: 70, height: 28),
                CGRect(x: size.width - 50, y: size.height - 18, width: 66, height: 30),
                CGRect(x: size.width * 0.43, y: -10, width: 84, height: 22)
            ]
            for area in wornAreas {
                context.fill(Path(ellipseIn: area), with: .color(.white.opacity(0.07)))
            }
        }
        .accessibilityHidden(true)
    }
}

private struct DialKnob: View {
    let isActive: Bool
    @State private var rotation: Double = 0
    @State private var lastTouchAngle: Double?

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                ForEach(0..<12, id: \.self) { tick in
                    Capsule()
                        .fill(AircheckTheme.ink.opacity(tick.isMultiple(of: 3) ? 0.48 : 0.22))
                        .frame(width: tick.isMultiple(of: 3) ? 2 : 1, height: tick.isMultiple(of: 3) ? 8 : 5)
                        .offset(y: -35)
                        .rotationEffect(.degrees(Double(tick) * 30))
                }
                knobBody
                    .rotationEffect(.degrees(rotation))
            }
            .contentShape(Circle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let center = CGPoint(x: proxy.size.width / 2, y: proxy.size.height / 2)
                        let angle = atan2(value.location.y - center.y, value.location.x - center.x)
                        if let lastTouchAngle {
                            var delta = angle - lastTouchAngle
                            if delta > .pi { delta -= 2 * .pi }
                            if delta < -.pi { delta += 2 * .pi }
                            rotation += delta * 180 / .pi
                        }
                        lastTouchAngle = angle
                    }
                    .onEnded { _ in lastTouchAngle = nil }
            )
        }
        .frame(width: 72, height: 72)
        .accessibilityLabel("Decorative tuning knob")
        .accessibilityHint("Drag around the knob to spin it")
    }

    private var knobBody: some View {
        ZStack {
            Circle()
                .fill(Color(red: 0.22, green: 0.20, blue: 0.17))
                .frame(width: 64, height: 64)
                .overlay(Circle().stroke(Color.black.opacity(0.72), lineWidth: 2))
                .shadow(color: AircheckTheme.ink.opacity(0.42), radius: 4, y: 3)
            Circle()
                .fill(AngularGradient(
                    colors: [
                        Color(white: 0.83), Color(white: 0.37), Color(white: 0.68),
                        Color(white: 0.26), Color(white: 0.75), Color(white: 0.43), Color(white: 0.83)
                    ],
                    center: .center
                ))
                .frame(width: 57, height: 57)
                .overlay(Circle().stroke(.white.opacity(0.24), lineWidth: 1))
                .overlay(KnobPatina().clipShape(Circle()))
            Capsule()
                .fill(isActive ? Color(red: 0.38, green: 0.08, blue: 0.05) : Color.black.opacity(0.76))
                .frame(width: 3, height: 21)
                .offset(y: -10)
                .rotationEffect(.degrees(-28))
            Circle()
                .fill(RadialGradient(
                    colors: [.white.opacity(0.36), Color(white: 0.36)],
                    center: .topLeading,
                    startRadius: 1,
                    endRadius: 10
                ))
                .frame(width: 15, height: 15)
                .overlay(Circle().stroke(Color.black.opacity(0.28), lineWidth: 0.7))
        }
    }
}

private struct KnobPatina: View {
    var body: some View {
        Canvas { context, size in
            for index in 0..<32 {
                let angle = Double(index * 137 % 360) * .pi / 180
                let radius = CGFloat(7 + (index * 11) % 21)
                let center = CGPoint(
                    x: size.width / 2 + cos(angle) * radius,
                    y: size.height / 2 + sin(angle) * radius
                )
                let diameter = CGFloat(index.isMultiple(of: 6) ? 4 : 1.5)
                let mark = CGRect(x: center.x - diameter / 2, y: center.y - diameter / 2, width: diameter, height: diameter)
                context.fill(
                    Path(ellipseIn: mark),
                    with: .color(index.isMultiple(of: 4) ? .black.opacity(0.24) : .white.opacity(0.22))
                )
            }

            for index in 0..<7 {
                let y = CGFloat(8 + index * 7)
                var scrape = Path()
                scrape.move(to: CGPoint(x: CGFloat(5 + index * 3), y: y))
                scrape.addLine(to: CGPoint(x: CGFloat(27 + index * 2), y: y - 2))
                context.stroke(scrape, with: .color(.white.opacity(0.22)), lineWidth: 0.7)
            }
        }
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
                Text("00")
            }
            .font(.system(size: 8, weight: .bold, design: .monospaced))
            .foregroundStyle(AircheckTheme.ink.opacity(0.55))
        }
        .accessibilityHidden(true)
    }
}

private struct TranscriptionDesk: View {
    let snapshot: ArchiveProgress

    var body: some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack(alignment: .firstTextBaseline) {
                Text("TRANSCRIPTION DESK")
                    .font(.caption.bold())
                    .tracking(1.7)
                Spacer()
                Text("LOCAL INDEX")
                    .font(.caption2.bold())
                    .tracking(1.1)
                    .foregroundStyle(.secondary)
            }

            HStack(alignment: .lastTextBaseline, spacing: 6) {
                Text("\(snapshot.completedShows)")
                    .font(.system(size: 42, weight: .bold, design: .serif))
                Text("/ \(snapshot.totalShows) SHOWS")
                    .font(.caption.bold())
                    .tracking(1.2)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(Int(snapshot.completionFraction * 100))%")
                    .font(.system(.headline, design: .monospaced, weight: .semibold))
                    .foregroundStyle(AircheckTheme.signal)
            }

            ProgressView(value: snapshot.completionFraction)
                .tint(AircheckTheme.signal)

            HStack(alignment: .top, spacing: 16) {
                deskDetail(label: "LAST COMPLETE", value: snapshot.latestCompletedShowID ?? "—")
                Spacer()
                if let activeShowID = snapshot.activeShowID {
                    deskDetail(
                        label: "IN THE BOOTH",
                        value: "\(activeShowID) · \(snapshot.activeChunksCompleted)/\(snapshot.activeTotalChunks) chunks"
                    )
                } else {
                    deskDetail(label: "NEXT RUN", value: "Waiting for worker")
                }
            }

            Text("Refreshes when the Mac exports a new archive snapshot.")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .foregroundStyle(AircheckTheme.ink)
        .softCard(AircheckTheme.blue)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilitySummary)
    }

    private var accessibilitySummary: String {
        var summary = "Transcription progress: \(snapshot.completedShows) of \(snapshot.totalShows) shows complete"
        if let activeShowID = snapshot.activeShowID {
            summary += ". \(activeShowID) is transcribing, chunk \(snapshot.activeChunksCompleted) of \(snapshot.activeTotalChunks)."
        }
        return summary
    }

    private func deskDetail(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label).font(.caption2.bold()).tracking(1.1).foregroundStyle(AircheckTheme.signal)
            Text(value).font(.caption.monospacedDigit()).foregroundStyle(.secondary)
        }
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
