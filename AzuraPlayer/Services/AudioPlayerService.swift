//
//  AudioPlayerService.swift
//  AzuraPlayer
//

import AVFoundation
import MediaPlayer
import Combine
import UIKit
import SwiftUI

class AudioPlayerService: ObservableObject {
    static let shared = AudioPlayerService()

    @Published var isPlaying: Bool = false
    @Published var isBuffering: Bool = false
    @Published var currentStation: RadioStation?

    private var player: AVPlayer?
    private var playerItem: AVPlayerItem?
    private var statusObserver: NSKeyValueObservation?
    private var reconnectTimer: Timer?
    private var reconnectAttempts = 0
    private var metadataTimer: Timer?
    
    // SPEICHER FÜR DAS COVER-BILD
    // Wir behalten das letzte erfolgreiche Bild im RAM, damit es nie verschwindet
    private var currentArtwork: MPMediaItemArtwork?
    private var lastDisplayedArtURL: String?

    private init() {
        setupAudioSession()
        setupRemoteControls()
    }

    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(
                .playback,
                mode: .default,
                options: [.allowAirPlay, .allowBluetoothHFP]
            )
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Audio session error: \(error)")
        }
    }

    func play(station: RadioStation) {
        guard let url = URL(string: station.streamURL) else { return }

        stopReconnectTimer()
        stopMetadataTimer()
        
        currentStation = station
        isBuffering = true
        reconnectAttempts = 0
        lastDisplayedArtURL = nil
        currentArtwork = nil // Reset bei neuem Sender

        player?.pause()
        player = nil
        playerItem = nil
        statusObserver?.invalidate()
        NotificationCenter.default.removeObserver(self)

        playerItem = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: playerItem)

        statusObserver = playerItem?.observe(\.status, options: [.new]) { [weak self] item, _ in
            DispatchQueue.main.async {
                switch item.status {
                case .readyToPlay:
                    self?.isBuffering = false
                case .failed:
                    self?.isBuffering = false
                    self?.scheduleReconnect()
                default:
                    break
                }
            }
        }

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(playerItemFailedToPlay),
            name: .AVPlayerItemFailedToPlayToEndTime,
            object: playerItem
        )

        player?.play()
        isPlaying = true
        
        MetadataService.shared.startPolling(apiURL: station.apiURL)
        
        updateNowPlayingInfo()
        startMetadataTimer()
    }

    func pause() {
        player?.pause()
        isPlaying = false
        isBuffering = false
    }

    func stop() {
        player?.pause()
        player = nil
        playerItem = nil
        isPlaying = false
        isBuffering = false
        currentStation = nil
        stopReconnectTimer()
        stopMetadataTimer()
        MetadataService.shared.stopPolling()
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
    }

    func togglePlayPause() {
        if isPlaying {
            pause()
        } else {
            if let station = currentStation {
                play(station: station)
            }
        }
    }

    private func startMetadataTimer() {
        metadataTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.updateNowPlayingInfo()
        }
    }
    
    private func stopMetadataTimer() {
        metadataTimer?.invalidate()
        metadataTimer = nil
    }

    @objc private func playerItemFailedToPlay() {
        DispatchQueue.main.async {
            self.isBuffering = true
            self.scheduleReconnect()
        }
    }

    private func scheduleReconnect() {
        guard isPlaying || currentStation != nil else { return }
        stopReconnectTimer()
        let delay = min(5.0 * Double(reconnectAttempts + 1), 30.0)
        reconnectTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            guard let self, let station = self.currentStation else { return }
            self.reconnectAttempts += 1
            self.play(station: station)
        }
    }

    private func stopReconnectTimer() {
        reconnectTimer?.invalidate()
        reconnectTimer = nil
    }

    // --- KORRIGIERTE COVER-LOGIK ---
    func updateNowPlayingInfo() {
        var info = [String: Any]()
        
        let title = MetadataService.shared.currentTrack?.title ?? "Live Stream"
        let artist = MetadataService.shared.currentTrack?.artist ?? currentStation?.displayName ?? "Radio"
        
        info[MPMediaItemPropertyTitle] = title
        info[MPMediaItemPropertyArtist] = artist
        info[MPNowPlayingInfoPropertyIsLiveStream] = true
        
        let currentArtURL = MetadataService.shared.currentTrack?.art ?? MetadataService.shared.stationArtURL
        
        // Szenario 1: URL hat sich geändert (neuer Song) -> Neues Bild laden
        if currentArtURL != lastDisplayedArtURL {
            lastDisplayedArtURL = currentArtURL
            
            if let urlString = currentArtURL, let url = URL(string: urlString) {
                URLSession.shared.dataTask(with: url) { data, _, _ in
                    if let data = data, let image = UIImage(data: data) {
                        let newArtwork = MPMediaItemArtwork(boundsSize: image.size) { _ in image }
                        
                        // Speichern im RAM
                        self.currentArtwork = newArtwork
                        info[MPMediaItemPropertyArtwork] = newArtwork
                        
                        DispatchQueue.main.async {
                            MPNowPlayingInfoCenter.default().nowPlayingInfo = info
                        }
                    }
                }.resume()
            }
        }
        // Szenario 2: URL gleich (gleicher Song) -> Altes Bild aus dem RAM verwenden
        else if let existingArtwork = self.currentArtwork {
            info[MPMediaItemPropertyArtwork] = existingArtwork
        }
        
        // Immer updaten (mit oder ohne neues Cover)
        DispatchQueue.main.async {
            MPNowPlayingInfoCenter.default().nowPlayingInfo = info
        }
    }

    private func setupRemoteControls() {
        let commandCenter = MPRemoteCommandCenter.shared()
        
        commandCenter.playCommand.addTarget { [weak self] _ in
            if let station = self?.currentStation {
                self?.play(station: station)
            }
            return .success
        }
        
        commandCenter.pauseCommand.addTarget { [weak self] _ in
            self?.pause()
            return .success
        }
        
        commandCenter.stopCommand.isEnabled = false
        commandCenter.stopCommand.removeTarget(nil)
        
        commandCenter.nextTrackCommand.isEnabled = false
        commandCenter.previousTrackCommand.isEnabled = false
    }
}
