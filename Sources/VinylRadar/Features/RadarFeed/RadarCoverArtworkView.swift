import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

struct RadarCoverArtworkView: View {
    let imageURL: URL?
    let placeholderSeed: String
    @State private var remoteImageData: Data?

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
            if let renderedImage {
                renderedImage
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
            } else {
                placeholderLayer
            }
        }
        .task(id: imageURL) {
            await loadRemoteImage()
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
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
    }

    private var renderedImage: Image? {
        guard let remoteImageData else {
            return nil
        }
        return image(from: remoteImageData)
    }

    private func loadRemoteImage() async {
        guard let imageURL else {
            await MainActor.run {
                remoteImageData = nil
            }
            return
        }

        await MainActor.run {
            remoteImageData = nil
        }

        let requestedURL = imageURL
        let data = await RadarArtworkLoader.shared.loadData(for: requestedURL)
        await MainActor.run {
            guard imageURL == requestedURL else {
                return
            }
            remoteImageData = data
        }
    }

    private func image(from data: Data) -> Image? {
        #if canImport(UIKit)
        guard let image = UIImage(data: data) else { return nil }
        return Image(uiImage: image)
        #elseif canImport(AppKit)
        guard let image = NSImage(data: data) else { return nil }
        return Image(nsImage: image)
        #else
        return nil
        #endif
    }
}
