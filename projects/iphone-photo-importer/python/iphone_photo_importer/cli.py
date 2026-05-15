from __future__ import annotations

import argparse
from dataclasses import replace
import json
from datetime import datetime
from pathlib import Path

from .ingest import apply_plan, build_plan, summarize
from .usb_bridge import build_staging_root, list_devices, scan_device, stage_device


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="iphone-photo-importer",
        description="Plan or run iPhone photo archive imports on Windows.",
    )
    subparsers = parser.add_subparsers(dest="command", required=True)

    usb_devices = subparsers.add_parser("usb-devices")
    usb_devices.add_argument("--json", action="store_true")

    for command_name in ("plan", "import"):
        command = subparsers.add_parser(command_name)
        command.add_argument("--source", required=True)
        command.add_argument("--library", required=True)
        command.add_argument("--state-db")
        command.add_argument("--source-kind", choices=("folder", "icloud", "usb"), default="folder")
        command.add_argument("--limit", type=int)
        command.add_argument("--json", action="store_true")

    return parser


def get_state_db(args: argparse.Namespace, library_root: Path) -> Path:
    if args.state_db:
        return Path(args.state_db)
    return library_root / ".state" / "imports.sqlite3"


def emit(payload: dict[str, object], as_json: bool) -> None:
    if as_json:
        print(json.dumps(payload, indent=2))
        return

    if payload["command"] == "usb-devices":
        devices = payload["devices"]
        print(f"USB devices: {len(devices)}")
        for device in devices:
            print(f"- {device['name']} ({device['type']})")
        for line in payload.get("diagnostics", []):
            print(line)
        return

    summary = payload["summary"]
    print(f"Total: {summary['total']}")
    print(f"Importable: {summary['importable']}")
    print(f"Imported: {summary['imported']}")
    print(f"Duplicates: {summary['duplicates']}")
    print(f"Unsupported: {summary['unsupported']}")
    print(f"Failed: {summary['failed']}")


def write_report(library_root: Path, payload: dict[str, object]) -> Path:
    report_dir = library_root / ".reports"
    report_dir.mkdir(parents=True, exist_ok=True)
    report_path = report_dir / f"import-report-{datetime.now():%Y%m%d-%H%M%S}.json"
    report_path.write_text(json.dumps(payload, indent=2), encoding="utf-8")
    return report_path


def iso_range(items: list[dict[str, object]]) -> tuple[str | None, str | None]:
    captured_dates = [item["captured_at"] for item in items if item.get("captured_at")]
    if not captured_dates:
        return None, None
    return min(captured_dates), max(captured_dates)


def summarize_usb_scan(items: list[dict[str, object]]) -> dict[str, int | str | None]:
    earliest, latest = iso_range(items)
    return {
        "total": len(items),
        "importable": sum(1 for item in items if item["action"] == "stage"),
        "ready_to_import": sum(1 for item in items if item["action"] == "stage"),
        "imported": 0,
        "duplicates": 0,
        "unsupported": sum(1 for item in items if item["action"] == "unsupported"),
        "failed": sum(1 for item in items if item["action"] == "failed"),
        "bytes_to_copy": sum(item["size"] for item in items if item["action"] == "stage"),
        "earliest_capture_at": earliest,
        "latest_capture_at": latest,
    }


def summarize_usb_stage(items: list[dict[str, object]]) -> dict[str, int]:
    return {
        "total": len(items),
        "staged": sum(1 for item in items if item["action"] == "staged"),
        "unsupported": sum(1 for item in items if item["action"] == "unsupported"),
        "failed": sum(1 for item in items if item["action"] == "failed"),
    }


def format_usb_items(entries: list[dict[str, object]]) -> list[dict[str, object]]:
    items: list[dict[str, object]] = []
    for entry in entries:
        action = entry["action"]
        items.append(
            {
                "action": "stage" if action == "stage" else action,
                "source_path": entry["device_path"],
                "original_source_path": entry["device_path"],
                "relative_path": entry["relative_path"],
                "staged_path": entry.get("staged_path"),
                "media_type": entry["media_type"],
                "size": entry["size"],
                "captured_at": entry.get("modified_at"),
                "date_source": "device_modified_time" if entry.get("modified_at") else None,
                "reason": entry.get("reason"),
            }
        )
    return items


def build_stage_issue_items(stage_items: list[dict[str, object]]) -> list[dict[str, object]]:
    return [item for item in stage_items if item["action"] in {"unsupported", "failed"}]


