from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime
from pathlib import Path


@dataclass(slots=True)
class PlannedItem:
    source_path: Path
    action: str
    media_type: str
    size: int
    original_source_path: str | None = None
    sha256: str | None = None
    captured_at: datetime | None = None
    date_source: str | None = None
    destination_relpath: Path | None = None
    final_path: Path | None = None
    duplicate_of: str | None = None
    reason: str | None = None

    def to_dict(self) -> dict[str, object]:
        return {
            "action": self.action,
            "source_path": str(self.source_path),
            "original_source_path": self.original_source_path,
            "media_type": self.media_type,
            "size": self.size,
            "sha256": self.sha256,
            "captured_at": self.captured_at.isoformat() if self.captured_at else None,
            "date_source": self.date_source,
            "destination_relpath": str(self.destination_relpath) if self.destination_relpath else None,
            "final_path": str(self.final_path) if self.final_path else None,
            "duplicate_of": self.duplicate_of,
            "reason": self.reason,
        }
