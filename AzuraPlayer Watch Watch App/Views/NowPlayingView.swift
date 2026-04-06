import SwiftUI

struct NowPlayingView: View {
    @EnvironmentObject var player: WatchNowPlayingManager
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 8) {

                // Cover (Song-Art wenn verfügbar, sonst Sender-Custom-Image, sonst Platzhalter)
                Group {
                    if let urlString = player.artworkURL, let url = URL(string: urlString) {
                        AsyncImage(url: url) { phase in
                            if case .success(let img) = phase {
                                img.resizable().scaledToFill()
                            } else {
                                placeholderIcon
                            }
                        }
                    } else {
                        placeholderIcon
                    }
                }
                .frame(width: 70, height: 70)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(radius: 4)

                // Sendername
                Text(player.currentStation?.displayName ?? "")
                    .font(.footnote.weight(.bold))
                    .lineLimit(1)
                    .foregroundStyle(.primary)

                // Titel
                Text(player.songTitle.isEmpty ? "Titel unbekannt" : player.songTitle)
                    .font(.caption2.weight(.semibold))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .foregroundStyle(.primary)

                // Künstler
                if !player.artistName.isEmpty {
                    Text(player.artistName)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                // Steuerung: Pause + Stop
                HStack(spacing: 16) {
                    // Pause / Play
                    Button {
                        player.togglePlayPause()
                    } label: {
                        Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                            .font(.title3)
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                            .background(Color.blue)
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)

                    // Stop
                    Button {
                        player.stop()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.title3)
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                            .background(Color.gray.opacity(0.6))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top, 4)
            }
            .padding(.horizontal, 4)
            .padding(.bottom, 8)
        }
        .navigationTitle("Now Playing")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var placeholderIcon: some View {
        ZStack {
            Color.gray.opacity(0.2)
            Image(systemName: "music.note.house")
                .font(.title2)
                .foregroundStyle(.secondary)
        }
    }
}
