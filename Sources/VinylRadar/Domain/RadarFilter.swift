import Foundation

public enum RadarQuickFilter: String, CaseIterable, Identifiable, Sendable {
    case all
    case limited
    case colored
    case exclusive
    case saved

    public var id: String { rawValue }

    public var displayTitle: String {
        switch self {
        case .all:
            return "全部"
        case .limited:
            return "限量"
        case .colored:
            return "彩胶"
        case .exclusive:
            return "独家"
        case .saved:
            return "已收藏"
        }
    }
}
