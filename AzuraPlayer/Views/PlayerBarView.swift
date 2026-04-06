//
//  PlayerBarView.swift
//  AzuraPlayer
//

import SwiftUI

struct PlayerBarView: View {
    @ObservedObject var player = AudioPlayerService.shared
    @ObservedObject var metadata = MetadataService.shared
    private let accentBlue = Color(red: 0.0, green: 0.48, blue: 1.0)

    var body: some View {
        HStack(spacing: 14) {
            // Cover
            ZStack {
                if let station = player.currentStation,
                   station.showSongArt,
                   let artURL = metadata.currentTrack?.art,
                   let url = URL(string: artURL) {
                    AsyncImage(url: url) { phase in
                        if case .success(let img) = phase {
                            img.resizable().scaledToFill()
                        } else if let data = station.customImageData, let uiImg = UIImage(data: data) {
                            Image(uiImage: uiImg).resizable().scaledToFill()
                        } else {
                            Color.gray.opacity(0.3)
                        }
                    }
                } else if let data = player.currentStation?.customImageData,
                          let uiImg = UIImage(data: data) {
                    Image(uiImage: uiImg).resizable().scaledToFill()
                } else {
                    Color.gray.opacity(0.3)
                        .overlay(Image(systemName: "music.note").foregroundStyle(.secondary))
                }
            }
            .frame(width: 48, height: 48)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .shadow(color: .black.opacity(0.1), radius: 2, y: 1)

            // Infos
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    if player.isBuffering {
                        Text("Verbinde...")
                            .font(.subheadline).bold()
                            .foregroundStyle(.orange)
                    } else if player.isPlaying {
                        // Kleines grünes Punkt-Icon für "Verbunden"
                        Image(systemName: "antenna.radiowaves.left.and.right")
                            .font(.caption2)
                            .foregroundStyle(.green)
                        Text(metadata.currentTrack?.title ?? "Live Stream")
                            .font(.subheadline).bold()
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                    } else {
                        Text(metadata.currentTrack?.title ?? "Pausiert")
                            .font(.subheadline).bold()
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                    }
                }

                Text(metadata.currentTrack?.artist ?? player.currentStation?.displayName ?? "")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            // Play/Pause
            Button {
                player.togglePlayPause()
            } label: {
                Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                    .font(.title3)
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background(accentBlue)
                    .clipShape(Circle())
            }

            // Stop
            Button {
                player.stop()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .frame(width: 36, height: 36)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            Color(UIColor.systemBackground)
                .opacity(0.85)
                .background(.ultraThinMaterial)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.15), radius: 15, y: 8)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
}
