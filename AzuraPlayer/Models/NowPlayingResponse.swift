import Foundation

struct NowPlayingResponse: Codable {
    let station: StationInfo
    let nowPlaying: NowPlayingTrack?
    let live: LiveInfo?
    let isOnline: Bool?

    enum CodingKeys: String, CodingKey {
        case station
        case nowPlaying = "now_playing"
        case live
        case isOnline = "is_online"
    }
}

struct StationInfo: Codable {
    let name: String
    let shortcode: String?
    let listenURL: String?

    enum CodingKeys: String, CodingKey {
        case name
        case shortcode
        case listenURL = "listen_url"
    }
}

struct NowPlayingTrack: Codable {
    let song: SongInfo?
    let elapsed: Int?
    let duration: Int?
}

struct SongInfo: Codable {
    let title: String
    let artist: String
    let art: String?
    let album: String?
}

struct LiveInfo: Codable {
    let isLive: Bool
    let streamerName: String?

    enum CodingKeys: String, CodingKey {
        case isLive = "is_live"
        case streamerName = "streamer_name"
    }
}
