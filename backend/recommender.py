"""
Five-stage recommendation pipeline for personalised article feeds.

Pipeline:
    1. Candidate generation   — filter already-seen, enforce freshness
    2. Feature scoring        — category/source/bias/recency/topic signals
    3. Engagement prediction  — sigmoid over feature vector
    4. MMR re-ranking         — maximal marginal relevance for diversity
    5. Thompson sampling      — Beta-distribution explore/exploit

Runs server-side and returns a ranked list of article dicts ready to send
to the iOS client.
"""

import json
import math
import random
import re
from collections import Counter, defaultdict
from datetime import datetime, timezone
from typing import Optional

from db import ArticleDB

# ---------------------------------------------------------------------------
# Signal weights — how much each interaction type matters for affinity
# ---------------------------------------------------------------------------
SIGNAL_WEIGHTS = {
    "like":      5.0,
    "bookmark":  4.0,
    "long_read": 3.0,
    "read":      1.5,
    "view":      0.5,
    "skip":     -1.0,
}

# Feature weights for engagement prediction (Stage 3)
W_RECENCY  = 1.0
W_CATEGORY = 0.8
W_SOURCE   = 0.4
W_BIAS     = 0.2
W_TOPIC    = 0.6

# MMR lambda (Stage 4) — higher = favour relevance over diversity
MMR_LAMBDA = 0.7

# Personalisation should warm up gradually. One like should nudge the feed,
# not turn it into a single-category wall.
PROFILE_WARMUP_INTERACTIONS = 40
MMR_CANDIDATE_MULTIPLIER = 4
MMR_CANDIDATE_FLOOR = 60

# Decay half-lives
RECENCY_HALF_LIFE_HOURS = 18.0
AFFINITY_HALF_LIFE_DAYS = 3.0

# How many tokens to keep per article for topic fingerprinting
MAX_TOPIC_TOKENS = 20

# Minimum word length for topic keywords
MIN_KEYWORD_LEN = 4

# Stop words to exclude from topic fingerprinting
_STOP_WORDS = frozenset({
    "this", "that", "with", "from", "have", "been", "were", "will",
    "they", "their", "them", "than", "what", "when", "where", "which",
    "about", "into", "more", "some", "would", "could", "should", "also",
    "just", "over", "after", "before", "other", "says", "said", "like",
    "make", "made", "most", "much", "many", "very", "your", "does",
    "each", "know", "want", "year", "years", "back", "even", "well",
    "here", "only", "come", "came", "take", "took", "going", "being",
    "first", "last", "long", "great", "little", "right", "still",
    "think", "every", "people", "because", "these", "those", "through",
    "between", "such", "while", "around", "again", "against", "under",
    "never", "always", "really", "until", "something", "anything",
    "everything", "during", "another", "number", "since", "however",
    "report", "reports", "according", "could", "there", "three",
    "million", "billion", "percent",
})

_WORD_RE = re.compile(r"[a-z]{4,}")


# ---------------------------------------------------------------------------
# User profile data structure
# ---------------------------------------------------------------------------

def _empty_profile() -> dict:
    """Return a blank profile for cold-start users."""
    return {
        "category_affinity": {},    # category -> float
        "source_affinity": {},      # source -> float
        "bias_pref": 0.0,           # weighted mean of engaged articles' bias
        "topic_tf": {},             # token -> tf score
        "beta_params": {},          # category -> {"alpha": float, "beta": float}
        "interaction_count": 0,
    }


# ---------------------------------------------------------------------------
# Profile computation from interaction history
# ---------------------------------------------------------------------------

