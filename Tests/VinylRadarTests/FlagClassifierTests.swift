import Foundation
import Testing
@testable import VinylRadar

@Suite("FlagClassifierTests")
struct FlagClassifierTests {
    @Test("classifies limited colored and exclusive by keywords")
    func keywordClassification() {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let firstSeen = now.addingTimeInterval(-2 * 60 * 60)

        let flags = FeedFlagClassifier.classify(
            title: "Store Exclusive Limited Marble Pressing",
            subtitle: "Only 500 copies",
            firstSeenAt: firstSeen,
            now: now
        )

        #expect(flags.contains(.isExclusive))
        #expect(flags.contains(.isLimited))
        #expect(flags.contains(.isColored))
        #expect(flags.contains(.isNew))
    }

    @Test("new flag expires after 72h")
    func newExpiry() {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let firstSeen = now.addingTimeInterval(-(73 * 60 * 60))

        let flags = FeedFlagClassifier.classify(
            title: "Limited Edition",
            firstSeenAt: firstSeen,
            now: now
        )

        #expect(flags.contains(.isLimited))
        #expect(!flags.contains(.isNew))
    }
}
