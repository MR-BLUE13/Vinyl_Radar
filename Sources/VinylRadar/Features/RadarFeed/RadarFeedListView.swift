import SwiftUI

struct RadarFeedListView: View {
    let layout: FeedCardLayout
    let items: [RadarFeedItemViewData]
    let onToggleSaved: (String) -> Void
    let onSelect: (RadarFeedItemViewData) -> Void

    var body: some View {
        LazyVStack(spacing: layout == .large ? RadarSpacing.lg : RadarSpacing.sm) {
            ForEach(items) { item in
                switch layout {
                case .large:
                    ReleaseRadarCard(
                        item: item,
                        onToggleSaved: { onToggleSaved(item.id) },
                        onTap: { onSelect(item) }
                    )
                case .compact:
                    ReleaseRadarCompactCard(
                        item: item,
                        onToggleSaved: { onToggleSaved(item.id) },
                        onTap: { onSelect(item) }
                    )
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .animation(.easeInOut(duration: 0.18), value: layout)
    }
}

#Preview("Large") {
    ScrollView {
        RadarFeedListView(
            layout: .large,
            items: [
                .init(
                    id: "1",
                    artist: "Aerial Dust",
                    title: "Night Pressing",
                    coverAssetName: "cover_01",
                    storeID: "store_blood_records",
                    sourceName: "Blood Records",
                    publishedAtText: "8分钟前",
                    publishedAt: .now,
                    badges: [.new, .exclusive, .limited],
                    isSaved: true
                ),
            ],
            onToggleSaved: { _ in },
            onSelect: { _ in }
        )
        .padding()
    }
    .background(RadarColor.backgroundPrimary)
    .preferredColorScheme(.dark)
}

#Preview("Compact") {
    ScrollView {
        RadarFeedListView(
            layout: .compact,
            items: [
                .init(
                    id: "1",
                    artist: "Aerial Dust",
                    title: "Night Pressing",
                    coverAssetName: "cover_01",
                    storeID: "store_blood_records",
                    sourceName: "Blood Records",
                    publishedAtText: "8分钟前",
                    publishedAt: .now,
                    badges: [.new, .exclusive, .limited],
                    isSaved: true
                ),
            ],
            onToggleSaved: { _ in },
            onSelect: { _ in }
        )
        .padding()
    }
    .background(RadarColor.backgroundPrimary)
    .preferredColorScheme(.dark)
}
