import Foundation

enum NewsService {
    // -----------------------------------------------------------------------
    // Configuration
    //
    // Default points at the public Fly.io deployment. Override at runtime by
    // setting the `NEWSHAWK_API_BASE_URL` UserDefaults key (useful for testing
    // against a local backend without rebuilding):
    //
    //   UserDefaults.standard.set("http://192.168.1.42:8000",
    //                             forKey: "NEWSHAWK_API_BASE_URL")
    // -----------------------------------------------------------------------
    static let defaultBaseURL = "https://newshawk-api.fly.dev"

    static var baseURL: String {
        UserDefaults.standard.string(forKey: "NEWSHAWK_API_BASE_URL") ?? defaultBaseURL
    }

    // -----------------------------------------------------------------------
    // Decoder — handles ISO-8601 dates from the backend
    // -----------------------------------------------------------------------
    static let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .custom { decoder in
            let c   = try decoder.singleValueContainer()
            let str = try c.decode(String.self)

            let fmt = ISO8601DateFormatter()
            for opts: ISO8601DateFormatter.Options in [
                [.withInternetDateTime, .withFractionalSeconds],
                [.withInternetDateTime]
            ] {
                fmt.formatOptions = opts
                if let date = fmt.date(from: str) { return date }
            }
            throw DecodingError.dataCorruptedError(
                in: c, debugDescription: "Unrecognised date: \(str)")
        }
        return d
    }()

    // -----------------------------------------------------------------------
    // Fetch
    // -----------------------------------------------------------------------
    static func fetchArticles(category: String? = nil) async throws -> [Article] {
        var components = URLComponents(string: "\(baseURL)/articles")!
        if let category, category != "All" {
            components.queryItems = [URLQueryItem(name: "category", value: category)]
        }
        guard let url = components.url else { throw URLError(.badURL) }

        var request = URLRequest(url: url)
        request.timeoutInterval = 10
        request.cachePolicy = .reloadIgnoringLocalCacheData

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        return try decoder.decode([Article].self, from: data)
    }
}
