import Foundation

/// On-disk cache of the most recent article list so the app boots with real
/// content instantly and keeps working if the backend is unreachable.
enum ArticleStorage {
    private static let fileName = "articles_cache.json"

    private static var fileURL: URL {
        let dir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        return dir.appendingPathComponent(fileName)
    }

    private static let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        return e
    }()

    private static let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    static func save(_ articles: [Article]) {
        do {
            let data = try encoder.encode(articles)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            print("[ArticleStorage] save failed: \(error)")
        }
    }

    static func load() -> [Article]? {
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        return try? decoder.decode([Article].self, from: data)
    }

    /// Last time the on-disk cache was written, if any.
    static var lastUpdated: Date? {
        (try? FileManager.default.attributesOfItem(atPath: fileURL.path))?[.modificationDate] as? Date
    }
}
