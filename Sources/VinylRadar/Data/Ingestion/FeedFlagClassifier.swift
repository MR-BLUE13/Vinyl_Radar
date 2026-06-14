import Foundation

public enum FeedFlagClassifier {
    public static func classify(title: String, subtitle: String? = nil, firstSeenAt: Date, now: Date) -> ReleaseFlags {
        let normalized = [title, subtitle]
            .compactMap { $0?.lowercased() }
            .joined(separator: " ")

        var flags: ReleaseFlags = []

        if Self.containsAny(normalized, keywords: [
            "limited",
            "copies",
            "numbered",
        ]) {
            flags.insert(.isLimited)
        }

        if Self.containsAny(normalized, keywords: [
            "colored",
            "coloured",
            "splatter",
            "clear",
            "marble",
        ]) {
            flags.insert(.isColored)
        }

        if Self.containsAny(normalized, keywords: [
            "exclusive",
            "store exclusive",
        ]) {
            flags.insert(.isExclusive)
        }

        if Self.containsAny(normalized.replacingOccurrences(of: "unsigned", with: ""), keywords: [
            "signed",
            "personally signed",
            "autographed",
            "hand-signed",
            "signature",
            "signed print",
            "签名",
            "亲签",
        ]) {
            flags.insert(.isSigned)
        }

        if now.timeIntervalSince(firstSeenAt) <= 72 * 60 * 60 {
            flags.insert(.isNew)
        }

        return flags
    }

    private static func containsAny(_ normalizedText: String, keywords: [String]) -> Bool {
        keywords.contains { normalizedText.contains($0) }
    }
}
