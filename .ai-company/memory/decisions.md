# Decisions

## 2026-05-14 - Use Windows Terminal multipane for AI agent monitor v1

Decision: Build the first AI agent monitor as a Windows Terminal multipane workflow using local runtime files and ANSI pixel cartoon characters.

Reason: The user is on Windows and wants a terminal-native monitor. Windows Terminal already supports multiple panes, avoids the extra resource cost of a web terminal stack, and does not require tmux/WSL for the first version.

Update: The default Windows Terminal layout should show one agent per pane. A combined overview pane is not needed by default; timeline remains optional.

## 2026-05-05 - Use local Markdown memory

Decision: Store AI company memory in local Markdown files under `.ai-company/memory/`.

Reason: The user wants memory and personality to persist in this folder and remain easy to inspect, edit, and reuse.

## 2026-05-05 - Use role skills as reusable employee training

Decision: Store role behavior in Codex-compatible `SKILL.md` files under `.ai-company/skills/`.

Reason: Skills provide reusable instructions for specialist roles while keeping each role portable.

## 2026-05-05 - Separate source files from Codex discovery targets

Decision: Keep editable AI company source files under `.ai-company`, then install them to official Codex discovery locations with `scripts/install-codex-discovery.ps1`.

Reason: Official Codex docs say repository skills are discovered from `.agents/skills` and project custom agents from `.codex/agents`, but this sandbox blocks direct writes to those root discovery folders.

## 2026-05-05 - Require approval for dangerous actions

Decision: Add safety guardrails requiring explicit user approval before destructive, external, costly, public, production-facing, or broad system actions.

Reason: The user wants protection against accidental file deletion and other dangerous AI actions.

## 2026-05-05 - Place Pokedex app inside workspace projects folder

Decision: Create the Next.js app at `projects/pokedex-nextjs`.

Reason: The requested parent folder outside the workspace was not writable from this Codex session, while the `projects` folder inside the workspace keeps the AI company memory and skills available.

## 2026-05-05 - Fetch Pokemon client-side

Decision: Use client-side fetches to PokeAPI from the Pokedex UI.

Reason: Search should happen interactively in the browser, and the app can remain statically buildable while still using live Pokemon data at runtime.

## 2026-05-13 - Avoid custom iPhone USB import in v1

Decision: Scope the Windows photo app MVP around local-folder ingestion, including `iCloud Photos` folders and folders populated by Windows Photos or File Explorer, instead of custom direct iPhone-over-USB import.

Reason: Apple and Microsoft provide user-facing Windows import flows, but not a clean low-risk developer path for a small `Electron + Python` MVP. Folder-based ingest keeps the app buildable while still solving archival, dedupe, and organization.

## 2026-05-13 - Keep Electron as UI shell and Python as short-lived worker

Decision: Use Electron for UI, path selection, and orchestration, while keeping Python as a short-lived filesystem ingest worker that returns JSON.

Reason: This preserves clean process boundaries and leaves room for a future Windows-native USB bridge without forcing Python to own device-specific Windows integration.

## 2026-05-13 - Prioritize USB in the UI, but keep fallback sources

Decision: Make `USB iPhone` the first source mode in the app while keeping `Imported Folder` and `iCloud Photos` as secondary fallback paths.

Reason: The user explicitly wants USB prioritized, but Windows iPhone visibility is inconsistent enough that the app still needs honest fallback paths.

## 2026-05-13 - Implement the first USB spike with a PowerShell shell bridge

Decision: Add a Windows-only USB bridge using PowerShell plus `Shell.Application` to enumerate and stage files from portable devices exposed by Windows.

Reason: This is the fastest path to a working USB-first prototype inside the current Electron plus Python project, while a richer WPD-based helper remains an open next-step option if real-device validation shows the shell bridge is too fragile.
