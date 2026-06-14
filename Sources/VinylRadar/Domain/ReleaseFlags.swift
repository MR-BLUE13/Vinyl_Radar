import Foundation

public struct ReleaseFlags: OptionSet, Codable, Hashable, Sendable {
    public let rawValue: Int

    public static let isNew = ReleaseFlags(rawValue: 1 << 0)
    public static let isLimited = ReleaseFlags(rawValue: 1 << 1)
    public static let isColored = ReleaseFlags(rawValue: 1 << 2)
    public static let isExclusive = ReleaseFlags(rawValue: 1 << 3)
    public static let isSigned = ReleaseFlags(rawValue: 1 << 4)

    public static let none: ReleaseFlags = []

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    var badges: [RadarBadge] {
        var result: [RadarBadge] = []
        if contains(.isNew) {
            result.append(.new)
        }
        if contains(.isExclusive) {
            result.append(.exclusive)
        }
        if contains(.isLimited) {
            result.append(.limited)
        }
        return result
    }

    var rarityScore: Int {
        var score = 0
        if contains(.isNew) {
            score += 8
        }
        if contains(.isExclusive) {
            score += 4
        }
        if contains(.isLimited) {
            score += 2
        }
        if contains(.isColored) {
            score += 1
        }
        return score
    }

    public init(from decoder: Decoder) throws {
        if let rawValue = try? decoder.singleValueContainer().decode(Int.self) {
            self.init(rawValue: rawValue)
            return
        }

        let values = try decoder.singleValueContainer().decode([String].self)
        var flags: ReleaseFlags = []

        for value in values {
            switch value.uppercased() {
            case RadarBadge.new.rawValue:
                flags.insert(.isNew)
            case RadarBadge.limited.rawValue:
                flags.insert(.isLimited)
            case RadarBadge.colored.rawValue:
                flags.insert(.isColored)
            case RadarBadge.exclusive.rawValue:
                flags.insert(.isExclusive)
            case "SIGNED":
                flags.insert(.isSigned)
            default:
                continue
            }
        }

        self = flags
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(apiValues)
    }

    private var apiValues: [String] {
        var values: [String] = []
        if contains(.isNew) {
            values.append(RadarBadge.new.rawValue)
        }
        if contains(.isExclusive) {
            values.append(RadarBadge.exclusive.rawValue)
        }
        if contains(.isLimited) {
            values.append(RadarBadge.limited.rawValue)
        }
        if contains(.isColored) {
            values.append(RadarBadge.colored.rawValue)
        }
        if contains(.isSigned) {
            values.append("SIGNED")
        }
        return values
    }
}
