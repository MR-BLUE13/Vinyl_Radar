import SwiftUI

struct ReleaseDetailView: View {
    let item: RadarFeedItemViewData

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: RadarSpacing.lg) {
                ReleaseRadarCard(
                    item: item,
                    onToggleSaved: {},
                    onTap: {}
                )
                .allowsHitTesting(false)

                VStack(alignment: .leading, spacing: RadarSpacing.sm) {
                    Text("详情页骨架")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(RadarColor.textPrimary)

                    Text("一期先保留结构，用于承接卡片点击。二期可在这里扩展发售渠道、价格、版本差异和收藏动作。")
                        .font(.subheadline)
                        .foregroundStyle(RadarColor.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)

                    Divider()
                        .overlay(RadarColor.textSecondary.opacity(0.3))

                    Label(item.sourceName, systemImage: "record.circle")
                        .font(.subheadline)
                        .foregroundStyle(RadarColor.textPrimary)

                    Label(item.publishedAtText, systemImage: "clock")
                        .font(.subheadline)
                        .foregroundStyle(RadarColor.textSecondary)

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
            .padding(RadarSpacing.md)
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
                isSaved: false
            )
        )
    }
    .preferredColorScheme(.dark)
}
