import AircheckCore
import AVFoundation
import MediaPlayer
import Observation
import UIKit

@Observable
final class AudioPlayer {
    private(set) var currentShow: Show?
    private(set) var isPlaying = false
    private(set) var currentTime: TimeInterval = 0
    private(set) var duration: TimeInterval = 0
    private(set) var history: [ListeningHistoryEntry] = []
    var showsFullPlayer = false

    var currentSectionTitle: String? {
        guard let show = currentShow else { return nil }
        return show.topics.last(where: { $0.startTime <= currentTime })?.title
            ?? show.topics.first?.title
            ?? show.displayTitle
    }

    @ObservationIgnored private let player = AVPlayer()
    @ObservationIgnored private var timeObserver: Any?
    @ObservationIgnored private let defaults = UserDefaults.standard
    @ObservationIgnored private var lastListeningTick = Date()
    @ObservationIgnored private var lastHistorySave = Date.distantPast

    private let historyKey = "listening.history.v1"
    private let lastShowKey = "playback.lastShowID"

    init() {
        restoreHistory()
        configureAudioSession()
        configureRemoteCommands()
        observePlayer()
    }

    func play(_ show: Show, at requestedTime: TimeInterval? = nil) {
        if currentShow?.id != show.id {
            prepare(show, at: requestedTime, recordsHistory: true)
        } else if let requestedTime {
            seek(to: requestedTime)
        }
        defaults.set(show.id, forKey: lastShowKey)
        touchHistory(for: show)
        lastListeningTick = Date()
        player.play()
        isPlaying = true
        updateNowPlaying()
    }

    func toggle() {
        guard currentShow != nil else { return }
        if isPlaying { player.pause() } else { player.play() }
        isPlaying.toggle()
        lastListeningTick = Date()
        persistHistory()
        updateNowPlaying()
    }

    func seek(to time: TimeInterval) {
        seek(to: time, recordsHistory: true)
    }

    private func seek(to time: TimeInterval, recordsHistory: Bool) {
        let target = max(0, min(time, duration))
        player.seek(to: CMTime(seconds: target, preferredTimescale: 600), toleranceBefore: .zero, toleranceAfter: .zero)
        currentTime = target
        if recordsHistory, let show = currentShow { recordHistory(for: show, listenedDelta: 0) }
        updateNowPlaying()
    }

    func skip(by seconds: TimeInterval) { seek(to: currentTime + seconds) }

    func progress(for show: Show) -> Double {
        let saved = currentShow?.id == show.id ? currentTime : defaults.double(forKey: progressKey(show.id))
        guard show.duration > 0 else { return 0 }
        return min(max(saved / show.duration, 0), 1)
    }

    func restoreLastShow(from shows: [Show]) {
        guard currentShow == nil, !shows.isEmpty else { return }
        let show = defaults.string(forKey: lastShowKey).flatMap { id in
            shows.first(where: { $0.id == id })
        } ?? shows.sorted(by: { $0.date < $1.date }).first!
        prepare(show, at: nil, recordsHistory: false)
    }

    func historyEntry(for show: Show) -> ListeningHistoryEntry? {
        history.first { $0.showID == show.id }
    }

    func persistHistory() {
        if let data = try? JSONEncoder().encode(history) {
            defaults.set(data, forKey: historyKey)
            lastHistorySave = Date()
        }
        if let show = currentShow {
            defaults.set(currentTime, forKey: progressKey(show.id))
        }
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
                let now = Date()
                let delta = self.isPlaying ? min(max(now.timeIntervalSince(self.lastListeningTick), 0), 1) : 0
                self.lastListeningTick = now
                self.recordHistory(for: show, listenedDelta: delta, at: now)
                if now.timeIntervalSince(self.lastHistorySave) >= 5 { self.persistHistory() }
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
        player.pause(); isPlaying = false; persistHistory(); updateNowPlaying(); return .success
    }

    private func skipFromRemote(_ seconds: TimeInterval) -> MPRemoteCommandHandlerStatus {
        skip(by: seconds); return .success
    }

    private func updateNowPlaying() {
        guard let show = currentShow else { return }
        let sectionTitle = (currentSectionTitle ?? show.displayTitle) + " · " + show.date.formatted(.dateTime.month(.twoDigits).year(.twoDigits))
        var info: [String: Any] = [
            MPMediaItemPropertyTitle: sectionTitle,
            MPMediaItemPropertyAlbumTitle: "Airhcheck",
            MPMediaItemPropertyArtist: "The Howard Stern Show — 2006 archive",
            MPMediaItemPropertyPlaybackDuration: show.duration,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: currentTime,
            MPNowPlayingInfoPropertyPlaybackRate: isPlaying ? 1.0 : 0.0
        ]
        if let image = UIImage(named: "Howard2") {
            info[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: image.size) { _ in image }
        }
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }

    private func progressKey(_ showID: String) -> String { "playback.progress.\(showID)" }

    private func prepare(_ show: Show, at requestedTime: TimeInterval?, recordsHistory: Bool) {
        currentShow = show
        duration = show.duration
        player.replaceCurrentItem(with: AVPlayerItem(url: show.audioURL))
        let historyPosition = historyEntry(for: show)?.lastPosition
        let legacyPosition = defaults.object(forKey: progressKey(show.id)) as? Double
        let saved = historyPosition ?? legacyPosition
        seek(
            to: requestedTime ?? ResumePositionPolicy.startTime(saved: saved, duration: show.duration),
            recordsHistory: recordsHistory
        )
        defaults.set(show.id, forKey: lastShowKey)
        updateNowPlaying()
    }

    private func touchHistory(for show: Show) {
        recordHistory(for: show, listenedDelta: 0)
    }

    private func recordHistory(for show: Show, listenedDelta: TimeInterval, at date: Date = Date()) {
        if let index = history.firstIndex(where: { $0.showID == show.id }) {
            history[index].record(position: currentTime, listenedDelta: listenedDelta, at: date)
        } else {
            history.append(ListeningHistoryEntry(
                showID: show.id,
                lastPosition: currentTime,
                furthestPosition: currentTime,
                secondsListened: max(listenedDelta, 0),
                duration: show.duration,
                lastListenedAt: date
            ))
        }
        history = ListeningHistoryEntry.mostRecentFirst(history)
    }

    private func restoreHistory() {
        guard let data = defaults.data(forKey: historyKey),
              let saved = try? JSONDecoder().decode([ListeningHistoryEntry].self, from: data) else { return }
        history = ListeningHistoryEntry.mostRecentFirst(saved)
    }
}
