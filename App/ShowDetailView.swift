import AircheckCore
import SwiftUI

struct ShowDetailView: View {
    @Environment(AudioPlayer.self) private var player
    @Environment(CatalogStore.self) private var catalog
    let show: Show
    @State private var mode = DetailMode.stories
    @State private var transcriptSegments: [TranscriptSegment] = []
    @State private var isLoadingTranscript = false

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
                .padding(.horizontal, 20).padding(.bottom, 40)
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

    private var hero: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(show.weekday).font(.caption.bold()).tracking(3).foregroundStyle(AircheckTheme.signal)
            Text(show.date.formatted(.dateTime.month(.wide).day()))
                .font(.system(size: 56, weight: .bold, design: .serif)).tracking(-3)
            Text(show.displayTitle).font(.title3.weight(.medium))
            Text(show.durationText + "  ·  24 kbps archive stream").font(.subheadline).foregroundStyle(.secondary)
            Button { player.play(show) } label: {
                Label(player.currentShow?.id == show.id && player.isPlaying ? "Playing" : "Listen from here", systemImage: "play.fill")
                    .font(.headline).frame(maxWidth: .infinity).padding(.vertical, 16)
                    .foregroundStyle(AircheckTheme.paper)
                    .background(AircheckTheme.ink, in: Capsule())
            }
        }
        .padding(.top, 10)
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
            LazyVStack(spacing: 18) {
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
            .frame(height: 112).clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        } else {
            abstractSignal.frame(height: 78)
        }
    }

    private var abstractSignal: some View {
        Canvas { context, size in
            let seed = topic.id.unicodeScalars.reduce(0) { $0 + Int($1.value) }
            let center = CGPoint(x: size.width * 0.76, y: size.height * 0.46)
            for ring in 1...3 {
                let diameter = CGFloat(18 + ring * 23 + seed % 9)
                let rect = CGRect(x: center.x - diameter / 2, y: center.y - diameter / 2, width: diameter, height: diameter)
                context.stroke(Path(ellipseIn: rect), with: .color(AircheckTheme.ink.opacity(0.16)), lineWidth: 1.5)
            }
            var wave = Path()
            wave.move(to: CGPoint(x: 0, y: size.height * 0.6))
            let steps = 32
            for step in 1...steps {
                let x = size.width * CGFloat(step) / CGFloat(steps)
                let amplitude = CGFloat(8 + seed % 16)
                let y = size.height * 0.6 + sin(CGFloat(step + seed) * 0.72) * amplitude
                wave.addLine(to: CGPoint(x: x, y: y))
            }
            context.stroke(wave, with: .color(AircheckTheme.ink.opacity(0.62)), lineWidth: 2)
        }
        .accessibilityHidden(true)
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
