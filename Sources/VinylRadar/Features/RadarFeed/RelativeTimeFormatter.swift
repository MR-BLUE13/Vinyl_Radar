import Foundation

public struct RelativeTimeFormatter: Sendable {
    public init() {}

    public func string(since date: Date, reference: Date = Date()) -> String {
        let seconds = max(0, Int(reference.timeIntervalSince(date)))

        if seconds < 60 {
            return "刚刚"
        }

        let minutes = seconds / 60
        if minutes < 60 {
            return "\(minutes)分钟前"
        }

        let hours = minutes / 60
        if hours < 24 {
            return "\(hours)小时前"
        }

        let days = hours / 24
        return "\(days)天前"
    }
}