def merge_usb_import_summary(
    import_summary: dict[str, int | str | None],
    stage_issue_items: list[dict[str, object]],
) -> dict[str, int | str | None]:
    if not stage_issue_items:
        return import_summary

    summary = dict(import_summary)
    summary["total"] = int(summary["total"]) + len(stage_issue_items)
    summary["importable"] = int(summary["importable"]) + sum(1 for item in stage_issue_items if item["action"] == "failed")
    summary["failed"] = int(summary["failed"]) + sum(1 for item in stage_issue_items if item["action"] == "failed")
    summary["unsupported"] = int(summary["unsupported"]) + sum(1 for item in stage_issue_items if item["action"] == "unsupported")
    return summary


def run_usb_devices(args: argparse.Namespace) -> int:
    payload = list_devices()
    emit(payload, args.json)
    return 0


def run_plan(args: argparse.Namespace) -> int:
    library_root = Path(args.library)
    if args.source_kind == "usb":
        scan_payload = scan_device(args.source)
        items = format_usb_items(scan_payload["items"])
        payload = {
            "command": "plan",
            "source_kind": args.source_kind,
            "source": args.source,
            "library": str(library_root),
            "summary": summarize_usb_scan(items),
            "items": items,
            "usb": {
                "mode": "experimental",
                "device": scan_payload["device"],
                "message": "USB preview enumerates device media first. Duplicate detection happens during import after staging files to disk.",
            },
        }
        emit(payload, args.json)
        return 0

    source_root = Path(args.source)
    state_db = get_state_db(args, library_root)
    plan = build_plan(
        source_root=source_root,
        library_root=library_root,
        state_db=state_db,
        source_kind=args.source_kind,
        limit=args.limit,
    )
    payload = {
        "command": "plan",
        "source_kind": args.source_kind,
        "source": str(source_root),
        "library": str(library_root),
        "summary": summarize(plan),
        "items": [item.to_dict() for item in plan],
    }
    emit(payload, args.json)
    return 0


def run_import(args: argparse.Namespace) -> int:
    library_root = Path(args.library)
    state_db = get_state_db(args, library_root)

    if args.source_kind == "usb":
        staging_root = build_staging_root(args.source)
        stage_payload = stage_device(args.source, staging_root)
        stage_items = format_usb_items(stage_payload["items"])
        stage_issue_items = build_stage_issue_items(stage_items)
        source_map = {
            entry["staged_path"]: entry["source_path"]
            for entry in stage_items
            if entry["action"] == "staged" and entry.get("staged_path")
        }
        plan = build_plan(
            source_root=staging_root,
            library_root=library_root,
            state_db=state_db,
            source_kind=args.source_kind,
            limit=args.limit,
        )
        results = apply_plan(
            library_root=library_root,
            state_db=state_db,
            source_kind=args.source_kind,
            plan=plan,
        )
        results = [
            replace(item, original_source_path=source_map.get(str(item.source_path), item.original_source_path))
            for item in results
        ]
        import_items = [item.to_dict() for item in results]
        summary = merge_usb_import_summary(summarize(results), stage_issue_items)
        payload = {
            "command": "import",
            "source_kind": args.source_kind,
            "source": args.source,
            "library": str(library_root),
            "summary": summary,
            "items": stage_issue_items + import_items,
            "usb": {
                "mode": "experimental",
                "device": stage_payload["device"],
                "staging_root": str(staging_root),
                "stage_summary": summarize_usb_stage(stage_items),
                "stage_items": stage_items,
            },
        }
        payload["report_path"] = str(write_report(library_root, payload))
        emit(payload, args.json)
        return 0

    source_root = Path(args.source)
    plan = build_plan(
        source_root=source_root,
        library_root=library_root,
        state_db=state_db,
        source_kind=args.source_kind,
        limit=args.limit,
    )
    results = apply_plan(
        library_root=library_root,
        state_db=state_db,
        source_kind=args.source_kind,
        plan=plan,
    )
    payload = {
        "command": "import",
        "source_kind": args.source_kind,
        "source": str(source_root),
        "library": str(library_root),
        "summary": summarize(results),
        "items": [item.to_dict() for item in results],
    }
    payload["report_path"] = str(write_report(library_root, payload))
    emit(payload, args.json)
    return 0


def main() -> int:
    parser = build_parser()
    args = parser.parse_args()

    if args.command == "usb-devices":
        return run_usb_devices(args)
    if args.command == "plan":
        return run_plan(args)
    if args.command == "import":
        return run_import(args)

    parser.error(f"Unknown command: {args.command}")
    return 2


if __name__ == "__main__":
    raise SystemExit(main())
