import SwiftUI

struct ReleaseDetailView: View {
    let item: RadarFeedItemViewData

    var body: some View {
        GeometryReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: RadarSpacing.lg) {
                    ReleaseRadarCard(
                        item: item,
                        onToggleSaved: {},
                        onTap: {}
                    )
                    .allowsHitTesting(false)

                    VStack(alignment: .leading, spacing: RadarSpacing.sm) {
                        Text("发售信息")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(RadarColor.textPrimary)

                        if let description = item.description, !description.isEmpty {
                            Text(description)
                                .font(.subheadline)
                                .foregroundStyle(RadarColor.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        } else {
                            Text("暂无描述，点击查看来源")
                                .font(.subheadline)
                                .foregroundStyle(RadarColor.textSecondary)
                        }

                        Divider()
                            .overlay(RadarColor.textSecondary.opacity(0.3))

                        Label(item.sourceName, systemImage: "record.circle")
                            .font(.subheadline)
                            .foregroundStyle(RadarColor.textPrimary)

                        if item.isSoldOut {
                            Text("已售罄")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(RadarColor.textSecondary)
                                .padding(.horizontal, RadarSpacing.xs)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule(style: .continuous)
                                        .fill(RadarColor.backgroundSecondary.opacity(0.9))
                                )
                        }

                        if let sourceItemURL = item.sourceItemURL {
                            Link(destination: sourceItemURL) {
                                Label("查看来源", systemImage: "arrow.up.right")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(RadarColor.textPrimary)
                            }
                        }
                    }
                    .padding(RadarSpacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: RadarRadius.card, style: .continuous)
                            .fill(RadarColor.surfaceCard.opacity(0.8))
                    )
                }
                .frame(width: max(proxy.size.width - RadarSpacing.md * 2, 0), alignment: .leading)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, RadarSpacing.md)
            }
        }
        .background(RadarColor.backgroundPrimary.ignoresSafeArea())
        .navigationTitle("Release")
    }
}

#Preview {
    NavigationStack {
        ReleaseDetailView(
            item: .init(
                id: "preview",
                artist: "Kite Harbor",
                title: "Blue Pressing",
                coverAssetName: "cover_03",
                storeID: "store_banquet_records",
                sourceName: "Banquet Records",
                publishedAtText: "刚刚",
                publishedAt: .now,
                badges: [.new, .colored],
                isSaved: false,
                description: "Banquet 独家彩胶版本，180g 压片，附带折页歌词内页，数量有限。"
            )
        )
    }
    .preferredColorScheme(.dark)
}
