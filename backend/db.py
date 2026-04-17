"""
SQLite persistence for scraped articles.

The DB is a single file (path from NEWSHAWK_DB_PATH env var, default
./articles.db) holding one row per article keyed by stable UUID. Re-scrapes
UPSERT, so likes/bookmarks on the client stay pinned to the same IDs.

On Fly.io this file lives on a mounted volume so it survives deploys/restarts.
"""

import os
import json
import sqlite3
import threading
from datetime import datetime, timezone
from typing import Optional

DB_PATH = os.getenv("NEWSHAWK_DB_PATH", os.path.join(os.path.dirname(__file__), "articles.db"))

_SCHEMA = """
CREATE TABLE IF NOT EXISTS articles (
    id           TEXT PRIMARY KEY,
    title        TEXT NOT NULL,
    excerpt      TEXT NOT NULL,
    body         TEXT NOT NULL,
    image_url    TEXT,
    source       TEXT NOT NULL,
    category     TEXT NOT NULL,
    published_at TEXT NOT NULL,
    url          TEXT,
    bias         REAL,
    updated_at   TEXT NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_articles_category     ON articles(category);
CREATE INDEX IF NOT EXISTS idx_articles_published_at ON articles(published_at DESC);

CREATE TABLE IF NOT EXISTS bias_cache (
    article_id TEXT PRIMARY KEY,
    score      REAL NOT NULL
);

CREATE TABLE IF NOT EXISTS user_interactions (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id     TEXT NOT NULL,
    article_id  TEXT NOT NULL,
    interaction TEXT NOT NULL,
    dwell_ms    INTEGER DEFAULT 0,
    created_at  TEXT NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_interactions_user ON user_interactions(user_id);
CREATE INDEX IF NOT EXISTS idx_interactions_time ON user_interactions(created_at DESC);

CREATE TABLE IF NOT EXISTS user_profiles (
    user_id    TEXT PRIMARY KEY,
    profile    TEXT NOT NULL,
    updated_at TEXT NOT NULL
);
"""


