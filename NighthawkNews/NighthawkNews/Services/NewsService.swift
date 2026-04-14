import Foundation

enum NewsService {
    // -----------------------------------------------------------------------
    // Configuration
    // Change to your Mac's LAN IP (e.g. "http://192.168.1.42:8000")
    // when testing on a physical device instead of the simulator.
    // -----------------------------------------------------------------------
    static let baseURL = "http://localhost:8000"

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

        var request        = URLRequest(url: url)
        request.timeoutInterval = 10

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        return try decoder.decode([Article].self, from: data)
    }
}
