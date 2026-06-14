import Foundation
import Testing
@testable import VinylRadar

@Suite("ReleaseDropDecodingTests")
struct ReleaseDropDecodingTests {
    @Test("decodes publishedAtSource when present")
    func decodesPublishedAtSource() throws {
        let payload = """
        {
          "id": "r1",
          "artist": "Artist",
          "title": "Title",
          "storeID": "store_blood_records",
          "sourceItemKey": "source-key",
          "publishedAt": "2026-03-27T19:11:21Z",
          "publishedAtSource": "first_seen",
          "flags": ["NEW"],
          "isSoldOut": false,
          "signedByHeuristic": true
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(ReleaseDrop.self, from: payload)

        #expect(decoded.publishedAtSource == .firstSeen)
        #expect(decoded.signedByHeuristic == true)
    }

    @Test("falls back to unknown when publishedAtSource missing")
    func defaultsUnknownPublishedAtSource() throws {
        let payload = """
        {
          "id": "r1",
          "artist": "Artist",
          "title": "Title",
          "storeID": "store_blood_records",
          "sourceItemKey": "source-key",
          "publishedAt": "2026-03-27T19:11:21Z",
          "flags": ["NEW"],
          "isSoldOut": false
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(ReleaseDrop.self, from: payload)

        #expect(decoded.publishedAtSource == .unknown)
        #expect(decoded.signedByHeuristic == false)
    }
}
