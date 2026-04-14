import asyncio
import os
import feedparser
import uuid
import time
import trafilatura
from datetime import datetime, timezone
from bs4 import BeautifulSoup
from dotenv import load_dotenv
from openai import AsyncOpenAI

load_dotenv()
_openai = AsyncOpenAI(api_key=os.getenv("OPENAI_API_KEY"))

# Persists across refresh cycles so each article is only rated once
_bias_cache: dict[str, float] = {}

# ---------------------------------------------------------------------------
# Feed registry  —  (display_name, rss_url) per category
# ---------------------------------------------------------------------------
RSS_FEEDS: dict[str, list[tuple[str, str]]] = {
    "Tech": [
        ("Ars Technica",  "https://feeds.arstechnica.com/arstechnica/index"),
        ("The Verge",     "https://www.theverge.com/rss/index.xml"),
        ("TechCrunch",    "https://techcrunch.com/feed/"),
        ("Wired",         "https://www.wired.com/feed/rss"),
    ],
    "Business": [
        ("CNBC",          "https://www.cnbc.com/id/10001147/device/rss/rss.html"),
        ("MarketWatch",   "https://feeds.marketwatch.com/marketwatch/topstories/"),
        ("Bloomberg",     "https://feeds.bloomberg.com/markets/news.rss"),
    ],
    "Politics": [
        ("NPR Politics",  "https://feeds.npr.org/1004/rss.xml"),
        ("Politico",      "https://rss.politico.com/politics-news.xml"),
        ("The Atlantic",  "https://www.theatlantic.com/feed/all/"),
    ],
    "Sports": [
        ("ESPN",          "https://www.espn.com/espn/rss/news"),
        ("BBC Sport",     "https://feeds.bbci.co.uk/sport/rss.xml"),
        ("CBS Sports",    "https://www.cbssports.com/rss/headlines/"),
    ],
    "Science": [
        ("Science Daily", "https://www.sciencedaily.com/rss/top/science.xml"),
        ("New Scientist", "https://feeds.newscientist.com/full-strength-new-scientist"),
        ("NASA",          "https://www.nasa.gov/rss/dyn/breaking_news.rss"),
    ],
    "Entertainment": [
        ("Variety",            "https://variety.com/feed/"),
        ("Hollywood Reporter", "https://www.hollywoodreporter.com/feed/"),
        ("Rolling Stone",      "https://www.rollingstone.com/music/music-news/feed/"),
    ],
}

MAX_PER_FEED = 6          # articles taken from each feed per scrape
FETCH_TIMEOUT = 15        # seconds before feedparser gives up on a URL


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _stable_id(url: str, title: str) -> str:
    """Deterministic UUID so likes/bookmarks survive a re-scrape."""
    key = url or title
    return str(uuid.uuid5(uuid.NAMESPACE_URL, key))


def _extract_image(entry) -> str | None:
    # 1. media:thumbnail
    thumbs = getattr(entry, "media_thumbnail", None)
    if thumbs:
        return thumbs[0].get("url")

    # 2. media:content with image mime
    for mc in getattr(entry, "media_content", []):
        mime = mc.get("type", "")
        url  = mc.get("url", "")
        if mime.startswith("image") or url.lower().endswith((".jpg", ".jpeg", ".png", ".webp")):
            return url

    # 3. First <img> in content or summary HTML
    html = ""
    content = getattr(entry, "content", None)
    if content:
        html = content[0].get("value", "")
    if not html:
        html = getattr(entry, "summary", "")
    if html and "<" in html:   # only parse if it actually looks like HTML
        soup = BeautifulSoup(html, "html.parser")
        img  = soup.find("img")
        if img:
            src = img.get("src") or img.get("data-src", "")
            if src and src.startswith("http"):
                return src

    # 4. Enclosures
    for enc in getattr(entry, "enclosures", []):
        if enc.get("type", "").startswith("image"):
            return enc.get("url")

    return None


def _clean_html(raw: str) -> str:
    if "<" not in raw:          # plain text already — skip the parser
        return " ".join(raw.split())
    soup = BeautifulSoup(raw, "html.parser")
    return " ".join(soup.get_text(separator=" ").split())


def _fetch_full_content(url: str) -> tuple[str | None, str | None]:
    """
    Fetch the article page once and return (body_text, image_url).
    image_url comes from og:image / twitter:image meta tags — the canonical
    high-res thumbnail every modern news site sets for social sharing.
    """
    try:
        html = trafilatura.fetch_url(url)
        if not html:
            return None, None

        # Body
        text = trafilatura.extract(
            html,
            include_comments=False,
            include_tables=False,
            no_fallback=False,
        )
        body = text.strip() if text else None

        # Image — try Open Graph then Twitter Card
        soup = BeautifulSoup(html, "html.parser")
        image_url: str | None = None
        for attr, name in [("property", "og:image"), ("name", "twitter:image")]:
            tag = soup.find("meta", attrs={attr: name})
            if tag:
                image_url = tag.get("content") or None
            if image_url:
                break

        return body, image_url
    except Exception:
        return None, None


