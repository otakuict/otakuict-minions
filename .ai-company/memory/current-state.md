# Current State

Last updated: 2026-05-14

## Active Objective

Implement and use an AI agent monitoring system that uses Windows Terminal multipane views, local status files, and ANSI pixel cartoon characters to show what each AI role/agent is doing.

## Current Status

The local AI company system has been initialized with:

- persistent memory files
- role skill source files
- operating model files
- reusable templates
- starter prompts
- root workspace instructions in `AGENTS.md`
- root usage guide in `AI_COMPANY_USAGE.md`
- Codex discovery installer and custom-agent templates based on official Codex docs
- official Codex discovery files installed under `.agents/skills` and `.codex/agents`
- safety guardrails added under `.ai-company/operating-model/safety-guardrails.md`

The Pokedex app has been created under `projects/pokedex-nextjs`.

The Windows Terminal-based AI agent monitor v1 has been implemented. It uses local runtime files under `.ai-company/runtime/`, PowerShell scripts under `.ai-company/scripts/`, and ANSI pixel cartoon characters to show current activity/status for AI company roles. The default launcher now opens a compact agent grid with up to five role cards per row plus a detail panel for the active or most recently updated agent; the old split-pane layout is optional.

## User Preferences

- The user wants a reusable AI company, not something tied to one repo.
- The user wants multiple roles such as team lead, data engineer, developer, and marketing.
- The user wants local file memory so personality and work context can persist.
- The user wants to see a plan before implementation for the AI agent monitoring system.
- The user prefers a visual monitor using pixel cartoon characters for each AI agent/persona.
- The user prefers a Windows Terminal multipane monitor for v1, with tmux or web UI deferred unless needed later.
- The user prefers agent cards to be compact, all visible, and arranged horizontally up to five per row before wrapping to the next row.

## Next Actions

- Try the AI agent monitor in Windows Terminal with `powershell -ExecutionPolicy Bypass -File .ai-company\scripts\start-monitor.ps1`.
- Update agent statuses during future AI company work with `.ai-company\scripts\update-agent-status.ps1`.
- Consider integrating status updates into sprint/handoff prompts so agents update monitor state automatically.
- Run the Pokedex app locally from `projects/pokedex-nextjs` with `npm.cmd run start -- -p 3000 --hostname 127.0.0.1` after build, or `npm.cmd run dev` from a normal terminal if the sandbox is not blocking dev server child processes.
- Open `AI_COMPANY_USAGE.md` when instructions are needed.
- Use the starter prompt in `prompts/use-ai-company.md`.
- Restart Codex if newly installed skills or custom agents do not appear in the current session.
- Rerun the discovery installer after safety or role skill changes so `.agents/skills` and `.codex/agents` receive the latest source.
- Create a project under `projects/` when there is a specific objective.
- Update memory after meaningful work.
