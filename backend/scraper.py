import asyncio
import feedparser
import uuid
import time
from datetime import datetime, timezone
from bs4 import BeautifulSoup

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
    if html:
        soup = BeautifulSoup(html, "lxml")
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
    soup = BeautifulSoup(raw, "lxml")
    return " ".join(soup.get_text(separator=" ").split())


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
    feed = feedparser.parse(feed_url, request_headers={"User-Agent": "NighthawkNewsBot/1.0"})
    articles = []

    for entry in feed.entries[:MAX_PER_FEED]:
        title = (entry.get("title") or "").strip()
        if not title:
            continue

        link = entry.get("link", "")

        # Body: prefer full content, fall back to summary
        raw_body = ""
        content = getattr(entry, "content", None)
        if content:
            raw_body = content[0].get("value", "")
        if not raw_body:
            raw_body = getattr(entry, "summary", "")

        body    = _clean_html(raw_body) if raw_body else title
        excerpt = _make_excerpt(body)

        articles.append({
            "id":          _stable_id(link, title),
            "title":       title,
            "excerpt":     excerpt,
            "body":        body,
            "imageURL":    _extract_image(entry),
            "source":      source,
            "category":    category,
            "publishedAt": _parse_date(entry),
            "url":         link,
        })

    return articles


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
    return articles
