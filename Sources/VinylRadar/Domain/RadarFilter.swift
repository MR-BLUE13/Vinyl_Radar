import Foundation

public enum RadarQuickFilter: String, CaseIterable, Identifiable, Sendable {
    case all
    case exclusive
    case signed
    case saved

    public var id: String { rawValue }

    public var displayTitle: String {
        switch self {
        case .all:
            return "全部"
        case .exclusive:
            return "独家"
        case .signed:
            return "带签名"
        case .saved:
            return "已收藏"
        }
    }
}
