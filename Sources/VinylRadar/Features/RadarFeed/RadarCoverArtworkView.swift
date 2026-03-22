import SwiftUI

struct RadarCoverArtworkView: View {
    let imageURL: URL?
    let placeholderSeed: String

    private var palette: [Color] {
        let gradients: [[Color]] = [
            [Color(hex: 0x1B1327), Color(hex: 0x6D3040), Color(hex: 0xC08A45)],
            [Color(hex: 0x0F2530), Color(hex: 0x245267), Color(hex: 0xB0844C)],
            [Color(hex: 0x1F1C17), Color(hex: 0x574233), Color(hex: 0xA77451)],
            [Color(hex: 0x25131B), Color(hex: 0x6B2E4C), Color(hex: 0xD08E5A)],
            [Color(hex: 0x161D27), Color(hex: 0x30485D), Color(hex: 0x8895A6)],
            [Color(hex: 0x191B1D), Color(hex: 0x495058), Color(hex: 0x9B7A4F)],
            [Color(hex: 0x141416), Color(hex: 0x3E2833), Color(hex: 0x7A4A57)],
            [Color(hex: 0x1D1A17), Color(hex: 0x564437), Color(hex: 0xB48E68)],
        ]
        let index = abs(placeholderSeed.hashValue) % gradients.count
        return gradients[index]
    }

    var body: some View {
        Group {
            if let imageURL {
                AsyncImage(url: imageURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .empty:
                        placeholderLayer
                    case .failure:
                        placeholderLayer
                    @unknown default:
                        placeholderLayer
                    }
                }
            } else {
                placeholderLayer
            }
        }
    }

    private var placeholderLayer: some View {
        ZStack {
            LinearGradient(colors: palette, startPoint: .topLeading, endPoint: .bottomTrailing)

            Circle()
                .stroke(Color.white.opacity(0.18), lineWidth: 1)
                .padding(42)

            Circle()
                .stroke(Color.black.opacity(0.2), lineWidth: 16)
                .padding(62)
                .blur(radius: 0.5)

            Circle()
                .fill(Color.black.opacity(0.2))
                .frame(width: 34, height: 34)

            Circle()
                .fill(Color.white.opacity(0.45))
                .frame(width: 8, height: 8)
        }
    }
}
