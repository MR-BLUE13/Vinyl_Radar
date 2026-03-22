import Foundation

enum MockDataLoader {
    static func loadStores() throws -> [StoreSource] {
        try decode("MockStores", as: [StoreSource].self)
    }

    static func loadReleases() throws -> [ReleaseDrop] {
        try decode("MockReleases", as: [ReleaseDrop].self)
    }

    private static func decode<T: Decodable>(_ name: String, as type: T.Type) throws -> T {
        guard let url = Bundle.module.url(forResource: name, withExtension: "json") else {
            throw DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "Missing resource: \(name).json"))
        }

        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(type, from: data)
    }
}
