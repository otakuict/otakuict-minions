# Current State

Last updated: 2026-05-13

## Active Objective

Build a USB-first Windows iPhone photo archive app starter using `Electron + Python helper`.

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

A new Windows desktop app starter has been created under `projects/iphone-photo-importer` with:

- Electron shell for Windows-focused onboarding, folder selection, and helper orchestration
- Python helper for scan, duplicate detection by hash, copy-only import, SQLite state, and JSON reports
- experimental Windows USB bridge via PowerShell and `Shell.Application`, plus USB-first UI mode and folder/iCloud fallback
- focused verification for Python compile, Electron JavaScript syntax, and sample plan/import rerun behavior

## User Preferences

- The user wants a reusable AI company, not something tied to one repo.
- The user wants multiple roles such as team lead, data engineer, developer, and marketing.
- The user wants local file memory so personality and work context can persist.
- For this app, the user wants a Windows target, Electron UI, Python helper, and strong priority on USB over cloud.

## Next Actions

- Install Electron dependencies in `projects/iphone-photo-importer/electron` with `npm.cmd install`.
- Install the Python package in `projects/iphone-photo-importer/python` with `python -m pip install -e .`.
- Test the USB-first workflow against a real iPhone on Windows with Apple Devices installed, the phone unlocked, and trust granted.
- Decide whether to keep the PowerShell shell bridge or replace it with a Windows-native WPD helper after real-device validation.
- Keep folder and iCloud flows as fallback paths, not the headline path.
- Open `AI_COMPANY_USAGE.md` when instructions are needed.
- Use the starter prompt in `prompts/use-ai-company.md`.
- Restart Codex if newly installed skills or custom agents do not appear in the current session.
- Rerun the discovery installer after safety or role skill changes so `.agents/skills` and `.codex/agents` receive the latest source.
- Update memory after meaningful work.
