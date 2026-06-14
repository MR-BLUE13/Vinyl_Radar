import Foundation

struct StoreFilterOption: Identifiable, Equatable {
    let id: String
    let name: String
    let totalCount: Int
    let inStockCount: Int
    let isSelected: Bool

    func displayCount(for stockFilter: StockAvailabilityFilter) -> Int {
        switch stockFilter {
        case .all:
            return totalCount
        case .inStock:
            return inStockCount
        }
    }
}
