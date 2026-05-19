# iPhone Photo Importer

Windows desktop app starter for bringing photos from a personal iPhone onto a PC, using an Electron UI and a Python helper.

## Current MVP Position

This build is now USB-first, but still honest about the platform limits.

Current source modes:

- detect an iPhone exposed through the Windows shell portable-device layer over USB
- stage reachable device files into a local working folder before archive import
- watch or scan an `iCloud Photos` folder
- import from a folder that the user already populated via Windows Photos or File Explorer
- deduplicate and copy files into a local archive layout
- write a machine-readable import report after each run

The USB path is explicitly marked experimental. On Windows, it still depends on device trust state, Apple/Windows device plumbing, and whether originals are actually present on the phone.

## Project Layout

- `docs/`: product and architecture notes
- `electron/`: desktop shell and renderer
- `python/`: ingest helper and archive logic

## Quick Start

1. Install Python 3.14+.
2. Install Node.js 22+.
3. If you want the iCloud-based path, install iCloud for Windows and enable iCloud Photos.
4. If you want the USB path, install Apple Devices if needed, connect the iPhone with a data-capable cable, unlock it, and tap `Trust`.
4. In one terminal:

```powershell
cd projects/iphone-photo-importer/python
python -m pip install -e .
```

5. In another terminal:

```powershell
cd projects/iphone-photo-importer/electron
npm.cmd install
npm.cmd start
```

## Python Helper Without Electron

You can use the helper directly:

```powershell
cd projects/iphone-photo-importer/python
python -m iphone_photo_importer.cli usb-devices --json
python -m iphone_photo_importer.cli plan --source "Apple iPhone" --library "D:\PhotoArchive" --source-kind usb --json
python -m iphone_photo_importer.cli import --source "Apple iPhone" --library "D:\PhotoArchive" --source-kind usb --json

cd projects/iphone-photo-importer/python
python -m iphone_photo_importer.cli plan --source "C:\Users\you\Pictures\iCloud Photos" --library "D:\PhotoArchive" --source-kind icloud --json
python -m iphone_photo_importer.cli import --source "C:\Users\you\Pictures\ImportedFromPhone" --library "D:\PhotoArchive" --source-kind folder --json
```

## Notes

- USB import first stages files into `%LOCALAPPDATA%\iPhonePhotoImporter\staging\`, then runs the normal archive import logic.
- Capture date currently falls back to file modification time. EXIF-based dating can be added later.
- The helper records imported hashes in SQLite so repeated imports can skip duplicates.
- Import reports are written to `<library>/.reports/`.
- The Electron shell is a functional starter, not a finished product.