class ArticleDB:
    """Thread-safe SQLite wrapper. FastAPI runs single-process so a lock is enough."""

    def __init__(self, path: str = DB_PATH) -> None:
        self.path = path
        os.makedirs(os.path.dirname(os.path.abspath(path)) or ".", exist_ok=True)
        self._lock = threading.Lock()
        self._conn = sqlite3.connect(path, check_same_thread=False, isolation_level=None)
        self._conn.row_factory = sqlite3.Row
        self._conn.execute("PRAGMA journal_mode=WAL;")
        self._conn.execute("PRAGMA synchronous=NORMAL;")
        with self._lock:
            self._conn.executescript(_SCHEMA)

    # ------------------------------------------------------------------
    # Articles

    def upsert_articles(self, articles: list[dict]) -> int:
        now = datetime.now(timezone.utc).isoformat()
        rows = [
            (
                a["id"], a["title"], a["excerpt"], a["body"], a.get("imageURL"),
                a["source"], a["category"], a["publishedAt"], a.get("url"),
                a.get("bias"), now,
            )
            for a in articles
        ]
        with self._lock:
            self._conn.executemany(
                """
                INSERT INTO articles (id, title, excerpt, body, image_url, source,
                                      category, published_at, url, bias, updated_at)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                ON CONFLICT(id) DO UPDATE SET
                    title=excluded.title,
                    excerpt=excluded.excerpt,
                    body=excluded.body,
                    image_url=excluded.image_url,
                    source=excluded.source,
                    category=excluded.category,
                    published_at=excluded.published_at,
                    url=excluded.url,
                    bias=COALESCE(excluded.bias, articles.bias),
                    updated_at=excluded.updated_at
                """,
                rows,
            )
        return len(rows)

    def list_articles(self, category: Optional[str] = None, limit: int = 500) -> list[dict]:
        with self._lock:
            if category and category != "All":
                cur = self._conn.execute(
                    "SELECT * FROM articles WHERE category = ? ORDER BY published_at DESC LIMIT ?",
                    (category, limit),
                )
            else:
                cur = self._conn.execute(
                    "SELECT * FROM articles ORDER BY published_at DESC LIMIT ?",
                    (limit,),
                )
            return [_row_to_dict(r) for r in cur.fetchall()]

    def count(self) -> int:
        with self._lock:
            return self._conn.execute("SELECT COUNT(*) FROM articles").fetchone()[0]

    def prune_older_than(self, days: int) -> int:
        """Remove articles whose publish date is older than N days. Returns rows deleted."""
        cutoff = (datetime.now(timezone.utc).timestamp() - days * 86400)
        cutoff_iso = datetime.fromtimestamp(cutoff, tz=timezone.utc).isoformat()
        with self._lock:
            cur = self._conn.execute(
                "DELETE FROM articles WHERE published_at < ?", (cutoff_iso,)
            )
            return cur.rowcount

    # ------------------------------------------------------------------
    # Bias cache

    def get_bias(self, article_id: str) -> Optional[float]:
        with self._lock:
            row = self._conn.execute(
                "SELECT score FROM bias_cache WHERE article_id = ?", (article_id,)
            ).fetchone()
        return row["score"] if row else None

    def set_bias(self, article_id: str, score: float) -> None:
        with self._lock:
            self._conn.execute(
                "INSERT INTO bias_cache (article_id, score) VALUES (?, ?) "
                "ON CONFLICT(article_id) DO UPDATE SET score=excluded.score",
                (article_id, score),
            )


    # ------------------------------------------------------------------
    # User interactions

    def record_interactions(self, user_id: str, interactions: list[dict]) -> int:
        with self._lock:
            self._conn.executemany(
                """
                INSERT INTO user_interactions (user_id, article_id, interaction, dwell_ms, created_at)
                VALUES (?, ?, ?, ?, ?)
                """,
                [
                    (user_id, i["article_id"], i["interaction"],
                     i.get("dwell_ms", 0), i["timestamp"])
                    for i in interactions
                ],
            )
        return len(interactions)

    def get_user_interactions(self, user_id: str, limit: int = 2000) -> list[dict]:
        with self._lock:
            cur = self._conn.execute(
                "SELECT article_id, interaction, dwell_ms, created_at "
                "FROM user_interactions WHERE user_id = ? "
                "ORDER BY created_at DESC LIMIT ?",
                (user_id, limit),
            )
            return [
                {
                    "article_id": r["article_id"],
                    "interaction": r["interaction"],
                    "dwell_ms": r["dwell_ms"],
                    "created_at": r["created_at"],
                }
                for r in cur.fetchall()
            ]

    # ------------------------------------------------------------------
    # User profiles (cached recommendation state)

    def upsert_profile(self, user_id: str, profile_json: str) -> None:
        now = datetime.now(timezone.utc).isoformat()
        with self._lock:
            self._conn.execute(
                "INSERT INTO user_profiles (user_id, profile, updated_at) "
                "VALUES (?, ?, ?) "
                "ON CONFLICT(user_id) DO UPDATE SET profile=excluded.profile, updated_at=excluded.updated_at",
                (user_id, profile_json, now),
            )

    def get_profile(self, user_id: str) -> Optional[str]:
        with self._lock:
            row = self._conn.execute(
                "SELECT profile FROM user_profiles WHERE user_id = ?", (user_id,)
            ).fetchone()
        return row["profile"] if row else None


def _row_to_dict(r: sqlite3.Row) -> dict:
    return {
        "id":          r["id"],
        "title":       r["title"],
        "excerpt":     r["excerpt"],
        "body":        r["body"],
        "imageURL":    r["image_url"],
        "source":      r["source"],
        "category":    r["category"],
        "publishedAt": r["published_at"],
        "url":         r["url"],
        "bias":        r["bias"],
    }
