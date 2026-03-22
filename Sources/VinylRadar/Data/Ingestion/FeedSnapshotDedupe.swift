import Foundation

public enum FeedSnapshotDedupe {
    public static func dedupeWithinStore(_ releases: [ReleaseDrop]) -> [ReleaseDrop] {
        var bestByKey: [DedupeKey: ReleaseDrop] = [:]

        for release in releases {
            let key = DedupeKey(storeID: release.storeID, sourceItemKey: release.sourceItemKey)
            guard let existing = bestByKey[key] else {
                bestByKey[key] = release
                continue
            }

            if release.publishedAt > existing.publishedAt {
                bestByKey[key] = release
            }
        }

        return bestByKey.values.sorted(by: RadarFeedMapper.sortRule)
    }
}

private struct DedupeKey: Hashable {
    let storeID: String
    let sourceItemKey: String
}
