import AircheckCore
import SwiftUI

struct ShowDetailView: View {
    @Environment(AudioPlayer.self) private var player
    @Environment(CatalogStore.self) private var catalog
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    let show: Show
    @State private var mode = DetailMode.stories
    @State private var transcriptSegments: [TranscriptSegment] = []
    @State private var isLoadingTranscript = false

    private var isPad: Bool { UIDevice.current.userInterfaceIdiom == .pad }

    private var liveHeadline: String {
        guard player.currentShow?.id == show.id else { return show.topics.first?.title ?? show.displayTitle }
        return player.currentSectionTitle ?? show.topics.first?.title ?? show.displayTitle
    }

    private enum DetailMode: String, CaseIterable { case stories = "Stories", transcript = "Transcript" }

    var body: some View {
        ZStack {
            PaperBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    hero
                    Picker("View", selection: $mode) {
                        ForEach(DetailMode.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    if mode == .stories { stories } else { transcript }
                }
                .frame(maxWidth: 1_120, alignment: .leading)
                .padding(.horizontal, isPad ? 24 : 20)
                .padding(.bottom, 40)
                .frame(maxWidth: .infinity)
            }
        }
        .navigationTitle(show.shortDate)
        .navigationBarTitleDisplayMode(.inline)
        .task(id: mode) {
            guard mode == .transcript, transcriptSegments.isEmpty else { return }
            isLoadingTranscript = true
            transcriptSegments = catalog.database.transcript(showID: show.id)
            isLoadingTranscript = false
        }
    }

    @ViewBuilder private var hero: some View {
        if isPad {
            wideHero
        } else {
            compactHero
        }
    }

    private var compactHero: some View {
        ZStack(alignment: .leading) {
            Image(uiImage: UIImage(named: "Howard2") ?? UIImage())
                .resizable()
                .scaledToFill()
                .frame(height: 320)
                .frame(maxWidth: .infinity)
                .clipped()
                .overlay {
                    LinearGradient(colors: [AircheckTheme.paper.opacity(0.94), AircheckTheme.paper.opacity(0.72), .clear], startPoint: .leading, endPoint: .trailing)
                }
                .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
            VStack(alignment: .leading, spacing: 12) {
                Text(show.weekday).font(.caption.bold()).tracking(3).foregroundStyle(AircheckTheme.signal)
                Text(show.date.formatted(.dateTime.month(.wide).day()))
                    .font(.system(size: 48, weight: .bold, design: .serif)).tracking(-3)
                Text(liveHeadline).font(.title3.weight(.medium)).frame(maxWidth: 260, alignment: .leading)
                Text(show.durationText + "  ·  24 kbps archive stream").font(.subheadline).foregroundStyle(.secondary)
                Button { player.play(show) } label: {
                    Label(player.currentShow?.id == show.id && player.isPlaying ? "Playing" : "Hey Now", systemImage: "play.fill")
                        .font(.headline).frame(maxWidth: 260).padding(.vertical, 14)
                        .foregroundStyle(AircheckTheme.paper)
                        .background(AircheckTheme.ink, in: Capsule())
                }
            }
            .padding(22)
            .background(.ultraThinMaterial.opacity(0.42), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: .white.opacity(0.72), radius: 10)
            .foregroundStyle(AircheckTheme.ink)
        }
        .frame(height: 320)
        .padding(.top, 10)
    }