def compute_profile(interactions: list[dict], articles_by_id: dict[str, dict]) -> dict:
    """Build a user profile from their interaction history and the article corpus."""
    profile = _empty_profile()
    if not interactions:
        return profile

    now = datetime.now(timezone.utc)

    cat_raw: dict[str, float] = defaultdict(float)
    src_raw: dict[str, float] = defaultdict(float)
    bias_sum = 0.0
    bias_weight_sum = 0.0
    word_counts: Counter = Counter()
    total_docs = 0
    engagement_by_cat: dict[str, dict] = defaultdict(lambda: {"pos": 0, "neg": 0})

    for ix in interactions:
        article = articles_by_id.get(ix["article_id"])
        if not article:
            continue

        signal_w = SIGNAL_WEIGHTS.get(ix["interaction"], 0.0)
        if signal_w == 0.0:
            continue

        # Time decay: interactions from days ago count less
        try:
            ix_time = datetime.fromisoformat(ix["created_at"])
            if ix_time.tzinfo is None:
                ix_time = ix_time.replace(tzinfo=timezone.utc)
        except (ValueError, TypeError):
            ix_time = now
        age_days = max(0, (now - ix_time).total_seconds() / 86400)
        decay = math.pow(0.5, age_days / AFFINITY_HALF_LIFE_DAYS)
        effective_w = signal_w * decay

        cat = article.get("category", "")
        src = article.get("source", "")

        cat_raw[cat] += effective_w
        src_raw[src] += effective_w

        # Bias tracking
        bias = article.get("bias")
        if bias is not None and signal_w > 0:
            bias_sum += bias * effective_w
            bias_weight_sum += effective_w

        # Topic keywords from engaged articles
        if signal_w > 0:
            title = (article.get("title") or "").lower()
            excerpt = (article.get("excerpt") or "").lower()
            tokens = _WORD_RE.findall(title + " " + excerpt)
            tokens = [t for t in tokens if t not in _STOP_WORDS]
            for t in tokens:
                word_counts[t] += effective_w
            total_docs += 1

        # Beta distribution tracking (positive engagement vs skips)
        if signal_w > 0:
            engagement_by_cat[cat]["pos"] += 1
        else:
            engagement_by_cat[cat]["neg"] += 1

    # Normalise affinities to [0, 1]
    profile["category_affinity"] = _normalise(dict(cat_raw))
    profile["source_affinity"] = _normalise(dict(src_raw))
    profile["bias_pref"] = (bias_sum / bias_weight_sum) if bias_weight_sum > 0 else 0.0

    # Topic fingerprint: keep top-N keywords by weighted frequency
    if word_counts:
        top = word_counts.most_common(MAX_TOPIC_TOKENS)
        max_count = top[0][1] if top else 1
        profile["topic_tf"] = {w: c / max_count for w, c in top}

    # Beta params per category
    beta_params = {}
    for cat, counts in engagement_by_cat.items():
        beta_params[cat] = {
            "alpha": 1.0 + counts["pos"],
            "beta": 1.0 + counts["neg"],
        }
    profile["beta_params"] = beta_params
    profile["interaction_count"] = len(interactions)

    return profile


# ---------------------------------------------------------------------------
# Five-stage pipeline
# ---------------------------------------------------------------------------

def generate_feed(
    articles: list[dict],
    profile: dict,
    session_seen: set[str],
    count: int = 30,
) -> list[dict]:
    """Run the full 5-stage pipeline and return up to `count` ranked articles."""

    # -- Stage 1: Candidate generation --
    candidates = _stage1_candidates(articles, session_seen)
    if not candidates:
        return []

    # -- Stage 2 + 3: Feature scoring + engagement prediction --
    scored = []
    for a in candidates:
        features = _stage2_features(a, profile)
        relevance = _stage3_engagement_score(features)
        scored.append((a, relevance, features))

    # -- Stage 4: MMR re-ranking for diversity --
    mmr_count = min(
        len(scored),
        max(count * MMR_CANDIDATE_MULTIPLIER, min(MMR_CANDIDATE_FLOOR, len(scored))),
    )
    ranked = _stage4_mmr(scored, mmr_count)

    # -- Stage 5: Thompson sampling for exploration --
    final = _stage5_thompson(ranked, profile, count)

    return final


# ---------------------------------------------------------------------------
# Stage 1: Candidate generation
# ---------------------------------------------------------------------------

def _stage1_candidates(articles: list[dict], session_seen: set[str]) -> list[dict]:
    """Filter out already-seen articles. Keep all others — recency is handled by scoring."""
    return [a for a in articles if a["id"] not in session_seen]


# ---------------------------------------------------------------------------
# Stage 2: Feature extraction
# ---------------------------------------------------------------------------

