import Foundation

/// Ranks and shuffles articles for the "For You" feed.
///
/// Two-phase algorithm:
///   1. Score every article against the user's profile (category + source +
///      bias affinities, decayed by recency, penalised if already viewed).
///   2. Materialise the feed via weighted-random sampling without replacement.
///      Higher-scored articles are more likely to appear earlier, but the
///      order is different every call. After each pick, the winning article's
///      category and source are temporarily penalised so the next few slots
///      favour something different — no five-CNBC-articles-in-a-row.
///
/// Result: a feed that is genuinely personalised *and* genuinely randomised
/// each time the user opens it. Cold-start with no profile = near-uniform
/// shuffle biased only by recency.
enum RecommendationEngine {

    // MARK: - Scoring weights

    private static let recencyWeight: Double  = 1.0
    private static let categoryWeight: Double = 0.8
    private static let sourceWeight: Double   = 0.4
    private static let biasWeight: Double     = 0.2
    private static let viewedPenalty: Double  = 0.5

    /// Like counts this many times more than an open.
    private static let likeWeight: Double = 3.0
    private static let openWeight: Double = 1.0

    /// Half-life for recency decay (hours).
    private static let halfLifeHours: Double = 18.0

    // MARK: - Sampling parameters

    /// Controls how sharp the weighted random is.
    /// 0 → uniform shuffle (ignores score). Higher → closer to deterministic ranking.
    /// ~2.5 gives a feed that clearly respects the profile but still surprises you.
    private static let samplingSharpness: Double = 2.5

    /// After picking an article, multiply the next sampling weight of its
    /// category / source by this factor. Recovers over subsequent picks.
    private static let sameCategoryDamping: Double = 0.35
    private static let sameSourceDamping:   Double = 0.2

    /// How many subsequent picks the damping persists for (decays linearly).
    private static let dampingWindow: Int = 4

    // MARK: - Public API

    struct Signals {
        let likedIDs: Set<UUID>
        let viewedIDs: Set<UUID>
        let articles: [Article]
    }

    /// Generate a fresh, personalised, diversity-interleaved feed.
    /// Call again to get a different order.
    static func feed(
        from articles: [Article],
        using signals: Signals,
        rng: inout RandomNumberGenerator
    ) -> [Article] {
        guard !articles.isEmpty else { return [] }

        let (catAff, srcAff, biasMean) = computeAffinities(signals: signals)

        // Phase 1: score every candidate.
        var pool: [(article: Article, baseWeight: Double)] = articles.map { a in
            let s = score(a, catAff: catAff, srcAff: srcAff,
                          biasMean: biasMean, viewed: signals.viewedIDs.contains(a.id))
            let w = pow(max(s, 0.0001), samplingSharpness)   // softmax-ish, guaranteed > 0
            return (a, w)
        }

        // Phase 2: weighted-random sampling without replacement + diversity damping.
        var picked: [Article] = []
        picked.reserveCapacity(pool.count)

        // Track cooldown counters — number of slots left where a cat/src is damped.
        var catCooldown: [String: Int] = [:]
        var srcCooldown: [String: Int] = [:]

        while !pool.isEmpty {
            // Compute effective weight per pool entry given current cooldowns.
            let weights: [Double] = pool.map { entry in
                var w = entry.baseWeight
                if let remaining = catCooldown[entry.article.category], remaining > 0 {
                    let decay = Double(remaining) / Double(dampingWindow)
                    w *= (1.0 - (1.0 - sameCategoryDamping) * decay)
                }
                if let remaining = srcCooldown[entry.article.source], remaining > 0 {
                    let decay = Double(remaining) / Double(dampingWindow)
                    w *= (1.0 - (1.0 - sameSourceDamping) * decay)
                }
                return w
            }

            let idx = weightedRandomIndex(weights: weights, rng: &rng)
            let chosen = pool.remove(at: idx)
            picked.append(chosen.article)

            // Apply damping to same category/source for the next `dampingWindow` picks.
            catCooldown[chosen.article.category] = dampingWindow
            srcCooldown[chosen.article.source]   = dampingWindow

            // Decrement all existing cooldowns by 1.
            catCooldown = catCooldown.mapValues { max(0, $0 - 1) }
            srcCooldown = srcCooldown.mapValues { max(0, $0 - 1) }
        }

        return picked
    }

    /// Convenience overload that uses the system RNG.
    static func feed(from articles: [Article], using signals: Signals) -> [Article] {
        var rng: RandomNumberGenerator = SystemRandomNumberGenerator()
        return feed(from: articles, using: signals, rng: &rng)
    }

    // MARK: - Scoring

    private static func score(
        _ article: Article,
        catAff: [String: Double],
        srcAff: [String: Double],
        biasMean: Double,
        viewed: Bool
    ) -> Double {
        let recency = recencyScore(article.publishedAt)
        let cat     = catAff[article.category] ?? 0
        let src     = srcAff[article.source]   ?? 0
        let bias    = article.bias.map { biasAlignment($0, targetMean: biasMean) } ?? 0

        var s = recencyWeight  * recency
              + categoryWeight * cat
              + sourceWeight   * src
              + biasWeight     * bias

        if viewed { s -= viewedPenalty }
        return s
    }

    private static func recencyScore(_ publishedAt: Date) -> Double {
        let hours = max(0, -publishedAt.timeIntervalSinceNow / 3600)
        return pow(0.5, hours / halfLifeHours)
    }

    private static func biasAlignment(_ articleBias: Double, targetMean: Double) -> Double {
        let distance = abs(articleBias - targetMean)   // 0…2
        return max(0, 1.0 - distance)
    }

    // MARK: - Affinities

    private static func computeAffinities(
        signals: Signals
    ) -> (category: [String: Double], source: [String: Double], biasMean: Double) {

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

        return (normalise(catRaw), normalise(srcRaw),
                biasWeightSum > 0 ? biasSum / biasWeightSum : 0)
    }

    private static func normalise(_ raw: [String: Double]) -> [String: Double] {
        guard let maxVal = raw.values.max(), maxVal > 0 else { return [:] }
        return raw.mapValues { $0 / maxVal }
    }

    // MARK: - Weighted random

    private static func weightedRandomIndex(
        weights: [Double],
        rng: inout RandomNumberGenerator
    ) -> Int {
        let total = weights.reduce(0, +)
        guard total > 0 else {
            return Int.random(in: 0..<weights.count, using: &rng)
        }
        let target = Double.random(in: 0..<total, using: &rng)
        var running = 0.0
        for (i, w) in weights.enumerated() {
            running += w
            if target < running { return i }
        }
        return weights.count - 1
    }
}
