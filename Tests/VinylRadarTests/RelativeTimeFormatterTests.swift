import Foundation
import Testing
@testable import VinylRadar

@Suite("RelativeTimeFormatterTests")
struct RelativeTimeFormatterTests {
    private let formatter = RelativeTimeFormatter()
    private let reference = Date(timeIntervalSince1970: 1_700_000_000)

    @Test("just now")
    func justNow() {
        let date = reference.addingTimeInterval(-15)
        #expect(formatter.string(since: date, reference: reference) == "刚刚")
    }

    @Test("minutes")
    func minutes() {
        let date = reference.addingTimeInterval(-8 * 60)
        #expect(formatter.string(since: date, reference: reference) == "8分钟前")
    }

    @Test("hours")
    func hours() {
        let date = reference.addingTimeInterval(-3 * 3600)
        #expect(formatter.string(since: date, reference: reference) == "3小时前")
    }

    @Test("days")
    func days() {
        let date = reference.addingTimeInterval(-2 * 86_400)
        #expect(formatter.string(since: date, reference: reference) == "2天前")
    }
}
