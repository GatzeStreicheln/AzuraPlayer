import SwiftUI
import WatchKit

struct NowPlayingView: View {
    @EnvironmentObject var player: WatchNowPlayingManager
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 8) {

            // Cover mit Status-Badge
            ZStack(alignment: .bottomTrailing) {
                Group {
                    if let img = player.artworkImage {
                        Image(uiImage: img).resizable().scaledToFill()
                    } else if let station = player.currentStation,
                              let data = station.customImageData,
                              let uiImg = UIImage(data: data) {
                        Image(uiImage: uiImg).resizable().scaledToFill()
                    } else {
                        ZStack {
                            Color.gray.opacity(0.2)
                            Image(systemName: "music.note.house")
                                .font(.title2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .frame(width: 64, height: 64)
                .clipShape(RoundedRectangle(cornerRadius: 12))

                // Status-Badge: grün wenn Stream läuft, orange wenn verbindet
                if player.isPlaying {
                    Group {
                        if player.isStreaming {
                            Text("LIVE")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(Color.green)
                                .clipShape(Capsule())
                        } else {
                            Text("…")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(Color.orange)
                                .clipShape(Capsule())
                        }
                    }
                    .offset(x: 2, y: 4)
                }
            }
            .shadow(radius: 3)

            // Sendername
            Text(player.currentStation?.displayName ?? "")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
                .lineLimit(1)

            // Titel · Künstler
            let title = player.songTitle.isEmpty ? "Unbekannt" : player.songTitle
            let artist = player.artistName
            let combined = artist.isEmpty ? title : "\(title) · \(artist)"

            MarqueeText(text: combined, font: .footnote.weight(.medium))
                .foregroundStyle(.primary)

            Spacer(minLength: 0)

            // Controls
            HStack(spacing: 22) {
                Button {
                    player.togglePlayPause()
                } label: {
                    Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(width: 50, height: 50)
                        .background(Color.blue)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)

                Button {
                    player.stop()
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(width: 40, height: 40)
                        .background(Color.gray.opacity(0.5))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 6)
        .padding(.top, 4)
        .padding(.bottom, 8)
        .navigationTitle("")
        // Unsichtbarer VolumeControl – bindet Digital Crown an System-Lautstärke
        .background {
            VolumeControl()
                .frame(width: 1, height: 1)
                .opacity(0)
                .allowsHitTesting(false)
        }
    }
}

// MARK: - Volume Control (Digital Crown → System-Lautstärke)

private struct VolumeControl: WKInterfaceObjectRepresentable {
    typealias WKInterfaceObjectType = WKInterfaceVolumeControl

    func makeWKInterfaceObject(context: Context) -> WKInterfaceVolumeControl {
        WKInterfaceVolumeControl(origin: .local)
    }

    func updateWKInterfaceObject(_ control: WKInterfaceVolumeControl, context: Context) {
        control.focus()
    }
}

// MARK: - Marquee Text

private struct MarqueeText: View {
    let text: String
    let font: Font

    @State private var offset: CGFloat = 0
    @State private var containerWidth: CGFloat = 0
    @State private var isReturning: Bool = false
    @State private var scrollTask: Task<Void, Never>?

    private var textWidth: CGFloat {
        let uiFont = UIFont.preferredFont(forTextStyle: .footnote)
        return ceil((text as NSString).size(withAttributes: [.font: uiFont]).width)
    }

    private var needsScroll: Bool {
        containerWidth > 0 && textWidth > containerWidth
    }

    private var scrollDistance: CGFloat {
        textWidth - containerWidth + 10
    }

    private var scrollDuration: Double {
        max(Double(scrollDistance) / 28.0, 1.5)
    }

    var body: some View {
        Color.clear
            .frame(height: 18)
            .overlay(alignment: .leading) {
                Text(text)
                    .font(font)
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
                    .offset(x: needsScroll ? offset : max(0, (containerWidth - textWidth) / 2))
                    .animation(
                        isReturning
                            ? .linear(duration: 0.3)
                            : .linear(duration: scrollDuration),
                        value: offset
                    )
            }
            .clipped()
            .opacity(containerWidth > 0 ? 1 : 0)
            .background(
                GeometryReader { geo in
                    Color.clear
                        .onAppear {
                            containerWidth = geo.size.width
                            startScrollIfNeeded()
                        }
                        .onChange(of: geo.size.width) { _, w in
                            containerWidth = w
                            startScrollIfNeeded()
                        }
                }
            )
            .onChange(of: text) { _, _ in
                scrollTask?.cancel()
                offset = 0
                startScrollIfNeeded()
            }
            .onDisappear { scrollTask?.cancel() }
    }

    private func startScrollIfNeeded() {
        scrollTask?.cancel()
        offset = 0
        isReturning = false
        guard needsScroll else { return }

        let dist = scrollDistance
        let dur = scrollDuration

        scrollTask = Task { @MainActor in
            do {
                try await Task.sleep(for: .seconds(2))
                while !Task.isCancelled {
                    isReturning = false
                    offset = -dist
                    try await Task.sleep(for: .seconds(dur + 1.5))
                    guard !Task.isCancelled else { break }
                    isReturning = true
                    offset = 0
                    try await Task.sleep(for: .seconds(0.3 + 2.0))
                }
            } catch {}
        }
    }
}
