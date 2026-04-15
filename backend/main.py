"""
NewsHawk News  —  Backend API

Public, read-only endpoints backed by a SQLite article store that is
refreshed from RSS feeds every 30 minutes.

Endpoints:
    GET /articles                → newest articles
    GET /articles?category=Tech  → filtered by category
    GET /health                  → basic cache/db status
"""

import asyncio
import os
import uvicorn
from contextlib import asynccontextmanager
from fastapi import FastAPI, Query, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.errors import RateLimitExceeded
from slowapi.util import get_remote_address
from typing import Optional

from scraper import scrape_all
from cache import ArticleCache

cache = ArticleCache()
limiter = Limiter(key_func=get_remote_address)

# How many days of articles to retain in the DB.
RETENTION_DAYS = int(os.getenv("NEWSHAWK_RETENTION_DAYS", "14"))


async def _refresh_loop() -> None:
    """Scrape immediately on startup, then every REFRESH_INTERVAL_SECONDS."""
    while True:
        try:
            articles = await scrape_all()
            cache.set(articles)
            pruned = cache.db.prune_older_than(RETENTION_DAYS)
            print(f"[cache] updated — {len(articles)} scraped, {pruned} pruned, "
                  f"{cache.db.count()} total in DB")
        except Exception as exc:
            print(f"[cache] refresh failed: {exc}")

        await asyncio.sleep(ArticleCache.REFRESH_INTERVAL_SECONDS)


@asynccontextmanager
async def lifespan(app: FastAPI):
    task = asyncio.create_task(_refresh_loop())
    yield
    task.cancel()


app = FastAPI(
    title="NewsHawk News API",
    lifespan=lifespan,
    docs_url=None,          # hide /docs publicly
    redoc_url=None,
    openapi_url=None,
)
app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

# Public API: any client may GET. No other methods are exposed.
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["GET"],
    allow_headers=["*"],
)


@app.get("/articles")
@limiter.limit("60/minute")
async def get_articles(request: Request, category: Optional[str] = Query(default=None)):
    return cache.get(category=category)


@app.get("/health")
@limiter.limit("30/minute")
async def health(request: Request):
    return {
        "status":          "ok",
        "article_count":   cache.db.count(),
        "last_updated":    cache.last_updated_iso,
        "next_refresh_in": f"{cache.next_refresh_in // 60}m {cache.next_refresh_in % 60}s",
    }


if __name__ == "__main__":
    port = int(os.getenv("PORT", "8000"))
    uvicorn.run("main:app", host="0.0.0.0", port=port, reload=False)
