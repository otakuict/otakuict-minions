# Product Brief

## User

Windows user who wants a reliable way to pull photos from their own iPhone onto a local archive without manually sorting everything every time.

## Core Job

Take photos from a USB-connected iPhone when Windows exposes it, and move them into a clean, deduplicated local library.

## MVP

- Choose a source mode:
  - `USB iPhone (Experimental)`
  - `iCloud Photos`
  - `Imported Folder`
- Refresh USB devices and select the connected iPhone when available
- Pick a fallback source folder and destination archive folder
- Preview supported files, duplicates, bytes to copy, and date range
- Import files into `Archive\YYYY\YYYY-MM\`
- Keep a local import database so reruns are safe
- Write a machine-readable import report after each run

## Non-Goals

- custom Apple-protocol integration outside the Windows shell device layer
- deleting media from the iPhone
- editing photos
- cloud account authentication inside the app
- full media library management

## Primary Flow

1. User connects or syncs photos to Windows using a supported Apple/Microsoft path.
2. User opens the app and first tries `USB iPhone`.
3. If Windows exposes the phone, the app scans device media and stages files during import.
4. If Windows does not expose the phone, the user falls back to `iCloud Photos` or `Imported Folder`.
5. App copies files into the archive and records the import state.

## Acceptance Criteria

- User can refresh for USB devices and see a clear message if Windows is not exposing the iPhone.
- User can point the app at a USB device or local folder and get a preview of reachable supported media.
- User can run an import and receive a structured result.
- Imported files land in `YYYY\YYYY-MM` folders.
- A second run does not create duplicate copies for identical files.
- The project makes it explicit that USB mode is experimental and depends on Windows exposing the phone.

## Later Roadmap

- EXIF-based capture date parsing
- Live Photo pairing rules
- HEIC/HEVC codec checks
- optional watch mode for iCloud Photos
- USB adapter experiment behind a feature flag
