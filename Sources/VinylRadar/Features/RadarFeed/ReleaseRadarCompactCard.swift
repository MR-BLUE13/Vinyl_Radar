import SwiftUI

struct ReleaseRadarCompactCard: View {
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
                HStack(spacing: RadarSpacing.sm) {
                    RadarCoverArtworkView(
                        imageURL: item.coverImageURL,
                        placeholderSeed: item.coverAssetName ?? item.id
                    )
                        .frame(width: 92, height: 92)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                    VStack(alignment: .leading, spacing: 7) {
                        Text(item.artist)
                            .font(RadarTypography.artist)
                            .foregroundStyle(RadarColor.textPrimary)
                            .lineLimit(1)

                        Text(item.title)
                            .font(RadarTypography.release)
                            .foregroundStyle(RadarColor.textPrimary.opacity(0.92))
                            .lineLimit(2)

                        Text("\(item.sourceName) · \(item.publishedAtText)")
                            .font(RadarTypography.meta)
                            .foregroundStyle(RadarColor.textSecondary)
                            .lineLimit(1)

                        HStack(spacing: RadarSpacing.xs) {
                            ForEach(visibleBadges) { badge in
                                CompactBadgePill(badge: badge)
                            }

                            if hiddenBadgeCount > 0 {
                                Text("+\(hiddenBadgeCount)")
                                    .font(RadarTypography.badge)
                                    .foregroundStyle(RadarColor.textSecondary)
                            }
                        }
                    }

                    Spacer(minLength: 0)
                }
                .padding(RadarSpacing.sm)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: RadarRadius.card, style: .continuous)
                        .fill(RadarColor.surfaceCard.opacity(0.88))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: RadarRadius.card, style: .continuous)
                        .stroke(Color.white.opacity(0.07), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.18), radius: 8, x: 0, y: 6)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("release_compact_card_\(item.id)")

            Button(action: onToggleSaved) {
                Image(systemName: item.isSaved ? "bookmark.fill" : "bookmark")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(item.isSaved ? RadarColor.accentExclusive : RadarColor.textSecondary)
                    .padding(8)
                    .background(RadarColor.backgroundSecondary.opacity(0.95), in: Circle())
            }
            .buttonStyle(.plain)
            .padding(.top, 10)
            .padding(.trailing, 10)
            .accessibilityIdentifier("save_compact_\(item.id)")
        }
    }
}

private struct CompactBadgePill: View {
    let badge: RadarBadge

    var body: some View {
        Text(badge.rawValue)
            .font(RadarTypography.badge)
            .foregroundStyle(Color.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(
                RoundedRectangle(cornerRadius: RadarRadius.badge, style: .continuous)
                    .fill(RadarColor.badgeColor(badge))
            )
    }
}

#Preview {
    ReleaseRadarCompactCard(
        item: .init(
            id: "compact-preview",
            artist: "Kite Harbor",
            title: "Blue Pressing Archive Edition",
            coverAssetName: "cover_03",
            storeID: "store_banquet_records",
            sourceName: "Banquet Records",
            publishedAtText: "刚刚",
            publishedAt: .now,
            badges: [.exclusive, .limited, .colored],
            isSaved: true
        ),
        onToggleSaved: {},
        onTap: {}
    )
    .padding()
    .background(RadarColor.backgroundPrimary)
    .preferredColorScheme(.dark)
}
