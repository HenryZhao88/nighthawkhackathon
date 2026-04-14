"""
Nighthawk News  —  Backend API
==============================
Scrapes RSS feeds from reputable outlets, caches results in memory,
and refreshes every 30 minutes automatically.

Start:
    ./start.sh
    # or directly:
    .venv/bin/python main.py

Endpoints:
    GET /articles              → all articles (newest first)
    GET /articles?category=Tech → filtered by category
    GET /health                → cache status
"""

import asyncio
import uvicorn
from contextlib import asynccontextmanager
from fastapi import FastAPI, Query
from fastapi.middleware.cors import CORSMiddleware
from typing import Optional

from scraper import scrape_all
from cache import ArticleCache

cache = ArticleCache()


# ---------------------------------------------------------------------------
# Background refresh loop  (modern lifespan pattern, no deprecation warning)
# ---------------------------------------------------------------------------

async def _refresh_loop() -> None:
    """Scrape immediately on startup, then every REFRESH_INTERVAL_SECONDS."""
    while True:
        try:
            articles = await scrape_all()
            cache.set(articles)
            print(f"[cache] updated — {len(articles)} articles stored")
        except Exception as exc:
            print(f"[cache] refresh failed: {exc}")

        await asyncio.sleep(ArticleCache.REFRESH_INTERVAL_SECONDS)


@asynccontextmanager
async def lifespan(app: FastAPI):
    task = asyncio.create_task(_refresh_loop())
    yield
    task.cancel()


# ---------------------------------------------------------------------------
# App
# ---------------------------------------------------------------------------

app = FastAPI(title="Nighthawk News API", lifespan=lifespan)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["GET"],
    allow_headers=["*"],
)


# ---------------------------------------------------------------------------
# Routes
# ---------------------------------------------------------------------------

@app.get("/articles")
async def get_articles(category: Optional[str] = Query(default=None)):
    """
    Served entirely from cache — responds in < 5 ms.
    The background task keeps the cache fresh.
    """
    return cache.get(category=category)


@app.get("/health")
async def health():
    return {
        "status":          "ok",
        "article_count":   len(cache.get()),
        "last_updated":    cache.last_updated_iso,
        "next_refresh_in": f"{cache.next_refresh_in // 60}m {cache.next_refresh_in % 60}s",
    }


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=False)
