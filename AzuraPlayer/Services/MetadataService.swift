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
        if currentAPIURL == apiURL && timer != nil { return }

        stopPolling()
        currentAPIURL = apiURL
        isConnecting = true

        Task { await fetchNowPlaying() }

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

            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let stationData = json["station"] as? [String: Any],
                  let name = stationData["name"] as? String,
                  let shortcode = stationData["shortcode"] as? String else { return }

            stationName = name
            isOnline = (json["is_online"] as? Bool) ?? true
            isLive = false
            isConnecting = false

            if let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
               let scheme = components.scheme,
               let host = components.host {
                let newArtURL = "\(scheme)://\(host)/api/station/\(shortcode)/art"
                if stationArtURL != newArtURL {
                    stationArtURL = newArtURL
                }
            }

            if let nowPlayingDict = json["now_playing"] as? [String: Any],
               let songDict = nowPlayingDict["song"] as? [String: Any],
               let title = songDict["title"] as? String,
               let artist = songDict["artist"] as? String {

                let newSong = SongInfo(
                    title: title,
                    artist: artist,
                    art: songDict["art"] as? String,
                    album: songDict["album"] as? String
                )

                if currentTrack?.title != title || currentTrack?.artist != artist {
                    currentTrack = newSong
                }
            }

        } catch {
            isConnecting = false
        }
    }
}
