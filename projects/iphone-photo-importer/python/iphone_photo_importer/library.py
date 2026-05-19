from __future__ import annotations

import sqlite3
from datetime import datetime
from pathlib import Path

SCHEMA = """
CREATE TABLE IF NOT EXISTS imports (
    sha256 TEXT PRIMARY KEY,
    source_path TEXT NOT NULL,
    stored_path TEXT NOT NULL,
    size_bytes INTEGER NOT NULL,
    captured_at TEXT NOT NULL,
    imported_at TEXT NOT NULL,
    source_kind TEXT NOT NULL
);
"""


class ImportState:
    def __init__(self, db_path: Path) -> None:
        self.db_path = db_path
        self._connection: sqlite3.Connection | None = None

    def __enter__(self) -> "ImportState":
        self.db_path.parent.mkdir(parents=True, exist_ok=True)
        self._connection = sqlite3.connect(self.db_path)
        self._connection.execute(SCHEMA)
        self._connection.commit()
        return self

    def __exit__(self, exc_type, exc, tb) -> None:
        if self._connection is None:
            return
        if exc is None:
            self._connection.commit()
        self._connection.close()
        self._connection = None

    @property
    def connection(self) -> sqlite3.Connection:
        if self._connection is None:
            raise RuntimeError("ImportState connection is not open.")
        return self._connection

    def lookup(self, sha256_hex: str) -> str | None:
        row = self.connection.execute(
            "SELECT stored_path FROM imports WHERE sha256 = ?",
            (sha256_hex,),
        ).fetchone()
        return row[0] if row else None

    def record(
        self,
        *,
        sha256_hex: str,
        source_path: Path,
        stored_path: Path,
        size_bytes: int,
        captured_at: datetime,
        source_kind: str,
    ) -> None:
        self.connection.execute(
            """
            INSERT OR REPLACE INTO imports
            (sha256, source_path, stored_path, size_bytes, captured_at, imported_at, source_kind)
            VALUES (?, ?, ?, ?, ?, ?, ?)
            """,
            (
                sha256_hex,
                str(source_path),
                str(stored_path),
                size_bytes,
                captured_at.isoformat(),
                datetime.now().isoformat(timespec="seconds"),
                source_kind,
            ),
        )

