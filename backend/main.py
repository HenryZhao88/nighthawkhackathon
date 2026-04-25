"""
NighthawkNews  —  Backend API

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
from fastapi import BackgroundTasks, FastAPI, HTTPException, Query, Request
from fastapi.middleware.cors import CORSMiddleware
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.errors import RateLimitExceeded
from slowapi.util import get_remote_address
from typing import Optional

from pydantic import BaseModel
from scraper import scrape_all
from cache import ArticleCache
from recommender import build_feed, update_profile

cache = ArticleCache()
limiter = Limiter(key_func=get_remote_address)
_refresh_lock = asyncio.Lock()
_on_demand_refresh: asyncio.Task[None] | None = None

# How many days of articles to retain in the DB.
RETENTION_DAYS = int(os.getenv("NIGHTHAWK_RETENTION_DAYS", "14"))


async def _refresh_once(reason: str) -> None:
    async with _refresh_lock:
        try:
            articles = await scrape_all()
            cache.set(articles)
            pruned = cache.db.prune_older_than(RETENTION_DAYS)
            print(f"[cache] {reason} update — {len(articles)} scraped, "
                  f"{pruned} pruned, {cache.db.count()} total in DB")
        except Exception as exc:
            print(f"[cache] {reason} refresh failed: {exc}")


def _schedule_refresh_if_stale() -> None:
    """Wake stopped Fly machines into a refresh without blocking requests."""
    global _on_demand_refresh
    if not cache.is_stale or _refresh_lock.locked():
        return
    if _on_demand_refresh and not _on_demand_refresh.done():
        return
    _on_demand_refresh = asyncio.create_task(_refresh_once("on-demand"))


async def _refresh_loop() -> None:
    """Scrape immediately on startup, then every REFRESH_INTERVAL_SECONDS."""
    while True:
        await _refresh_once("scheduled")
        await asyncio.sleep(ArticleCache.REFRESH_INTERVAL_SECONDS)


@asynccontextmanager
async def lifespan(app: FastAPI):
    task = asyncio.create_task(_refresh_loop())
    yield
    task.cancel()
    if _on_demand_refresh:
        _on_demand_refresh.cancel()


app = FastAPI(
    title="NighthawkNews API",
    lifespan=lifespan,
    docs_url=None,          # hide /docs publicly
    redoc_url=None,
    openapi_url=None,
)
app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

# Public API: GET for reads, POST for interaction ingestion.
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["GET", "POST"],
    allow_headers=["*"],
)


# ---------------------------------------------------------------------------
# Request / response models for the recommendation endpoints
# ---------------------------------------------------------------------------

class Interaction(BaseModel):
    article_id: str
    interaction: str
    dwell_ms: int = 0
    timestamp: str

class InteractionBatch(BaseModel):
    user_id: str
    interactions: list[Interaction]

class StateMutation(BaseModel):
    article_id: str
    kind: str           # "liked" | "bookmarked" | "viewed"
    value: bool         # true = set, false = unset


# ---------------------------------------------------------------------------
# Endpoints
# ---------------------------------------------------------------------------

@app.post("/interactions")
@limiter.limit("120/minute")
async def post_interactions(
    request: Request,
    body: InteractionBatch,
    background_tasks: BackgroundTasks,
):
    """Ingest a batch of user interaction signals and recompute the profile."""
    recorded = cache.db.record_interactions(
        body.user_id,
        [i.model_dump() for i in body.interactions],
    )
    background_tasks.add_task(update_profile, cache.db, body.user_id)
    return {"recorded": recorded}


@app.get("/feed")
@limiter.limit("60/minute")
async def get_feed(
    request: Request,
    user_id: str = Query(default=""),
    session_seen: str = Query(default=""),
    count: int = Query(default=30, ge=1, le=100),
):
    """Return a personalised feed ranked by the 5-stage pipeline."""
    _schedule_refresh_if_stale()
    seen_ids = [s.strip() for s in session_seen.split(",") if s.strip()]
    ranked = build_feed(cache.db, user_id, seen_ids, count)
    return ranked


@app.get("/articles")
@limiter.limit("60/minute")
async def get_articles(request: Request, category: Optional[str] = Query(default=None)):
    _schedule_refresh_if_stale()
    return cache.get(category=category)


@app.get("/users/{user_id}/state")
@limiter.limit("60/minute")
async def get_user_state(request: Request, user_id: str):
    """Return the user's current liked / bookmarked / viewed article ID lists.
    Used by the iOS client on sign-in to seed local state from the server so
    bookmarks etc. are visible across devices."""
    return cache.db.get_user_state(user_id)


@app.post("/users/{user_id}/state")
@limiter.limit("180/minute")
async def post_user_state(request: Request, user_id: str, body: StateMutation):
    """Set or unset a single (user, article, kind) tuple. Idempotent."""
    if body.kind not in ("liked", "bookmarked", "viewed"):
        raise HTTPException(status_code=400, detail="invalid kind")
    if body.value:
        cache.db.set_user_state(user_id, body.article_id, body.kind)
    else:
        cache.db.unset_user_state(user_id, body.article_id, body.kind)
    return {"ok": True}


@app.get("/health")
@limiter.limit("30/minute")
async def health(request: Request):
    _schedule_refresh_if_stale()
    return {
        "status":          "ok",
        "article_count":   cache.db.count(),
        "last_updated":    cache.last_updated_iso,
        "next_refresh_in": f"{cache.next_refresh_in // 60}m {cache.next_refresh_in % 60}s",
    }


if __name__ == "__main__":
    port = int(os.getenv("PORT", "8000"))
    uvicorn.run("main:app", host="0.0.0.0", port=port, reload=False)
