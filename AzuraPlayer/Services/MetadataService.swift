//
//  MetadataService.swift
//  AzuraPlayer
//

import Foundation
import Combine

class MetadataService: ObservableObject {
    static let shared = MetadataService()

    @Published var currentTrack: SongInfo?
    @Published var stationName: String?
    @Published var stationArtURL: String?
    @Published var isLive: Bool = false
    @Published var isOnline: Bool = false
    @Published var isConnecting: Bool = false

    private var timer: AnyCancellable?
    private var currentAPIURL: String?

    func startPolling(apiURL: String) {
        // Verhindert Neustart, wenn URL gleich und Timer schon läuft
        if currentAPIURL == apiURL && timer != nil { return }
        
        stopPolling()
        currentAPIURL = apiURL
        isConnecting = true
        
        // Sofortiger erster Abruf (damit nicht 5 Sekunden gewartet wird bis zum ersten Update)
        Task { await fetchNowPlaying() }

        // --- HIER IST DIE ÄNDERUNG ---
        // Intervall von 10 auf 5 Sekunden reduziert für schnellere Song-Updates
        timer = Timer.publish(every: 5, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                Task { await self?.fetchNowPlaying() }
            }
    }

    func stopPolling() {
        timer?.cancel()
        timer = nil
    }

    @MainActor
    private func fetchNowPlaying() async {
        guard let urlString = currentAPIURL,
              let url = URL(string: urlString) else { return }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            
            // Rohes JSON parsen für maximale Flexibilität bei fehlenden Feldern
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let stationData = json["station"] as? [String: Any],
                  let name = stationData["name"] as? String,
                  let shortcode = stationData["shortcode"] as? String else {
                return
            }
            
            // Basis-Daten setzen
            stationName = name
            isOnline = (json["is_online"] as? Bool) ?? true
            isLive = false
            
            // Sender-Logo URL konstruieren
            if let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
               let scheme = components.scheme,
               let host = components.host {
                let baseURL = "\(scheme)://\(host)"
                let newArtURL = "\(baseURL)/api/station/\(shortcode)/art"
                if self.stationArtURL != newArtURL {
                    self.stationArtURL = newArtURL
                }
            }

            // Song-Daten extrahieren (inkl. Cover)
            if let nowPlayingDict = json["now_playing"] as? [String: Any],
               let songDict = nowPlayingDict["song"] as? [String: Any],
               let title = songDict["title"] as? String,
               let artist = songDict["artist"] as? String {
                
                let artURL = songDict["art"] as? String
                let newSong = SongInfo(title: title, artist: artist, art: artURL, album: songDict["album"] as? String)
                
                // Update nur bei Änderung
                if self.currentTrack?.title != title || self.currentTrack?.artist != artist {
                    self.currentTrack = newSong
                    // Optional: Debug-Print entfernen, wenn es zu viel wird
                    // print("🎵 Songwechsel: \(artist) - \(title)")
                }
            }
            
            isConnecting = false

        } catch {
            isConnecting = false
            // Fehler schweigen, es sei denn, es ist ein dauerhafter Verbindungsabbruch
            // print("❌ Metadata Error: \(error.localizedDescription)")
        }
    }
}
