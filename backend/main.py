"""
Nighthawk News  —  Backend API
==============================
Scrapes RSS feeds from reputable outlets, caches results in memory,
and refreshes every 30 minutes automatically.

Start:
    python main.py
    # or
    uvicorn main:app --reload --port 8000

Endpoints:
    GET /articles              → all articles (newest first)
    GET /articles?category=Tech → filtered by category
    GET /health                → cache status
"""

import asyncio
import uvicorn
from fastapi import FastAPI, Query
from fastapi.middleware.cors import CORSMiddleware
from typing import Optional

from scraper import scrape_all
from cache import ArticleCache

app   = FastAPI(title="Nighthawk News API")
cache = ArticleCache()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["GET"],
    allow_headers=["*"],
)


# ---------------------------------------------------------------------------
# Background refresh loop
# ---------------------------------------------------------------------------

async def _refresh_loop() -> None:
    """Scrape immediately, then repeat every REFRESH_INTERVAL_SECONDS."""
    while True:
        try:
            articles = await scrape_all()
            cache.set(articles)
            print(f"[cache] updated — {len(articles)} articles stored")
        except Exception as exc:
            print(f"[cache] refresh failed: {exc}")

        await asyncio.sleep(ArticleCache.REFRESH_INTERVAL_SECONDS)


@app.on_event("startup")
async def startup() -> None:
    # Fire-and-forget: first scrape starts immediately in the background
    asyncio.create_task(_refresh_loop())


# ---------------------------------------------------------------------------
# Routes
# ---------------------------------------------------------------------------

@app.get("/articles")
async def get_articles(category: Optional[str] = Query(default=None)):
    """
    Returns articles from cache. Responds in < 5 ms because no I/O happens here.
    The cache is populated/refreshed by the background task.
    """
    return cache.get(category=category)


@app.get("/health")
async def health():
    return {
        "status":           "ok",
        "article_count":    len(cache.get()),
        "last_updated":     cache.last_updated_iso,
        "next_refresh_in":  f"{cache.next_refresh_in // 60}m {cache.next_refresh_in % 60}s",
    }


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=False)
