import Foundation

/// Ranks articles for the "For You" feed using a simple, explainable
/// content-based scoring model. No ML — just per-category and per-source
/// affinities derived from explicit (like) and implicit (open/view) signals,
/// decayed by article recency.
///
/// score(article) =   recencyWeight   * recencyScore(publishedAt)
///                  + categoryWeight  * affinity(article.category, in: categoryAffinities)
///                  + sourceWeight    * affinity(article.source,   in: sourceAffinities)
///                  + biasWeight      * biasAlignment(article.bias)
///                  - viewedPenalty   (if the user has already opened this article)
///
/// All weights sum to ~1.0 on a fresh install so recency dominates; as the
/// user likes/opens more articles the personalisation signal grows.
enum RecommendationEngine {

    // MARK: - Tunable weights

    private static let recencyWeight: Double  = 1.0    // baseline: always prefer fresher news
    private static let categoryWeight: Double = 0.8
    private static let sourceWeight: Double   = 0.4
    private static let biasWeight: Double     = 0.2
    private static let viewedPenalty: Double  = 0.3

    // Like counts this many times more than an open.
    private static let likeWeight: Double = 3.0
    private static let openWeight: Double = 1.0

    // Half-life for recency decay (hours).
    private static let halfLifeHours: Double = 18.0

    // MARK: - Public API

    struct Signals {
        let likedIDs: Set<UUID>
        let viewedIDs: Set<UUID>
        let articles: [Article]
    }

    static func rank(_ articles: [Article], using signals: Signals) -> [Article] {
        let (catAff, srcAff, biasAff) = computeAffinities(signals: signals)

        return articles
            .map { ($0, score($0, catAff: catAff, srcAff: srcAff,
                              biasAff: biasAff, viewed: signals.viewedIDs.contains($0.id))) }
            .sorted { lhs, rhs in
                // Stable: primary = score desc, tiebreak = recency desc
                if abs(lhs.1 - rhs.1) > 0.001 { return lhs.1 > rhs.1 }
                return lhs.0.publishedAt > rhs.0.publishedAt
            }
            .map { $0.0 }
    }

    // MARK: - Scoring

    private static func score(
        _ article: Article,
        catAff: [String: Double],
        srcAff: [String: Double],
        biasAff: Double,
        viewed: Bool
    ) -> Double {
        let recency = recencyScore(article.publishedAt)
        let cat     = catAff[article.category] ?? 0
        let src     = srcAff[article.source]   ?? 0
        let bias    = article.bias.map { biasAlignment($0, targetMean: biasAff) } ?? 0

        var s = recencyWeight  * recency
              + categoryWeight * cat
              + sourceWeight   * src
              + biasWeight     * bias

        if viewed { s -= viewedPenalty }
        return s
    }

    /// Exponential decay: 1.0 at publish, 0.5 after `halfLifeHours`.
    private static func recencyScore(_ publishedAt: Date) -> Double {
        let hours = max(0, -publishedAt.timeIntervalSinceNow / 3600)
        return pow(0.5, hours / halfLifeHours)
    }

    /// How close an article's bias is to the user's preferred bias range.
    /// 1.0 if exactly on the user's mean, decaying as distance grows.
    private static func biasAlignment(_ articleBias: Double, targetMean: Double) -> Double {
        let distance = abs(articleBias - targetMean)   // 0…2
        return max(0, 1.0 - distance)                  // 0…1
    }

    // MARK: - Affinities (computed once per ranking pass)

    private static func computeAffinities(
        signals: Signals
    ) -> (category: [String: Double], source: [String: Double], biasMean: Double) {

        // Build fast lookups for the interacted articles only.
        let byID: [UUID: Article] = Dictionary(uniqueKeysWithValues: signals.articles.map { ($0.id, $0) })

        var catRaw: [String: Double] = [:]
        var srcRaw: [String: Double] = [:]
        var biasSum: Double = 0
        var biasWeightSum: Double = 0

        func record(_ article: Article, weight: Double) {
            catRaw[article.category, default: 0] += weight
            srcRaw[article.source,   default: 0] += weight
            if let b = article.bias {
                biasSum       += b * weight
                biasWeightSum += weight
            }
        }

        for id in signals.likedIDs  { if let a = byID[id] { record(a, weight: likeWeight) } }
        for id in signals.viewedIDs { if let a = byID[id] { record(a, weight: openWeight) } }

        let categoryAffinity = normalise(catRaw)
        let sourceAffinity   = normalise(srcRaw)
        let biasMean         = biasWeightSum > 0 ? biasSum / biasWeightSum : 0

        return (categoryAffinity, sourceAffinity, biasMean)
    }

    /// Map raw weights into the 0…1 range. If the user has no signals yet the
    /// dict is empty and every lookup returns 0 (neutral), so the ranker falls
    /// back to pure recency — exactly the old behaviour on a fresh install.
    private static func normalise(_ raw: [String: Double]) -> [String: Double] {
        guard let maxVal = raw.values.max(), maxVal > 0 else { return [:] }
        return raw.mapValues { $0 / maxVal }
    }
}
