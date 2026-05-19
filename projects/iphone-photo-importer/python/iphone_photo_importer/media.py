from __future__ import annotations

import hashlib
import re
from datetime import datetime
from pathlib import Path

SUPPORTED_EXTENSIONS = {
    ".aae",
    ".gif",
    ".heic",
    ".heif",
    ".jpeg",
    ".jpg",
    ".mov",
    ".mp4",
    ".png",
}


def iter_media_files(source_root: Path):
    for path in sorted(source_root.rglob("*")):
        if path.is_file():
            yield path


def compute_sha256(file_path: Path) -> str:
    digest = hashlib.sha256()
    with file_path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def detect_captured_at(file_path: Path) -> tuple[datetime, str]:
    return datetime.fromtimestamp(file_path.stat().st_mtime), "modified_time"


def detect_media_type(file_path: Path) -> str:
    suffix = file_path.suffix.lower().lstrip(".")
    return suffix or "unknown"


def is_supported(file_path: Path) -> bool:
    return file_path.suffix.lower() in SUPPORTED_EXTENSIONS


def build_destination_relpath(source_path: Path, captured_at: datetime, sha256_hex: str) -> Path:
    safe_stem = re.sub(r"[^A-Za-z0-9._-]+", "_", source_path.stem).strip("._") or "asset"
    file_name = f"{safe_stem}-{sha256_hex[:8]}{source_path.suffix.lower()}"
    return Path(f"{captured_at:%Y}") / f"{captured_at:%Y-%m}" / file_name
