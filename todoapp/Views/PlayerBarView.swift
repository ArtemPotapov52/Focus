import SwiftUI

struct PlayerBarView: View {
    @Bindable var music: MusicManager

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 10) {
                if let art = music.artwork {
                    art
                        .resizable()
                        .frame(width: 44, height: 44)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.white.opacity(0.15))
                        .frame(width: 44, height: 44)
                        .overlay(
                            Image(systemName: "music.note")
                                .foregroundColor(.white.opacity(0.5))
                        )
                }

                VStack(alignment: .leading, spacing: 1) {
                    if let t = music.title {
                        Text(t)
                            .font(.subheadline.bold())
                            .foregroundColor(.white)
                            .lineLimit(1)
                    } else if music.hasContent {
                        Text("Сейчас играет")
                            .font(.subheadline.bold())
                            .foregroundColor(.white.opacity(0.7))
                            .lineLimit(1)
                    } else {
                        Text("Не играет")
                            .font(.subheadline.bold())
                            .foregroundColor(.white.opacity(0.5))
                            .lineLimit(1)
                    }
                    if let artist = music.artist {
                        Text(artist)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                            .lineLimit(1)
                    }
                }

                Spacer()
            }

            if music.hasContent && music.duration > 0 {
                HStack(spacing: 8) {
                    Text(music.currentTimeString)
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.5))
                        .monospacedDigit()

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(.white.opacity(0.2))
                                .frame(height: 4)
                            Capsule()
                                .fill(.white)
                                .frame(width: geo.size.width * music.progress, height: 4)
                        }
                    }
                    .frame(height: 4)

                    Text(music.durationString)
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.5))
                        .monospacedDigit()
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial.opacity(0.2))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .padding(.horizontal, 12)
        .padding(.top, 50)
    }
}
