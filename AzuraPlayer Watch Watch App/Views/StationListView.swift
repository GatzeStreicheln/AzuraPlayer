import SwiftUI

struct StationListView: View {
    @EnvironmentObject var store: WatchStationStore
    @EnvironmentObject var player: WatchNowPlayingManager

    var body: some View {
        NavigationStack {
            List {
                ForEach(store.stations) { station in
                    StationRowView(station: station)
                }

                // Now Playing Button – nur sichtbar wenn etwas spielt
                if player.currentStation != nil {
                    NavigationLink(destination: NowPlayingView()) {
                        HStack(spacing: 10) {
                            Image(systemName: player.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                                .font(.title3)
                                .foregroundStyle(player.isPlaying ? .blue : .secondary)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Now Playing")
                                    .font(.footnote.weight(.semibold))
                                if !player.songTitle.isEmpty {
                                    Text(player.songTitle)
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Sender")
            .overlay {
                if store.stations.isEmpty {
                    ContentUnavailableView(
                        "Keine Sender",
                        systemImage: "radio",
                        description: Text("Sender in der iPhone-App hinzufügen")
                    )
                }
            }
        }
    }
}
