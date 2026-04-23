"""
Thin facade over the SQLite article store.

Keeps the same API the rest of the app used for the old in-memory cache, but
every read/write now hits the DB so articles survive restarts.
"""

from datetime import datetime, timezone
from typing import Optional

from db import ArticleDB


class ArticleCache:
    REFRESH_INTERVAL_SECONDS = 30 * 60   # 30 minutes

    def __init__(self, db: Optional[ArticleDB] = None) -> None:
        self.db = db or ArticleDB()
        self._updated_at: Optional[datetime] = None

    # ------------------------------------------------------------------
    def set(self, articles: list[dict]) -> None:
        self.db.upsert_articles(articles)
        self._updated_at = datetime.now(timezone.utc)

    def get(self, category: Optional[str] = None) -> list[dict]:
        return self.db.list_articles(category=category)

    # ------------------------------------------------------------------
    @property
    def is_empty(self) -> bool:
        return self.db.count() == 0

    @property
    def last_updated_iso(self) -> Optional[str]:
        return self._updated_at.isoformat() if self._updated_at else None

    @property
    def next_refresh_in(self) -> int:
        if not self._updated_at:
            return 0
        elapsed = (datetime.now(timezone.utc) - self._updated_at).total_seconds()
        return max(0, int(self.REFRESH_INTERVAL_SECONDS - elapsed))

    @property
    def is_stale(self) -> bool:
        return self.next_refresh_in == 0
