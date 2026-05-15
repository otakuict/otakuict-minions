from __future__ import annotations

import json
import os
import re
import shutil
import subprocess
from datetime import datetime
from pathlib import Path

SCRIPT_PATH = Path(__file__).resolve().parent.parent / "scripts" / "windows_usb_bridge.ps1"


def _powershell_executable() -> str:
    return shutil.which("powershell") or shutil.which("pwsh") or "powershell"


def _ensure_list(value: object) -> list[object]:
    if value is None or value == {}:
        return []
    if isinstance(value, list):
        return value
    return [value]


def _normalize_payload(payload: dict[str, object]) -> dict[str, object]:
    if "devices" in payload:
        payload["devices"] = _ensure_list(payload["devices"])
    if "items" in payload:
        payload["items"] = _ensure_list(payload["items"])
    if "diagnostics" in payload:
        payload["diagnostics"] = _ensure_list(payload["diagnostics"])
    return payload


def _run_bridge(
    operation: str,
    *,
    device_id: str | None = None,
    destination: Path | None = None,
) -> dict[str, object]:
    args = [
        _powershell_executable(),
        "-NoProfile",
        "-ExecutionPolicy",
        "Bypass",
        "-File",
        str(SCRIPT_PATH),
        "-Operation",
        operation,
    ]

    if device_id is not None:
        args.extend(["-DeviceId", device_id])

    if destination is not None:
        args.extend(["-Destination", str(destination)])

    completed = subprocess.run(
        args,
        check=False,
        capture_output=True,
        text=True,
    )

    if completed.returncode != 0:
        message = completed.stderr.strip() or completed.stdout.strip() or f"USB bridge failed with code {completed.returncode}."
        raise RuntimeError(message)

    try:
        payload = json.loads(completed.stdout)
    except json.JSONDecodeError as error:
        raise RuntimeError(f"USB bridge returned invalid JSON: {error}\n\n{completed.stdout}") from error

    if not isinstance(payload, dict):
        raise RuntimeError(f"USB bridge returned unexpected payload: {payload!r}")

    return _normalize_payload(payload)


def list_devices() -> dict[str, object]:
    return _run_bridge("list-devices")


def scan_device(device_id: str) -> dict[str, object]:
    return _run_bridge("scan-device", device_id=device_id)


def stage_device(device_id: str, destination: Path) -> dict[str, object]:
    return _run_bridge("stage-device", device_id=device_id, destination=destination)


def build_staging_root(device_label: str) -> Path:
    safe_label = re.sub(r"[^A-Za-z0-9._-]+", "-", device_label).strip("-.") or "usb-device"
    base_root = Path(os.environ.get("LOCALAPPDATA") or Path.home() / "AppData" / "Local")
    return base_root / "iPhonePhotoImporter" / "staging" / f"{datetime.now():%Y%m%d-%H%M%S}-{safe_label}"
