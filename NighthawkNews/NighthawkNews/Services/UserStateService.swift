import Foundation

/// Server-side persistence of the user's liked / bookmarked / viewed article
/// sets, so they survive across devices and sign-in sessions.
///
/// Distinct from `InteractionService`:
///   - InteractionService = append-only signal stream that feeds the recommender.
///   - UserStateService    = current set membership (toggleable, idempotent).
///
/// Network failures are best-effort: a failed `set` leaves the local toggle
/// in place; the next successful sync from `fetch` will reconcile.
enum UserStateService {

    enum Kind: String, Codable, Sendable {
        case liked, bookmarked, viewed
    }

    struct State: Decodable, Sendable {
        let liked: [String]
        let bookmarked: [String]
        let viewed: [String]
    }

    // MARK: - Fetch

    static func fetch(userID: String) async throws -> State {
        let url = try makeURL(for: userID)
        var req = URLRequest(url: url)
        req.timeoutInterval = 15
        let (data, response) = try await URLSession.shared.data(for: req)
        try validate(response)
        return try JSONDecoder().decode(State.self, from: data)
    }

    // MARK: - Mutate

    static func set(userID: String, articleID: UUID, kind: Kind, value: Bool) async throws {
        let url = try makeURL(for: userID)
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.timeoutInterval = 15

        let body: [String: Any] = [
            "article_id": articleID.uuidString,
            "kind": kind.rawValue,
            "value": value,
        ]
        req.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (_, response) = try await URLSession.shared.data(for: req)
        try validate(response)
    }

    // MARK: - Account deletion

    /// Permanently delete the user's server-side data. Required by App Store
    /// guideline 5.1.1(v). Idempotent — a 404 from the server is treated as
    /// success because the goal state is "no data on the server".
    static func deleteAccount(userID: String) async throws {
        let trimmed = userID.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty,
              let encoded = trimmed.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
              let url = URL(string: "\(NewsService.baseURL)/users/\(encoded)")
        else {
            throw URLError(.badURL)
        }
        var req = URLRequest(url: url)
        req.httpMethod = "DELETE"
        req.timeoutInterval = 15

        let (_, response) = try await URLSession.shared.data(for: req)
        guard let http = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        if http.statusCode == 404 { return }
        guard (200...299).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
    }

    // MARK: - Helpers

    private static func makeURL(for userID: String) throws -> URL {
        let trimmed = userID.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty,
              let encoded = trimmed.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
              let url = URL(string: "\(NewsService.baseURL)/users/\(encoded)/state")
        else {
            throw URLError(.badURL)
        }
        return url
    }

    private static func validate(_ response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse,
              (200...299).contains(http.statusCode)
        else {
            throw URLError(.badServerResponse)
        }
    }
}
