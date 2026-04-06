import SwiftUI

struct StationRowView: View {
    let station: RadioStation
    @EnvironmentObject var player: WatchNowPlayingManager

    var isCurrent: Bool { player.currentStation?.id == station.id }
    var isPlaying: Bool { isCurrent && player.isPlaying }

    var body: some View {
        Button {
            if isPlaying {
                player.stop()
            } else {
                player.play(station: station)
            }
        } label: {
            HStack(spacing: 10) {
                Group {
                    if let data = station.customImageData,
                       let uiImage = UIImage(data: data) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                    } else {
                        Image(systemName: "radio")
                            .font(.title3)
                            .foregroundStyle(.blue)
                    }
                }
                .frame(width: 36, height: 36)
                .clipShape(RoundedRectangle(cornerRadius: 8))

                Text(station.displayName)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)

                Spacer()

                // Spielt → roter Stop   |   Pausiert → gedimmter Pause-Indikator
                if isPlaying {
                    Image(systemName: "stop.fill")
                        .font(.caption)
                        .foregroundStyle(.red)
                } else if isCurrent {
                    Image(systemName: "pause.fill")
                        .font(.caption)
                        .foregroundStyle(.blue.opacity(0.7))
                }
            }
        }
        .buttonStyle(.plain)
    }
}