def _parse_date(entry) -> str:
    parsed = getattr(entry, "published_parsed", None)
    if parsed:
        try:
            ts = time.mktime(parsed)
            return datetime.fromtimestamp(ts, tz=timezone.utc).isoformat()
        except Exception:
            pass
    return datetime.now(timezone.utc).isoformat()


def _make_excerpt(body: str, max_chars: int = 220) -> str:
    if len(body) <= max_chars:
        return body
    truncated = body[:max_chars]
    last_space = truncated.rfind(" ")
    return (truncated[:last_space] if last_space > 0 else truncated) + "…"


# ---------------------------------------------------------------------------
# Per-feed parse  (runs synchronously in a thread pool)
# ---------------------------------------------------------------------------

def _parse_feed(source: str, category: str, feed_url: str) -> list[dict]:
    feed = feedparser.parse(feed_url, request_headers={"User-Agent": "NewsHawkBot/1.0"})
    articles = []

    for entry in feed.entries[:MAX_PER_FEED]:
        title = (entry.get("title") or "").strip()
        if not title:
            continue

        link = entry.get("link", "")

        # Fetch the article page once — get full body AND og:image in one request
        page_body, page_image = _fetch_full_content(link) if link else (None, None)

        # Body: prefer full scraped text, fall back to RSS summary
        if page_body:
            body = page_body
        else:
            raw_body = ""
            content = getattr(entry, "content", None)
            if content:
                raw_body = content[0].get("value", "")
            if not raw_body:
                raw_body = getattr(entry, "summary", "")
            body = _clean_html(raw_body) if raw_body else title

        # Image: prefer RSS media tags (already embedded, high quality),
        # then fall back to the og:image scraped from the article page.
        image_url = _extract_image(entry) or page_image

        excerpt = _make_excerpt(body)

        articles.append({
            "id":          _stable_id(link, title),
            "title":       title,
            "excerpt":     excerpt,
            "body":        body,
            "imageURL":    image_url,
            "source":      source,
            "category":    category,
            "publishedAt": _parse_date(entry),
            "url":         link,
        })

    return articles


# ---------------------------------------------------------------------------
# Political-bias rating  (async, cached per article ID)
# ---------------------------------------------------------------------------

async def _rate_bias(article_id: str, title: str, excerpt: str) -> float:
    """
    Returns a bias score in [-1.0, 1.0].
    -1 = strongly left-leaning, 0 = neutral, +1 = strongly right-leaning.
    Cached so each article is only sent to the API once.
    """
    if article_id in _bias_cache:
        return _bias_cache[article_id]

    prompt = (
        "Rate the political bias of this news article on a scale from -1.0 to 1.0. "
        "-1.0 means strongly left-leaning, 0.0 means neutral/centrist, "
        "1.0 means strongly right-leaning. "
        "Reply with ONLY a decimal number and nothing else.\n\n"
        f"Title: {title}\nSummary: {excerpt}"
    )
    try:
        response = await _openai.chat.completions.create(
            model="gpt-4o-mini",
            messages=[{"role": "user", "content": prompt}],
            max_tokens=10,
            temperature=0,
        )
        raw = response.choices[0].message.content.strip()
        score = float(raw)
        score = max(-1.0, min(1.0, score))
    except Exception as exc:
        print(f"[bias] rating failed for '{title[:40]}': {exc}")
        score = 0.0

    _bias_cache[article_id] = score
    return score


# ---------------------------------------------------------------------------
# Async orchestrator
# ---------------------------------------------------------------------------

async def scrape_all() -> list[dict]:
    loop = asyncio.get_event_loop()

    tasks = [
        loop.run_in_executor(None, _parse_feed, source, category, url)
        for category, feeds in RSS_FEEDS.items()
        for source, url in feeds
    ]

    results = await asyncio.gather(*tasks, return_exceptions=True)

    articles: list[dict] = []
    for r in results:
        if isinstance(r, list):
            articles.extend(r)
        else:
            print(f"[scraper] feed error: {r}")

    # Newest first
    articles.sort(key=lambda a: a["publishedAt"], reverse=True)
    print(f"[scraper] collected {len(articles)} articles from {len(tasks)} feeds")

    # Rate political bias — cached articles return instantly, new ones hit the API
    bias_tasks = [_rate_bias(a["id"], a["title"], a["excerpt"]) for a in articles]
    scores = await asyncio.gather(*bias_tasks, return_exceptions=True)
    for article, score in zip(articles, scores):
        article["bias"] = score if isinstance(score, float) else 0.0
    new_rated = sum(1 for a in articles if a["id"] not in _bias_cache or True)
    print(f"[bias] ratings complete ({len(_bias_cache)} total cached)")

    return articles
