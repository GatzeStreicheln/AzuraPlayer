import Foundation
import AVFoundation
import MediaPlayer
import Combine

class WatchNowPlayingManager: NSObject, ObservableObject {
    @Published var isPlaying: Bool = false
    @Published var currentStation: RadioStation?
    @Published var songTitle: String = ""
    @Published var artistName: String = ""
    @Published var artworkURL: String?

    private var player: AVPlayer?
    private var pollTask: Task<Void, Never>?

    override init() {
        super.init()
        setupAudioSession()
        setupRemoteControls()
        setupInterruptionHandling()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Audio Session

    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(
                .playback,
                mode: .default,
                policy: .longFormAudio
            )
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Watch audio session error: \(error)")
        }
    }

    private func setupInterruptionHandling() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleInterruption(_:)),
            name: AVAudioSession.interruptionNotification,
            object: nil
        )
    }

    @objc private func handleInterruption(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else { return }

        if type == .ended {
            try? AVAudioSession.sharedInstance().setActive(true)
            if isPlaying, let station = currentStation {
                play(station: station)
            }
        }
    }

    // MARK: - Playback

    func play(station: RadioStation) {
        guard let url = URL(string: station.streamURL) else { return }

        player?.pause()
        player = nil

        let item = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: item)
        player?.automaticallyWaitsToMinimizeStalling = false
        player?.play()

        currentStation = station
        isPlaying = true

        startPolling(station: station)
        updateNowPlaying()
    }

    func stop() {
        player?.pause()
        player = nil
        isPlaying = false
        currentStation = nil
        songTitle = ""
        artistName = ""
        artworkURL = nil
        pollTask?.cancel()
        pollTask = nil
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
    }

    func pause() {
        player?.pause()
        player = nil
        isPlaying = false
        // pollTask läuft weiter → Metadaten-Updates auch bei Pause
        updateNowPlaying()
    }

    func togglePlayPause() {
        if isPlaying {
            pause()
        } else if let station = currentStation {
            play(station: station)
        }
    }

    // MARK: - Remote Controls (AirPods / Kopfhörer / Sperr-Screen)

    private func setupRemoteControls() {
        let cc = MPRemoteCommandCenter.shared()

        cc.playCommand.isEnabled = true
        cc.playCommand.addTarget { [weak self] _ in
            guard let self, let station = self.currentStation else { return .commandFailed }
            self.play(station: station)
            return .success
        }

        cc.pauseCommand.isEnabled = true
        cc.pauseCommand.addTarget { [weak self] _ in
            self?.pause()
            return .success
        }

        cc.togglePlayPauseCommand.isEnabled = true
        cc.togglePlayPauseCommand.addTarget { [weak self] _ in
            self?.togglePlayPause()
            return .success
        }

        // Nicht relevant für Radio → deaktivieren damit watchOS sie nicht anzeigt
        cc.nextTrackCommand.isEnabled = false
        cc.previousTrackCommand.isEnabled = false
        cc.skipForwardCommand.isEnabled = false
        cc.skipBackwardCommand.isEnabled = false
    }

    // MARK: - Metadata Polling

    private func startPolling(station: RadioStation) {
        pollTask?.cancel()
        guard !station.apiURL.isEmpty else { return }

        pollTask = Task {
            while !Task.isCancelled {
                await fetchNowPlaying(station: station)
                try? await Task.sleep(nanoseconds: 15_000_000_000)
            }
        }
    }

    private func fetchNowPlaying(station: RadioStation) async {
        guard let url = URL(string: station.apiURL) else { return }
        guard let (data, _) = try? await URLSession.shared.data(from: url) else { return }
        guard let response = try? JSONDecoder().decode(NowPlayingResponse.self, from: data) else { return }

        await MainActor.run {
            if let song = response.nowPlaying?.song {
                self.songTitle = song.title
                self.artistName = song.artist
                self.artworkURL = song.art
            }
            self.updateNowPlaying()
        }
    }

    // MARK: - Now Playing Info

    private func updateNowPlaying() {
        var info: [String: Any] = [:]
        info[MPMediaItemPropertyTitle] = songTitle.isEmpty ? (currentStation?.displayName ?? "") : songTitle
        info[MPMediaItemPropertyArtist] = artistName.isEmpty ? (currentStation?.displayName ?? "") : artistName
        info[MPNowPlayingInfoPropertyIsLiveStream] = true
        info[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0
        info[MPNowPlayingInfoPropertyDefaultPlaybackRate] = 1.0
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }
}
