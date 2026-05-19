# Architecture

## USB-First Position

The app now tries USB first, but it does so through the Windows shell portable-device layer instead of attempting direct Apple protocol integration.

Main reasons:

- device trust and unlock state can block access
- Apple Devices and Windows Photos handle parts of the supported flow
- if iCloud Photos is enabled, originals may not be present on the phone
- Windows-side device access is more like a portable-device or imaging integration than a normal filesystem integration

## Recommended Ingestion Paths

1. USB through the Windows shell portable-device layer
2. `iCloud Photos` folder on Windows
3. Any local folder populated by Windows Photos or File Explorer import

This keeps the app focused on archive quality, deduplication, and organization, while still giving USB priority in the UI.

## Process Boundaries

### Electron

- desktop UI
- folder pickers
- settings and UX state
- progress and result presentation
- calls into Python helper via child process

### Python Helper

- Windows USB bridge through PowerShell plus `Shell.Application`
- media discovery
- hashing and duplicate detection
- archive path planning
- file copy operations
- SQLite import state
- JSON output back to Electron

## Data Flow

1. Renderer sends an import request through preload IPC.
2. Electron main process spawns `python -m iphone_photo_importer.cli`.
3. For `source_kind=usb`, Python calls a Windows PowerShell bridge that enumerates portable devices exposed by the shell.
4. During USB import, the bridge stages supported media files into `%LOCALAPPDATA%\iPhonePhotoImporter\staging\...`.
5. Python runs the normal hash-and-import pipeline against that staging folder, records results in SQLite, and writes a JSON report.
6. Electron displays the result summary.

## Archive Layout

Imported files are stored like this:

```text
<library>/
  2026/
    2026-05/
      IMG_1234-ab12cd34.heic
```

This is deterministic, easy to back up, and works well outside the app.

## USB Adapter Limits

The current USB adapter is intentionally narrow:

- it depends on the Windows shell portable-device namespace
- it does not promise raw device access if Windows is not exposing the phone
- it stages files first because the device namespace is not a normal filesystem path
- it should be treated as experimental until validated against real iPhone/Windows combinations

If later validation shows this is too fragile, a real native Windows component around WPD or `Windows.Media.Import` should replace the PowerShell bridge without changing the archive engine.
