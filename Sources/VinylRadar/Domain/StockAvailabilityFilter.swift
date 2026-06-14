import Foundation

public enum StockAvailabilityFilter: String, CaseIterable, Identifiable, Sendable {
    case all
    case inStock

    public var id: String { rawValue }

    public var displayTitle: String {
        switch self {
        case .all:
            return "全部"
        case .inStock:
            return "有货"
        }
    }
}