    private var wideHero: some View {
        ZStack(alignment: .leading) {
            Image(uiImage: UIImage(named: "Howard2") ?? UIImage())
                .resizable()
                .scaledToFill()
                .frame(height: 390)
                .frame(maxWidth: .infinity)
                .clipped()
                .overlay {
                    LinearGradient(
                        colors: [AircheckTheme.paper.opacity(0.98), AircheckTheme.paper.opacity(0.78), AircheckTheme.paper.opacity(0.18), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                }
                .clipShape(RoundedRectangle(cornerRadius: 34, style: .continuous))

            VStack(alignment: .leading, spacing: 14) {
                Text(show.weekday).font(.caption.bold()).tracking(3).foregroundStyle(AircheckTheme.signal)
                Text(show.date.formatted(.dateTime.month(.wide).day()))
                    .font(.system(size: 64, weight: .bold, design: .serif)).tracking(-4)
                Text(liveHeadline)
                    .font(.system(.title2, design: .serif, weight: .semibold))
                    .frame(maxWidth: 400, alignment: .leading)
                Text(show.durationText + "  ·  24 kbps archive stream")
                    .font(.subheadline).foregroundStyle(.secondary)
                Button { player.play(show) } label: {
                    Label(player.currentShow?.id == show.id && player.isPlaying ? "Playing" : "Hey Now", systemImage: "play.fill")
                        .font(.headline).padding(.horizontal, 24).padding(.vertical, 15)
                        .foregroundStyle(AircheckTheme.paper)
                        .background(AircheckTheme.ink, in: Capsule())
                }
            }
            .padding(30)
            .background(.ultraThinMaterial.opacity(0.38), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .shadow(color: .white.opacity(0.72), radius: 12)
            .foregroundStyle(AircheckTheme.ink)
            .padding(30)
        }
        .frame(height: 390)
        .padding(.top, 12)
    }

    @ViewBuilder private var stories: some View {
        if show.topics.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Text("The tape is on the desk.").font(.system(.title2, design: .serif, weight: .semibold))
                Text("Audio is ready now. The transcript and story map are produced by the Mac pipeline and appear here as each broadcast completes.")
                    .foregroundStyle(.secondary)
                Label("Index pending", systemImage: "waveform.badge.magnifyingglass").font(.subheadline.bold()).padding(.top, 6)
            }.softCard(AircheckTheme.blue)
        } else {
            LazyVGrid(
                columns: isPad
                    ? [GridItem(.flexible(), spacing: 20), GridItem(.flexible(), spacing: 20)]
                    : [GridItem(.flexible())],
                alignment: .leading,
                spacing: 18
            ) {
                ForEach(Array(show.topics.enumerated()), id: \.element.id) { index, topic in
                    TopicCard(topic: topic, color: AircheckTheme.storyColors[index % AircheckTheme.storyColors.count])
                }
            }
        }
    }

    @ViewBuilder private var transcript: some View {
        if isLoadingTranscript {
            ProgressView("Opening transcript…").frame(maxWidth: .infinity).padding(.vertical, 60)
        } else if transcriptSegments.isEmpty {
            ContentUnavailableView("Transcript in the queue", systemImage: "text.badge.clock", description: Text("This show remains fully streamable while local transcription continues."))
                .padding(.vertical, 50)
        } else {
            TranscriptView(show: transcriptShow)
        }
    }

    private var transcriptShow: Show {
        var value = show
        value.transcript = transcriptSegments
        return value
    }
}

private struct TopicCard: View {
    @Environment(AudioPlayer.self) private var player
    @Environment(CatalogStore.self) private var catalog
    let topic: Topic
    let color: Color

    var body: some View {
        Button {
            guard let show = catalog.shows.first(where: { $0.topics.contains(topic) }) else { return }
            player.play(show, at: topic.startTime)
        } label: {
            VStack(alignment: .leading, spacing: 16) {
                TopicArtwork(topic: topic)
                HStack { Text(topic.startTime.timecode).font(.caption.monospacedDigit().bold()); Spacer(); Image(systemName: "arrowtriangle.right.fill") }
                Text(topic.title).font(.system(size: 29, weight: .semibold, design: .serif)).multilineTextAlignment(.leading)
                Text(topic.summary).font(.body).multilineTextAlignment(.leading).foregroundStyle(AircheckTheme.ink.opacity(0.72))
            }.frame(maxWidth: .infinity, alignment: .leading).softCard(color)
        }.buttonStyle(.plain).foregroundStyle(AircheckTheme.ink)
    }
}

private struct TopicArtwork: View {
    let topic: Topic

    var body: some View {
        if let url = topic.imageURL {
            AsyncImage(url: url) { phase in
                if let image = phase.image {
                    image.resizable().scaledToFill()
                } else {
                    abstractSignal
                }
            }
            .frame(width: 176, height: 72)
            .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
        } else {
            abstractSignal.frame(height: 52)
        }
    }

    private var abstractSignal: some View {
        Canvas { context, size in
            let seed = topic.id.unicodeScalars.reduce(0) { $0 + Int($1.value) }
            switch seed % 4 {
            case 0: drawSignalRings(context: &context, size: size, seed: seed)
            case 1: drawLevelBars(context: &context, size: size, seed: seed)
            case 2: drawTuningDial(context: &context, size: size, seed: seed)
            default: drawTapePath(context: &context, size: size, seed: seed)
            }
        }
        .accessibilityHidden(true)
    }

    private func drawSignalRings(context: inout GraphicsContext, size: CGSize, seed: Int) {
        let center = CGPoint(x: size.width * 0.82, y: size.height * 0.5)
        for ring in 1...3 {
            let diameter = CGFloat(10 + ring * 15 + seed % 5)
            let rect = CGRect(x: center.x - diameter / 2, y: center.y - diameter / 2, width: diameter, height: diameter)
            context.stroke(Path(ellipseIn: rect), with: .color(AircheckTheme.ink.opacity(0.18)), lineWidth: 1.2)
        }
        drawWave(context: &context, size: size, seed: seed, baseline: 0.58)
    }

