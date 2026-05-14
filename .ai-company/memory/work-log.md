# Work Log

## 2026-05-14

- Read the AI company startup, memory, Codex discovery, safety, sprint, delegation, and relevant role skill files for a new planning request.
- Captured a new objective to plan an AI agent monitoring system with pixel cartoon characters representing each agent/persona.
- Noted that implementation should wait until the user reviews and approves the plan.
- Refined the plan toward a Windows Terminal multipane v1 using local runtime files and ANSI pixel character rendering instead of a web dashboard or tmux-first design.
- Implemented `.ai-company/runtime/` seed files for latest agent state, event timeline, and session metadata.
- Added PowerShell scripts for status updates, overview rendering, individual agent panes, timeline tailing, and Windows Terminal multipane launch.
- Documented the monitor workflow in `AI_COMPANY_USAGE.md` and verified one-shot renders, status updates, timeline output, launcher command generation, and PowerShell parser checks.
- Updated the Windows Terminal launcher so the default layout opens one pane per AI company role, with the timeline available only through an optional flag.
- Fixed terminal flicker by replacing repeated `Clear-Host` calls with ANSI cursor redraw, frame diffing, and less frequent age-label changes.
- Replaced the default nested split-pane monitor layout with a compact single-terminal agent grid that shows all roles, up to five cards per row, and wraps overflow to the next row.
- Restored a work detail panel under the compact grid, selecting the active or most recently updated agent by default and showing full task, next action, blocker, progress, and recent events.

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
