import Foundation

public enum RadarSource: String, CaseIterable, Sendable {
    case bloodRecords = "blood_records"
    case badWorld = "bad_world"
    case banquetRecords = "banquet_records"
    case roughTradeUS = "rough_trade_us"
}

public protocol SourceAdapter: Sendable {
    var source: RadarSource { get }
    var storeID: String { get }
    func fetchLatest(at now: Date) async throws -> [ReleaseDrop]
}

public struct BloodRecordsAdapter: SourceAdapter {
    public let source: RadarSource = .bloodRecords
    public let storeID: String = "store_blood_records"

    public init() {}

    public func fetchLatest(at now: Date) async throws -> [ReleaseDrop] {
        []
    }
}

public struct BadWorldAdapter: SourceAdapter {
    public let source: RadarSource = .badWorld
    public let storeID: String = "store_bad_world"

    public init() {}

    public func fetchLatest(at now: Date) async throws -> [ReleaseDrop] {
        []
    }
}

public struct BanquetRecordsAdapter: SourceAdapter {
    public let source: RadarSource = .banquetRecords
    public let storeID: String = "store_banquet_records"

    public init() {}

    public func fetchLatest(at now: Date) async throws -> [ReleaseDrop] {
        []
    }
}

public struct RoughTradeUSAdapter: SourceAdapter {
    public let source: RadarSource = .roughTradeUS
    public let storeID: String = "store_rough_trade_us"

    public init() {}

    public func fetchLatest(at now: Date) async throws -> [ReleaseDrop] {
        []
    }
}
