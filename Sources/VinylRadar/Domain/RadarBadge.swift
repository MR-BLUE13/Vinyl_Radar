import Foundation

public enum RadarBadge: String, Codable, CaseIterable, Identifiable, Hashable, Sendable {
    case new = "NEW"
    case limited = "LIMITED"
    case colored = "COLORED"
    case exclusive = "EXCLUSIVE"

    public var id: String { rawValue }

    var priority: Int {
        switch self {
        case .new:
            return 0
        case .exclusive:
            return 1
        case .limited:
            return 2
        case .colored:
            return 3
        }
    }
}
