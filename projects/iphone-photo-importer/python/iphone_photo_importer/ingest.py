from __future__ import annotations

from dataclasses import replace
import shutil
from datetime import datetime
from pathlib import Path

from .library import ImportState
from .media import (
    build_destination_relpath,
    compute_sha256,
    detect_captured_at,
    detect_media_type,
    is_supported,
    iter_media_files,
)
from .models import PlannedItem


def build_plan(
    *,
    source_root: Path,
    library_root: Path,
    state_db: Path,
    source_kind: str,
    limit: int | None = None,
) -> list[PlannedItem]:
    source_root = source_root.resolve()
    library_root = library_root.resolve()

    if not source_root.exists():
        raise FileNotFoundError(f"Source folder does not exist: {source_root}")

    planned_items: list[PlannedItem] = []
    planned_hashes: dict[str, Path] = {}

    with ImportState(state_db) as state:
        for index, media_path in enumerate(iter_media_files(source_root), start=1):
            media_type = detect_media_type(media_path)
            size_bytes = media_path.stat().st_size

            if not is_supported(media_path):
                planned_items.append(
                    PlannedItem(
                        source_path=media_path,
                        action="unsupported",
                        media_type=media_type,
                        size=size_bytes,
                        reason="unsupported_extension",
                    )
                )
                if limit is not None and index >= limit:
                    break
                continue

            try:
                sha256_hex = compute_sha256(media_path)
                captured_at, date_source = detect_captured_at(media_path)
                destination_relpath = build_destination_relpath(media_path, captured_at, sha256_hex)
                existing = state.lookup(sha256_hex)
            except OSError as error:
                planned_items.append(
                    PlannedItem(
                        source_path=media_path,
                        action="failed",
                        media_type=media_type,
                        size=size_bytes,
                        reason=str(error),
                    )
                )
                if limit is not None and index >= limit:
                    break
                continue

            if existing is not None:
                planned_items.append(
                    PlannedItem(
                        source_path=media_path,
                        action="duplicate",
                        media_type=media_type,
                        size=size_bytes,
                        sha256=sha256_hex,
                        captured_at=captured_at,
                        date_source=date_source,
                        destination_relpath=destination_relpath,
                        duplicate_of=existing,
                    )
                )
            elif sha256_hex in planned_hashes:
                planned_items.append(
                    PlannedItem(
                        source_path=media_path,
                        action="duplicate",
                        media_type=media_type,
                        size=size_bytes,
                        sha256=sha256_hex,
                        captured_at=captured_at,
                        date_source=date_source,
                        destination_relpath=destination_relpath,
                        duplicate_of=str(library_root / planned_hashes[sha256_hex]),
                    )
                )
            else:
                planned_hashes[sha256_hex] = destination_relpath
                planned_items.append(
                    PlannedItem(
                        source_path=media_path,
                        action="import",
                        media_type=media_type,
                        size=size_bytes,
                        sha256=sha256_hex,
                        captured_at=captured_at,
                        date_source=date_source,
                        destination_relpath=destination_relpath,
                    )
                )

            if limit is not None and index >= limit:
                break

    return planned_items


def apply_plan(
    *,
    library_root: Path,
    state_db: Path,
    source_kind: str,
    plan: list[PlannedItem],
) -> list[PlannedItem]:
    library_root = library_root.resolve()
    library_root.mkdir(parents=True, exist_ok=True)

    results: list[PlannedItem] = []

    with ImportState(state_db) as state:
        for item in plan:
            if item.action != "import":
                results.append(item)
                continue

            destination = library_root / item.destination_relpath
            destination.parent.mkdir(parents=True, exist_ok=True)

            if destination.exists():
                destination = destination.with_stem(f"{destination.stem}-{item.sha256[8:12]}")

            try:
                shutil.copy2(item.source_path, destination)
                state.record(
                    sha256_hex=item.sha256,
                    source_path=item.source_path,
                    stored_path=destination,
                    size_bytes=item.size,
                    captured_at=item.captured_at,
                    source_kind=source_kind,
                )
                results.append(replace(item, action="imported", final_path=destination))
            except OSError as error:
                results.append(replace(item, action="failed", reason=str(error)))

    return results


def summarize(items: list[PlannedItem]) -> dict[str, int | str | None]:
    captured_dates = [item.captured_at for item in items if item.captured_at is not None]
    importable_items = [item for item in items if item.action in {"import", "imported", "failed"}]

    return {
        "total": len(items),
        "importable": len(importable_items),
        "ready_to_import": sum(1 for item in items if item.action == "import"),
        "imported": sum(1 for item in items if item.action == "imported"),
        "duplicates": sum(1 for item in items if item.action == "duplicate"),
        "unsupported": sum(1 for item in items if item.action == "unsupported"),
        "failed": sum(1 for item in items if item.action == "failed"),
        "bytes_to_copy": sum(item.size for item in items if item.action in {"import", "imported"}),
        "earliest_capture_at": min(captured_dates).isoformat() if captured_dates else None,
        "latest_capture_at": max(captured_dates).isoformat() if captured_dates else None,
    }
