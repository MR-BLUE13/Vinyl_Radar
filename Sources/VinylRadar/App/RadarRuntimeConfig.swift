import Foundation

enum RadarRuntimeConfig {
    static var apiBaseURL: URL? {
        if let value = ProcessInfo.processInfo.environment["RADAR_API_BASE_URL"],
           let url = URL(string: value),
           !value.isEmpty {
            return url
        }

        if let value = Bundle.main.object(forInfoDictionaryKey: "RadarAPIBaseURL") as? String,
           let url = URL(string: value),
           !value.isEmpty {
            return url
        }

        return nil
    }
}
