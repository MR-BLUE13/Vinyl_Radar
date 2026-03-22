import SwiftUI

struct ReleaseRadarCard: View {
    let item: RadarFeedItemViewData
    let onToggleSaved: () -> Void
    let onTap: () -> Void

    private var visibleBadges: [RadarBadge] {
        Array(item.badges.prefix(2))
    }

    private var hiddenBadgeCount: Int {
        max(0, item.badges.count - visibleBadges.count)
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Button(action: onTap) {
                ZStack {
                    RadarCoverArtworkView(
                        imageURL: item.coverImageURL,
                        placeholderSeed: item.coverAssetName ?? item.id
                    )

                    RoundedRectangle(cornerRadius: RadarRadius.card, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.clear,
                                    RadarColor.overlaySoft,
                                    RadarColor.overlayStrong,
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )

                    VStack(alignment: .leading, spacing: RadarSpacing.sm) {
                        HStack(alignment: .top) {
                            HStack(spacing: RadarSpacing.xs) {
                                ForEach(visibleBadges) { badge in
                                    BadgePill(badge: badge)
                                }

                                if hiddenBadgeCount > 0 {
                                    Text("+\(hiddenBadgeCount)")
                                        .font(RadarTypography.badge)
                                        .foregroundStyle(RadarColor.textPrimary)
                                        .padding(.horizontal, RadarSpacing.xs)
                                        .padding(.vertical, 5)
                                        .background(
                                            RoundedRectangle(cornerRadius: RadarRadius.badge, style: .continuous)
                                                .fill(Color.black.opacity(0.35))
                                        )
                                }
                            }
                            Spacer(minLength: 0)
                        }

                        Spacer(minLength: RadarSpacing.md)

                        VStack(alignment: .leading, spacing: RadarSpacing.xs) {
                            Text(item.artist)
                                .font(RadarTypography.artist)
                                .foregroundStyle(Color.white)
                                .lineLimit(2)
                                .shadow(color: Color.black.opacity(0.45), radius: 3, x: 0, y: 1)

                            Text(item.title)
                                .font(RadarTypography.release)
                                .foregroundStyle(Color.white.opacity(0.93))
                                .lineLimit(2)
                                .shadow(color: Color.black.opacity(0.4), radius: 3, x: 0, y: 1)

                            Text("\(item.sourceName) · \(item.publishedAtText)")
                                .font(RadarTypography.meta)
                                .foregroundStyle(Color.white.opacity(0.82))
                                .lineLimit(1)
                        }
                    }
                    .padding(RadarSpacing.md)
                }
                .frame(maxWidth: .infinity)
                .aspectRatio(0.78, contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: RadarRadius.card, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: RadarRadius.card, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 8)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("release_card_\(item.id)")

            Button(action: onToggleSaved) {
                Image(systemName: item.isSaved ? "bookmark.fill" : "bookmark")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(item.isSaved ? RadarColor.accentExclusive : Color.white.opacity(0.9))
                    .padding(10)
                    .background(.ultraThinMaterial, in: Circle())
            }
            .buttonStyle(.plain)
            .padding(RadarSpacing.sm)
            .accessibilityIdentifier("save_\(item.id)")
        }
    }
}

private struct BadgePill: View {
    let badge: RadarBadge

    var body: some View {
        Text(badge.rawValue)
            .font(RadarTypography.badge)
            .foregroundStyle(Color.white)
            .padding(.horizontal, RadarSpacing.xs)
            .padding(.vertical, 5)
            .background(
                RoundedRectangle(cornerRadius: RadarRadius.badge, style: .continuous)
                    .fill(RadarColor.badgeColor(badge))
            )
    }
}

#Preview {
    ReleaseRadarCard(
        item: .init(
            id: "preview",
            artist: "Nala Sine Quartet",
            title: "Shadow Pressing (Limited Red Marble Edition)",
            coverAssetName: "cover_01",
            storeID: "store_blood_records",
            sourceName: "Blood Records",
            publishedAtText: "12分钟前",
            publishedAt: .now,
            badges: [.new, .limited, .colored],
            isSaved: false
        ),
        onToggleSaved: {},
        onTap: {}
    )
    .padding()
    .background(RadarColor.backgroundPrimary)
    .preferredColorScheme(.dark)
}
