# Work Log

## 2026-05-13

- Ran the AI company workflow for a new Windows app objective using lead, product manager, and developer roles.
- Assessed iPhone photo import feasibility on Windows and explicitly rejected custom direct USB import as a v1 scope item.
- Created `projects/iphone-photo-importer` as an Electron plus Python starter project.
- Added Electron starter files for folder selection, helper invocation, and result display.
- Added Python helper code for source scan, content-hash dedupe, copy-only import, SQLite state, and JSON import reports.
- Added product and architecture docs that keep the MVP focused on local folder and iCloud-based ingestion paths.
- Verified Python syntax with `python -m compileall`, verified Electron JavaScript syntax with `node --check`, and exercised sample plan/import/rerun behavior with a temporary local test folder.
- Re-scoped the app to USB-first after the user clarified that USB matters more than cloud.
- Added an experimental Windows USB bridge using PowerShell and `Shell.Application`, plus Electron UI for USB device refresh and selection.
- Kept imported-folder and iCloud paths as fallback modes and moved USB staging out of the archive library into `%LOCALAPPDATA%`.
- Verified the new `usb-devices` CLI path end to end on this machine and confirmed the no-device diagnostic path works.

## 2026-05-05

- Initialized local AI company folder structure.
- Added identity, operating model, memory, role skill, template, and prompt files.
- Added root `AGENTS.md` so future Codex sessions can discover the local company workflow.
- Reviewed official Codex docs for skills, subagents, memories, and `AGENTS.md`.
- Updated role skills to use `ai-*` skill names and added optional `agents/openai.yaml` metadata.
- Added Codex discovery installer and project custom-agent templates under `.ai-company/codex-discovery`.
- Installed official Codex discovery files under `.agents/skills` and `.codex/agents`.
- Added safety guardrails requiring confirmation for destructive, external, costly, public, or production-facing actions.
- Updated the installer to copy over existing files instead of recursively deleting targets.
- Added root `AI_COMPANY_USAGE.md` with practical instructions for prompts, roles, memory, safety, projects, and skill updates.
- Created `projects/pokedex-nextjs`, an educational Next.js Pokedex app using PokeAPI.
- Implemented open/close Pokedex interaction, Pokemon search by name or ID, sprite/art display, types, stats, height, weight, base experience, and abilities.
- Verified the app with `npm.cmd run lint` and `npm.cmd run build`.
- Tried to start a local server; `next dev` was blocked by sandbox `spawn EPERM`, and background server launch did not persist. `next start` was confirmed ready in foreground before timeout.