def _stage2_features(article: dict, profile: dict) -> dict:
    cat_aff = profile.get("category_affinity", {})
    src_aff = profile.get("source_affinity", {})
    bias_pref = profile.get("bias_pref", 0.0)
    topic_tf = profile.get("topic_tf", {})
    profile_strength = _profile_strength(profile)

    # Recency score: exponential decay with 18-hour half-life
    try:
        pub = datetime.fromisoformat(article["publishedAt"])
        if pub.tzinfo is None:
            pub = pub.replace(tzinfo=timezone.utc)
    except (ValueError, TypeError):
        pub = datetime.now(timezone.utc)
    hours_old = max(0, (datetime.now(timezone.utc) - pub).total_seconds() / 3600)
    recency = math.pow(0.5, hours_old / RECENCY_HALF_LIFE_HOURS)

    # Category match
    category_match = cat_aff.get(article.get("category", ""), 0.0) * profile_strength

    # Source match
    source_match = src_aff.get(article.get("source", ""), 0.0) * profile_strength

    # Bias alignment: 1.0 when perfect match, 0.0 when maximally opposed
    article_bias = article.get("bias")
    if article_bias is not None:
        raw_bias_align = max(0.0, 1.0 - abs(article_bias - bias_pref))
        bias_align = 0.5 + (raw_bias_align - 0.5) * profile_strength
    else:
        bias_align = 0.5  # neutral for unrated articles

    # Topic similarity: Jaccard-like overlap between article keywords and profile
    title = (article.get("title") or "").lower()
    excerpt = (article.get("excerpt") or "").lower()
    article_tokens = set(_WORD_RE.findall(title + " " + excerpt)) - _STOP_WORDS
    if article_tokens and topic_tf:
        profile_tokens = set(topic_tf.keys())
        intersection = article_tokens & profile_tokens
        # Weighted overlap: sum of TF weights for matching tokens
        if intersection:
            topic_sim = (
                sum(topic_tf.get(t, 0) for t in intersection)
                / len(article_tokens)
                * profile_strength
            )
        else:
            topic_sim = 0.0
    else:
        topic_sim = 0.0

    return {
        "recency": recency,
        "category_match": category_match,
        "source_match": source_match,
        "bias_align": bias_align,
        "topic_sim": topic_sim,
    }


# ---------------------------------------------------------------------------
# Stage 3: Engagement prediction
# ---------------------------------------------------------------------------

def _stage3_engagement_score(features: dict) -> float:
    """Sigmoid over weighted feature sum."""
    z = (
        W_RECENCY  * features["recency"]
        + W_CATEGORY * features["category_match"]
        + W_SOURCE   * features["source_match"]
        + W_BIAS     * features["bias_align"]
        + W_TOPIC    * features["topic_sim"]
    )
    # Sigmoid squashes to (0, 1)
    return 1.0 / (1.0 + math.exp(-z))


# ---------------------------------------------------------------------------
# Stage 4: MMR re-ranking (Maximal Marginal Relevance)
# ---------------------------------------------------------------------------

def _article_similarity(a: dict, b: dict) -> float:
    """Simple similarity: 1.0 if same category AND source, partial matches otherwise."""
    sim = 0.0
    if a.get("category") == b.get("category"):
        sim += 0.6
    if a.get("source") == b.get("source"):
        sim += 0.4
    return sim


def _stage4_mmr(
    scored: list[tuple[dict, float, dict]],
    count: int,
) -> list[tuple[dict, float]]:
    """Select articles via MMR: balance relevance with diversity."""
    if not scored:
        return []

    # Sort by relevance descending as starting point
    scored.sort(key=lambda x: x[1], reverse=True)

    selected: list[tuple[dict, float]] = []
    remaining = list(scored)

    # Always pick the most relevant article first
    best = remaining.pop(0)
    selected.append((best[0], best[1]))

    while remaining and len(selected) < count:
        best_mmr = -float("inf")
        best_idx = 0

        for i, (article, relevance, _features) in enumerate(remaining):
            # Max similarity to any already-selected article
            max_sim = max(
                (_article_similarity(article, sel[0]) for sel in selected),
                default=0.0,
            )
            mmr = MMR_LAMBDA * relevance - (1.0 - MMR_LAMBDA) * max_sim
            if mmr > best_mmr:
                best_mmr = mmr
                best_idx = i

        chosen = remaining.pop(best_idx)
        selected.append((chosen[0], chosen[1]))

    return selected


