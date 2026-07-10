import AircheckCore
import SwiftUI

struct SignalGlyph: View {
    let isActive: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var breath = false

    var body: some View {
        ZStack {
            Circle().fill(AircheckTheme.signal.opacity(0.15)).frame(width: 54, height: 54).scaleEffect(breath ? 1.08 : 0.92)
            Image(systemName: "antenna.radiowaves.left.and.right").foregroundStyle(AircheckTheme.signal).font(.title3)
        }
        .onAppear { updateAnimation() }
        .onChange(of: isActive) { updateAnimation() }
    }

    private func updateAnimation() {
        guard isActive, !reduceMotion else { breath = false; return }
        withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) { breath = true }
    }
}

struct MiniPlayer: View {
    @Environment(AudioPlayer.self) private var player

    var body: some View {
        if let show = player.currentShow {
            VStack(spacing: 0) {
                MicrophoneScrubber(
                    value: player.currentTime,
                    duration: show.duration,
                    onSeek: player.seek
                )
                HStack(spacing: 12) {
                    VintageMicrophoneGlyph().frame(width: 36, height: 36)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(show.shortDate).font(.headline)
                        Text(player.currentTime.timecode + " / " + show.duration.timecode).font(.caption.monospacedDigit()).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button { player.toggle() } label: { Image(systemName: player.isPlaying ? "pause.fill" : "play.fill").frame(width: 44, height: 44) }
                        .buttonStyle(.plain).accessibilityLabel(player.isPlaying ? "Pause" : "Play")
                    Button { player.showsFullPlayer = true } label: {
                        Image(systemName: "chevron.up").frame(width: 32, height: 44)
                    }
                    .buttonStyle(.plain).accessibilityLabel("Open expanded player")
                }
                .padding(.horizontal, 12).padding(.vertical, 8)
            }
            .background {
                LinearGradient(
                    colors: [
                        Color(red: 0.58, green: 0.28, blue: 0.16),
                        Color(red: 0.76, green: 0.43, blue: 0.24),
                        Color(red: 0.48, green: 0.21, blue: 0.12)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .overlay {
                    Canvas { context, size in
                        for index in 0..<48 {
                            let y = CGFloat((index * 29) % 100) / 100 * size.height
                            var grain = Path()
                            grain.move(to: CGPoint(x: 0, y: y))
                            grain.addCurve(to: CGPoint(x: size.width, y: y + CGFloat((index % 3) - 1)), control1: CGPoint(x: size.width * 0.3, y: y - 2), control2: CGPoint(x: size.width * 0.7, y: y + 2))
                            context.stroke(grain, with: .color(.black.opacity(0.10)), lineWidth: CGFloat(index % 3 + 1))
                        }
                    }
                }
            }
            .foregroundStyle(AircheckTheme.ink)
        }
    }
}

private struct MicrophoneScrubber: View {
    let value: TimeInterval
    let duration: TimeInterval
    let onSeek: (TimeInterval) -> Void

    private var fraction: Double {
        guard duration > 0 else { return 0 }
        return min(max(value / duration, 0), 1)
    }

    var body: some View {
        GeometryReader { proxy in
            let usableWidth = max(proxy.size.width - 24, 1)
            let x = 12 + usableWidth * fraction
            ZStack(alignment: .leading) {
                Capsule().fill(AircheckTheme.ink.opacity(0.14)).frame(height: 3).padding(.horizontal, 12)
                Capsule().fill(AircheckTheme.signal).frame(width: max(x, 12), height: 4)
                VintageMicrophoneGlyph()
                    .frame(width: 28, height: 28)
                    .position(x: x, y: 14)
                    .shadow(color: AircheckTheme.ink.opacity(0.16), radius: 2, y: 1)
            }
            .contentShape(Rectangle())
            .gesture(DragGesture(minimumDistance: 0).onChanged { gesture in
                let draggedFraction = min(max((gesture.location.x - 12) / usableWidth, 0), 1)
                onSeek(duration * draggedFraction)
            })
        }
        .frame(height: 28)
        .accessibilityRepresentation {
            Slider(
                value: Binding(get: { value }, set: onSeek),
                in: 0...max(duration, 1)
            ) {
                Text("Show position")
            }
        }
    }
}

private struct VintageMicrophoneGlyph: View {
    private let silver = LinearGradient(
        colors: [.white, Color(white: 0.74), Color(white: 0.48), Color(white: 0.82)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Capsule()
                    .fill(silver)
                    .stroke(AircheckTheme.ink.opacity(0.62), lineWidth: 1)
                VStack(spacing: 2) {
                    ForEach(0..<4, id: \.self) { _ in
                        Capsule().fill(AircheckTheme.ink.opacity(0.64)).frame(width: 7, height: 1)
                    }
                }
            }
            .frame(width: 13, height: 17)
            Rectangle().fill(Color(white: 0.42)).frame(width: 2, height: 4)
            Capsule().fill(Color(white: 0.38)).frame(width: 12, height: 2)
        }
        .padding(3)
        .rotationEffect(.degrees(-13))
        .accessibilityHidden(true)
    }
}

struct FullPlayerView: View {
    @Environment(AudioPlayer.self) private var player
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            PaperBackground()
            if let show = player.currentShow {
                VStack(spacing: 28) {
                    Capsule().fill(AircheckTheme.ink.opacity(0.2)).frame(width: 42, height: 5).padding(.top, 10)
                    Spacer()
                    SignalGlyph(isActive: player.isPlaying).scaleEffect(2.5).frame(height: 140)
                    VStack(spacing: 7) {
                        Text(show.formattedDate).font(.system(.title2, design: .serif, weight: .semibold)).multilineTextAlignment(.center)
                        Text("AIRHCHECK").font(.caption.bold()).tracking(2).foregroundStyle(AircheckTheme.signal)
                    }
                    VStack(spacing: 8) {
                        Slider(value: Binding(get: { player.currentTime }, set: { player.seek(to: $0) }), in: 0...max(show.duration, 1)).tint(AircheckTheme.signal)
                        HStack { Text(player.currentTime.timecode); Spacer(); Text("−" + max(show.duration - player.currentTime, 0).timecode) }
                            .font(.caption.monospacedDigit()).foregroundStyle(.secondary)
                    }
                    HStack(spacing: 38) {
                        Button { player.skip(by: -15) } label: { Image(systemName: "gobackward.15") }
                        Button { player.toggle() } label: {
                            Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: 32)).frame(width: 78, height: 78)
                                .foregroundStyle(AircheckTheme.paper).background(AircheckTheme.ink, in: Circle())
                        }
                        Button { player.skip(by: 30) } label: { Image(systemName: "goforward.30") }
                    }.font(.title2).buttonStyle(.plain)
                    Spacer()
                    Text("STREAMING FROM INTERNET ARCHIVE").font(.caption2.bold()).tracking(1.5).foregroundStyle(.secondary)
                }.padding(.horizontal, 28).padding(.bottom, 28)
            }
        }
        .foregroundStyle(AircheckTheme.ink)
        .presentationDetents([.large])
        .overlay(alignment: .topTrailing) {
            Button { dismiss() } label: { Image(systemName: "xmark").frame(width: 44, height: 44).background(.white.opacity(0.55), in: Circle()) }
                .padding(16).buttonStyle(.plain).foregroundStyle(AircheckTheme.ink)
        }
    }
}
