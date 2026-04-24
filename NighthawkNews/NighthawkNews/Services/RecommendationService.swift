import Foundation

/// Single entry point for "what should we recommend to the user right now"
/// across sections of the app (currently the Search tab; can be reused
/// elsewhere). Distinct from `RecommendationEngine`, which builds the full
/// randomised, diversity-damped *Feed*. This service produces a small,
/// **deterministic** ranked list suitable for sidebar-style placements.
///
/// Pipeline (cascading — first non-empty signal wins):
///
///   1. Search history     → score by how many distinct past queries match
///   2. Likes              → category/source affinity from liked articles
///   3. Recent fallback    → newest articles, viewed items pushed down
///
/// The caller passes whatever signals it has; the service decides which to use.
enum RecommendationService {

    // MARK: - Inputs / outputs

    struct Signals {
        var searchHistory: [String] = []
        var likedIDs: Set<UUID> = []
        var viewedIDs: Set<UUID> = []
    }

    enum Source { case searchHistory, likes, recent }

    struct Result {
        let articles: [Article]
        let source: Source
    }

    // MARK: - Tuning

    private static let maxResults = 20

    // Likes-mode weights — same affinity idea as RecommendationEngine but
    // simplified: deterministic, no randomness, no MMR/Thompson, no bias term.
    private static let categoryWeight: Double = 2.0
    private static let sourceWeight:   Double = 1.0
    private static let recencyWeight:  Double = 0.5
    private static let viewedPenalty:  Double = 0.4
    private static let halfLifeHours:  Double = 24.0

    // MARK: - Public API

    /// Top-level entry point. Picks the strongest available signal and returns
    /// a ranked recommendation list for it.
    static func recommend(from articles: [Article], signals: Signals) -> Result {
        if !signals.searchHistory.isEmpty {
            let ranked = recommendFromHistory(signals.searchHistory, in: articles)
            if !ranked.isEmpty { return Result(articles: ranked, source: .searchHistory) }
        }
        if !signals.likedIDs.isEmpty {
            let ranked = recommendFromLikes(
                likedIDs: signals.likedIDs,
                viewedIDs: signals.viewedIDs,
                in: articles
            )
            if !ranked.isEmpty { return Result(articles: ranked, source: .likes) }
        }
        return Result(
            articles: recommendRecent(in: articles, viewedIDs: signals.viewedIDs),
            source: .recent
        )
    }

    /// Substring match against title/excerpt/body/source/category.
    /// Used both for live query results and for history-based scoring.
    static func matches(for query: String, in articles: [Article]) -> [Article] {
        let needle = query.lowercased()
        guard !needle.isEmpty else { return [] }
        return articles.filter { article in
            article.title.lowercased().contains(needle)
                || article.excerpt.lowercased().contains(needle)
                || article.body.lowercased().contains(needle)
                || article.source.lowercased().contains(needle)
                || article.category.lowercased().contains(needle)
        }
    }

    // MARK: - Mode 1: search history

    private static func recommendFromHistory(_ queries: [String], in articles: [Article]) -> [Article] {
        var hitCount: [UUID: Int] = [:]
        var firstSeenOrder: [UUID: Int] = [:]
        var order = 0

        for q in queries {
            for article in matches(for: q, in: articles) {
                hitCount[article.id, default: 0] += 1
                if firstSeenOrder[article.id] == nil {
                    firstSeenOrder[article.id] = order
                    order += 1
                }
            }
        }

        return articles
            .filter { hitCount[$0.id] != nil }
            .sorted { lhs, rhs in
                let lh = hitCount[lhs.id] ?? 0
                let rh = hitCount[rhs.id] ?? 0
                if lh != rh { return lh > rh }
                return (firstSeenOrder[lhs.id] ?? .max) < (firstSeenOrder[rhs.id] ?? .max)
            }
            .prefix(maxResults)
            .map { $0 }
    }

    // MARK: - Mode 2: likes

    private static func recommendFromLikes(
        likedIDs: Set<UUID>,
        viewedIDs: Set<UUID>,
        in articles: [Article]
    ) -> [Article] {
        var catCounts: [String: Double] = [:]
        var srcCounts: [String: Double] = [:]
        for article in articles where likedIDs.contains(article.id) {
            catCounts[article.category, default: 0] += 1
            srcCounts[article.source,   default: 0] += 1
        }
        let catAff = normalise(catCounts)
        let srcAff = normalise(srcCounts)

        guard !catAff.isEmpty || !srcAff.isEmpty else { return [] }

        let scored: [(Article, Double)] = articles.compactMap { article in
            guard !likedIDs.contains(article.id) else { return nil }

            let cat = catAff[article.category] ?? 0
            let src = srcAff[article.source]   ?? 0
            guard cat > 0 || src > 0 else { return nil }

            var s = categoryWeight * cat
                  + sourceWeight   * src
                  + recencyWeight  * recencyScore(article.publishedAt)
            if viewedIDs.contains(article.id) { s -= viewedPenalty }
            return (article, s)
        }

        return scored
            .sorted { $0.1 > $1.1 }
            .prefix(maxResults)
            .map { $0.0 }
    }

    // MARK: - Mode 3: recency fallback

    private static func recommendRecent(in articles: [Article], viewedIDs: Set<UUID>) -> [Article] {
        articles
            .sorted { lhs, rhs in
                let lv = viewedIDs.contains(lhs.id) ? 1 : 0
                let rv = viewedIDs.contains(rhs.id) ? 1 : 0
                if lv != rv { return lv < rv }   // unviewed before viewed
                return lhs.publishedAt > rhs.publishedAt
            }
            .prefix(maxResults)
            .map { $0 }
    }

    // MARK: - Helpers

    private static func recencyScore(_ publishedAt: Date) -> Double {
        let hours = max(0, -publishedAt.timeIntervalSinceNow / 3600)
        return pow(0.5, hours / halfLifeHours)
    }

    private static func normalise(_ raw: [String: Double]) -> [String: Double] {
        guard let maxVal = raw.values.max(), maxVal > 0 else { return [:] }
        return raw.mapValues { $0 / maxVal }
    }
}
