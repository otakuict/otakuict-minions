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