    private func drawLevelBars(context: inout GraphicsContext, size: CGSize, seed: Int) {
        let count = 18
        for index in 0..<count {
            let x = size.width * CGFloat(index) / CGFloat(count - 1)
            let height = CGFloat(8 + (index * 13 + seed) % 34)
            let rect = CGRect(x: x, y: (size.height - height) / 2, width: 3, height: height)
            context.fill(Path(roundedRect: rect, cornerRadius: 1.5), with: .color(AircheckTheme.ink.opacity(index.isMultiple(of: 3) ? 0.62 : 0.24)))
        }
    }

    private func drawTuningDial(context: inout GraphicsContext, size: CGSize, seed: Int) {
        let y = size.height * 0.56
        var baseline = Path()
        baseline.move(to: CGPoint(x: 0, y: y))
        baseline.addLine(to: CGPoint(x: size.width, y: y))
        context.stroke(baseline, with: .color(AircheckTheme.ink.opacity(0.38)), lineWidth: 1.5)
        for index in 0...12 {
            let x = size.width * CGFloat(index) / 12
            let tickHeight: CGFloat = index == seed % 13 ? 24 : (index.isMultiple(of: 3) ? 15 : 8)
            var tick = Path()
            tick.move(to: CGPoint(x: x, y: y - tickHeight / 2))
            tick.addLine(to: CGPoint(x: x, y: y + tickHeight / 2))
            context.stroke(tick, with: .color(AircheckTheme.ink.opacity(index == seed % 13 ? 0.72 : 0.26)), lineWidth: index == seed % 13 ? 2.5 : 1)
        }
    }

    private func drawTapePath(context: inout GraphicsContext, size: CGSize, seed: Int) {
        for offset in [0.28, 0.72] {
            let center = CGPoint(x: size.width * offset, y: size.height * 0.48)
            let rect = CGRect(x: center.x - 15, y: center.y - 15, width: 30, height: 30)
            context.stroke(Path(ellipseIn: rect), with: .color(AircheckTheme.ink.opacity(0.28)), lineWidth: 1.5)
            let hub = CGRect(x: center.x - 4, y: center.y - 4, width: 8, height: 8)
            context.fill(Path(ellipseIn: hub), with: .color(AircheckTheme.ink.opacity(0.55)))
        }
        drawWave(context: &context, size: size, seed: seed, baseline: 0.5)
    }

    private func drawWave(context: inout GraphicsContext, size: CGSize, seed: Int, baseline: CGFloat) {
        var wave = Path()
        wave.move(to: CGPoint(x: 0, y: size.height * baseline))
        for step in 1...32 {
            let x = size.width * CGFloat(step) / 32
            let amplitude = CGFloat(5 + seed % 9)
            let y = size.height * baseline + sin(CGFloat(step + seed) * 0.72) * amplitude
            wave.addLine(to: CGPoint(x: x, y: y))
        }
        context.stroke(wave, with: .color(AircheckTheme.ink.opacity(0.62)), lineWidth: 1.7)
    }
}

private struct TranscriptView: View {
    @Environment(AudioPlayer.self) private var player
    let show: Show

    var body: some View {
        ScrollViewReader { proxy in
            LazyVStack(alignment: .leading, spacing: 2) {
                ForEach(show.transcript) { segment in
                    let active = player.currentShow?.id == show.id && TranscriptTimeline.activeSegment(at: player.currentTime, in: show.transcript)?.id == segment.id
                    Button { player.play(show, at: segment.startTime) } label: {
                        HStack(alignment: .top, spacing: 12) {
                            Text(segment.startTime.timecode).font(.caption.monospacedDigit()).foregroundStyle(.secondary).frame(width: 54, alignment: .leading)
                            VStack(alignment: .leading, spacing: 4) {
                                if let speaker = segment.speaker { Text(speaker.uppercased()).font(.caption2.bold()).tracking(1.2).foregroundStyle(AircheckTheme.signal) }
                                Text(segment.text).font(.body).multilineTextAlignment(.leading)
                            }
                        }
                        .padding(.vertical, 10).padding(.horizontal, 8)
                        .background(active ? AircheckTheme.peach.opacity(0.28) : .clear, in: RoundedRectangle(cornerRadius: 12))
                    }.buttonStyle(.plain).foregroundStyle(AircheckTheme.ink).id(segment.id)
                }
            }
            .onChange(of: player.currentTime) {
                guard player.currentShow?.id == show.id,
                      let active = TranscriptTimeline.activeSegment(at: player.currentTime, in: show.transcript)
                else { return }
                withAnimation(.easeInOut(duration: 0.35)) { proxy.scrollTo(active.id, anchor: .center) }
            }
        }
    }
}