# ---------------------------------------------------------------------------
# Stage 5: Thompson Sampling (explore / exploit)
# ---------------------------------------------------------------------------

def _stage5_thompson(
    ranked: list[tuple[dict, float]],
    profile: dict,
    count: int,
) -> list[dict]:
    """
    Re-score articles using Thompson sampling to inject exploration.

    For each article, sample from a Beta distribution parameterised by the
    user's engagement history with that category. Articles in categories
    the user hasn't explored much get wide priors → higher chance of being
    surfaced.

    The final score blends the relevance score (exploitation) with the
    Thompson sample (exploration).
    """
    if not ranked:
        return []

    beta_params = profile.get("beta_params", {})
    interaction_count = profile.get("interaction_count", 0)
    profile_strength = _profile_strength(profile)

    # Exploration weight: higher for new users, decays as they build history
    # At 0 interactions: 0.5 explore / 0.5 exploit
    # At 50 interactions: ~0.15 explore
    # At 200+: ~0.05 explore (mostly exploit)
    explore_weight = max(0.05, 0.5 * math.exp(-interaction_count / 60.0))
    exploit_weight = 1.0 - explore_weight

    thompson_scored = []
    for article, relevance in ranked:
        cat = article.get("category", "")
        params = beta_params.get(cat, {"alpha": 1.0, "beta": 1.0})
        alpha = 1.0 + (params["alpha"] - 1.0) * profile_strength
        beta_val = 1.0 + (params["beta"] - 1.0) * profile_strength

        # Sample from Beta distribution
        thompson_sample = random.betavariate(alpha, beta_val)

        # Blend relevance (exploit) with Thompson sample (explore)
        final_score = exploit_weight * relevance + explore_weight * thompson_sample

        thompson_scored.append((article, final_score))

    # Sort by blended score, descending
    thompson_scored.sort(key=lambda x: x[1], reverse=True)

    return [article for article, _score in thompson_scored[:count]]


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _normalise(raw: dict[str, float]) -> dict[str, float]:
    if not raw:
        return {}
    max_val = max(abs(v) for v in raw.values())
    if max_val == 0:
        return {}
    return {k: v / max_val for k, v in raw.items()}


def _profile_strength(profile: dict) -> float:
    """Return 0..1 confidence for how strongly to personalise this feed."""
    interaction_count = max(0, int(profile.get("interaction_count", 0) or 0))
    if interaction_count == 0:
        return 0.0
    return min(1.0, math.log1p(interaction_count) / math.log1p(PROFILE_WARMUP_INTERACTIONS))


# ---------------------------------------------------------------------------
# High-level entry point used by main.py
# ---------------------------------------------------------------------------

def build_feed(
    db: ArticleDB,
    user_id: str,
    session_seen_ids: list[str],
    count: int = 30,
) -> list[dict]:
    """
    End-to-end: load profile + articles, run pipeline, return ranked feed.
    For unknown users, returns recency-ranked articles with exploration.
    """
    articles = db.list_articles(limit=500)
    if not articles:
        return []

    articles_by_id = {a["id"]: a for a in articles}

    # Load or compute profile
    profile_json = db.get_profile(user_id)
    if profile_json:
        try:
            profile = json.loads(profile_json)
        except (json.JSONDecodeError, TypeError):
            profile = _empty_profile()
    else:
        profile = _empty_profile()

    session_seen = set(session_seen_ids)
    return generate_feed(articles, profile, session_seen, count)


def update_profile(db: ArticleDB, user_id: str) -> dict:
    """Recompute and persist the user's profile from their interaction history."""
    interactions = db.get_user_interactions(user_id, limit=2000)
    articles = db.list_articles(limit=500)
    articles_by_id = {a["id"]: a for a in articles}

    profile = compute_profile(interactions, articles_by_id)
    db.upsert_profile(user_id, json.dumps(profile))
    return profile
