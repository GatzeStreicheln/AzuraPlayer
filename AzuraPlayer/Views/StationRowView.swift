//
//  StationRowView.swift
//  AzuraPlayer
//

import SwiftUI

struct StationRowView: View {
    let station: RadioStation
    let isPlaying: Bool
    let isBuffering: Bool

    @StateObject private var metadata = MetadataService.shared
    @EnvironmentObject var player: AudioPlayerService

    var body: some View {
        HStack(spacing: 14) {
            // Cover in der Liste
            ZStack {
                // Szenario B & D: Custom Cover vorhanden -> Immer anzeigen in der Liste
                if let data = station.customImageData,
                   let uiImg = UIImage(data: data) {
                    Image(uiImage: uiImg)
                        .resizable()
                        .scaledToFill()
                }
                // Szenario A & C: Kein Custom Cover -> Immer Platzhalter
                else {
                    placeholderIcon
                }
            }
            .frame(width: 56, height: 56)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isPlaying ? Color.accentColor : Color.clear, lineWidth: 2)
            )

            // Name & Status
            VStack(alignment: .leading, spacing: 4) {
                Text(station.displayName)
                    .font(.headline)
                    .foregroundStyle(.primary)

                if isPlaying {
                    if isBuffering {
                        Label("Verbinde...", systemImage: "wifi.exclamationmark")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    } else if let track = metadata.currentTrack {
                        Text("\(track.artist) – \(track.title)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    } else {
                        Label("Live", systemImage: "antenna.radiowaves.left.and.right")
                            .font(.caption)
                            .foregroundStyle(.green)
                    }
                } else {
                    Text(station.streamURL)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            if isPlaying && !isBuffering {
                Image(systemName: "waveform")
                    .foregroundStyle(Color.accentColor)
                    .symbolEffect(.variableColor.iterative)
            }
        }
        .padding(.vertical, 4)
    }

    private var placeholderIcon: some View {
        ZStack {
            Color.secondary.opacity(0.2)
            Image(systemName: "radio")
                .font(.title2)
                .foregroundStyle(.secondary)
        }
    }
}
