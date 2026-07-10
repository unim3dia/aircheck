import AircheckCore
import AVFoundation
import MediaPlayer
import Observation

@Observable
final class AudioPlayer {
    private(set) var currentShow: Show?
    private(set) var isPlaying = false
    private(set) var currentTime: TimeInterval = 0
    private(set) var duration: TimeInterval = 0
    var showsFullPlayer = false

    @ObservationIgnored private let player = AVPlayer()
    @ObservationIgnored private var timeObserver: Any?
    @ObservationIgnored private let defaults = UserDefaults.standard

    init() {
        configureAudioSession()
        configureRemoteCommands()
        observePlayer()
    }

    func play(_ show: Show, at requestedTime: TimeInterval? = nil) {
        if currentShow?.id != show.id {
            currentShow = show
            duration = show.duration
            player.replaceCurrentItem(with: AVPlayerItem(url: show.audioURL))
            let saved = defaults.object(forKey: progressKey(show.id)) as? Double
            seek(to: requestedTime ?? ResumePositionPolicy.startTime(saved: saved, duration: show.duration))
        } else if let requestedTime {
            seek(to: requestedTime)
        }
        player.play()
        isPlaying = true
        updateNowPlaying()
    }

    func toggle() {
        guard currentShow != nil else { return }
        if isPlaying { player.pause() } else { player.play() }
        isPlaying.toggle()
        updateNowPlaying()
    }

    func seek(to time: TimeInterval) {
        let target = max(0, min(time, duration))
        player.seek(to: CMTime(seconds: target, preferredTimescale: 600), toleranceBefore: .zero, toleranceAfter: .zero)
        currentTime = target
        updateNowPlaying()
    }

    func skip(by seconds: TimeInterval) { seek(to: currentTime + seconds) }

    func progress(for show: Show) -> Double {
        let saved = currentShow?.id == show.id ? currentTime : defaults.double(forKey: progressKey(show.id))
        guard show.duration > 0 else { return 0 }
        return min(max(saved / show.duration, 0), 1)
    }

    private func observePlayer() {
        timeObserver = player.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 0.5, preferredTimescale: 600),
            queue: .main
        ) { [weak self] time in
            Task { @MainActor [weak self] in
                guard let self, let show = self.currentShow else { return }
                self.currentTime = time.seconds.isFinite ? time.seconds : 0
                self.isPlaying = self.player.timeControlStatus == .playing
                self.defaults.set(self.currentTime, forKey: self.progressKey(show.id))
                self.updateNowPlaying()
            }
        }
    }

    private func configureAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .spokenAudio)
            try session.setActive(true)
        } catch {
            assertionFailure("Audio session configuration failed: \(error)")
        }
    }

    private func configureRemoteCommands() {
        let commands = MPRemoteCommandCenter.shared()
        commands.playCommand.addTarget { [weak self] _ in self?.resumeFromRemote() ?? .commandFailed }
        commands.pauseCommand.addTarget { [weak self] _ in self?.pauseFromRemote() ?? .commandFailed }
        commands.skipForwardCommand.preferredIntervals = [30]
        commands.skipForwardCommand.addTarget { [weak self] _ in self?.skipFromRemote(30) ?? .commandFailed }
        commands.skipBackwardCommand.preferredIntervals = [15]
        commands.skipBackwardCommand.addTarget { [weak self] _ in self?.skipFromRemote(-15) ?? .commandFailed }
        commands.changePlaybackPositionCommand.addTarget { [weak self] event in
            guard let self, let event = event as? MPChangePlaybackPositionCommandEvent else { return .commandFailed }
            self.seek(to: event.positionTime)
            return .success
        }
    }

    private func resumeFromRemote() -> MPRemoteCommandHandlerStatus {
        guard currentShow != nil else { return .noSuchContent }
        player.play(); isPlaying = true; updateNowPlaying(); return .success
    }

    private func pauseFromRemote() -> MPRemoteCommandHandlerStatus {
        player.pause(); isPlaying = false; updateNowPlaying(); return .success
    }

    private func skipFromRemote(_ seconds: TimeInterval) -> MPRemoteCommandHandlerStatus {
        skip(by: seconds); return .success
    }

    private func updateNowPlaying() {
        guard let show = currentShow else { return }
        MPNowPlayingInfoCenter.default().nowPlayingInfo = [
            MPMediaItemPropertyTitle: show.formattedDate,
            MPMediaItemPropertyAlbumTitle: "Aircheck ’06",
            MPMediaItemPropertyArtist: "The Howard Stern Show — 2006 archive",
            MPMediaItemPropertyPlaybackDuration: show.duration,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: currentTime,
            MPNowPlayingInfoPropertyPlaybackRate: isPlaying ? 1.0 : 0.0
        ]
    }

    private func progressKey(_ showID: String) -> String { "playback.progress.\(showID)" }
}
