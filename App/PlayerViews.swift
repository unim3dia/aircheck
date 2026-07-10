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
            Button { player.showsFullPlayer = true } label: {
                HStack(spacing: 12) {
                    SignalGlyph(isActive: player.isPlaying).scaleEffect(0.78).frame(width: 44)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(show.shortDate).font(.headline)
                        Text(player.currentTime.timecode + " / " + show.duration.timecode).font(.caption.monospacedDigit()).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button { player.toggle() } label: { Image(systemName: player.isPlaying ? "pause.fill" : "play.fill").frame(width: 44, height: 44) }
                        .buttonStyle(.plain).accessibilityLabel(player.isPlaying ? "Pause" : "Play")
                }
                .padding(.horizontal, 12).padding(.vertical, 8)
                .background(.ultraThinMaterial)
                .overlay(alignment: .top) { ProgressView(value: player.progress(for: show)).tint(AircheckTheme.signal) }
            }
            .buttonStyle(.plain).foregroundStyle(AircheckTheme.ink)
        }
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
                        Text("AIRCHECK ’06").font(.caption.bold()).tracking(2).foregroundStyle(AircheckTheme.signal)
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
