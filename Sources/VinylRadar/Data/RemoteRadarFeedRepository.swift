import Foundation

public actor RemoteRadarFeedRepository: RadarFeedRepository {
    public enum RepositoryError: Error, Equatable {
        case invalidEndpoint
        case invalidResponse
        case unexpectedStatusCode(Int)
    }

    public typealias Fetcher = @Sendable (URLRequest) async throws -> (Data, URLResponse)

    private let endpoint: URL
    private let timeoutInterval: TimeInterval
    private let cacheStore: any RadarFeedCacheStore
    private let fetcher: Fetcher

    public init(
        baseURL: URL,
        endpointPath: String = "/v1/radar/releases",
        timeoutInterval: TimeInterval = 12,
        cacheStore: any RadarFeedCacheStore = UserDefaultsRadarFeedCacheStore(),
        fetcher: @escaping Fetcher = RemoteRadarFeedRepository.defaultFetcher
    ) throws {
        guard let endpoint = URL(string: endpointPath, relativeTo: baseURL)?.absoluteURL else {
            throw RepositoryError.invalidEndpoint
        }

        self.endpoint = endpoint
        self.timeoutInterval = timeoutInterval
        self.cacheStore = cacheStore
        self.fetcher = fetcher
    }

    public func fetchLatest(forceRefresh: Bool = false) async throws -> [ReleaseDrop] {
        do {
            return try await fetchSnapshot(forceRefresh: forceRefresh)
        } catch {
            if forceRefresh {
                do {
                    return try await fetchSnapshot(forceRefresh: false)
                } catch {
                    // Fall through to cache fallback.
                }
            }
            if let cached = await cacheStore.load(), !cached.isEmpty {
                return cached
            }
            throw error
        }
    }

    private func fetchSnapshot(forceRefresh: Bool) async throws -> [ReleaseDrop] {
        var request = URLRequest(url: endpointURL(forceRefresh: forceRefresh))
        request.timeoutInterval = timeoutInterval
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.cachePolicy = .reloadIgnoringLocalCacheData

        let (data, response) = try await fetcher(request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw RepositoryError.invalidResponse
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            throw RepositoryError.unexpectedStatusCode(httpResponse.statusCode)
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let snapshot = try decoder.decode(RadarReleasesSnapshot.self, from: data)

        await cacheStore.save(snapshot.releases)
        return snapshot.releases
    }

    private func endpointURL(forceRefresh: Bool) -> URL {
        guard forceRefresh,
              var components = URLComponents(url: endpoint, resolvingAgainstBaseURL: false) else {
            return endpoint
        }

        var queryItems = components.queryItems ?? []
        queryItems.removeAll(where: { $0.name == "refresh" })
        queryItems.append(URLQueryItem(name: "refresh", value: "1"))
        components.queryItems = queryItems
        return components.url ?? endpoint
    }
}

extension RemoteRadarFeedRepository {
    public static let defaultFetcher: Fetcher = { request in
        try await URLSession.shared.data(for: request)
    }
}

private struct RadarReleasesSnapshot: Codable {
    let generatedAt: Date?
    let releases: [ReleaseDrop]
}
