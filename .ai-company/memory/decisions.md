# Decisions

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
