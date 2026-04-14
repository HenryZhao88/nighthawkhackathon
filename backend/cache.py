from datetime import datetime, timezone
from typing import Optional


class ArticleCache:
    """
    Simple in-memory store. Thread-safe for reads; scraper writes happen
    from a single asyncio background task so no lock is needed.
    """

    REFRESH_INTERVAL_SECONDS = 30 * 60   # 30 minutes

    def __init__(self) -> None:
        self._articles: list[dict] = []
        self._updated_at: Optional[datetime] = None

    # ------------------------------------------------------------------
    def set(self, articles: list[dict]) -> None:
        self._articles  = articles
        self._updated_at = datetime.now(timezone.utc)

    def get(self, category: Optional[str] = None) -> list[dict]:
        if not category or category == "All":
            return self._articles
        return [a for a in self._articles if a["category"] == category]

    # ------------------------------------------------------------------
    @property
    def is_empty(self) -> bool:
        return len(self._articles) == 0

    @property
    def last_updated_iso(self) -> Optional[str]:
        return self._updated_at.isoformat() if self._updated_at else None

    @property
    def next_refresh_in(self) -> int:
        """Seconds until next scheduled refresh (for /health endpoint)."""
        if not self._updated_at:
            return 0
        elapsed = (datetime.now(timezone.utc) - self._updated_at).total_seconds()
        return max(0, int(self.REFRESH_INTERVAL_SECONDS - elapsed))
