import Foundation

public enum FeedCardLayout: String, CaseIterable, Identifiable, Sendable {
    case large
    case compact

    public var id: String { rawValue }

    var toggleIconName: String {
        switch self {
        case .large:
            return "list.bullet"
        case .compact:
            return "rectangle"
        }
    }

    var toggleAccessibilityLabel: String {
        switch self {
        case .large:
            return "切换到列表卡"
        case .compact:
            return "切换到大卡"
        }
    }
}
