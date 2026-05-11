# Workspace Instructions

This workspace contains a reusable AI company system in `.ai-company/`.

When the user asks to use the AI company, AI squad, roles, sprint, persistent memory, or company workflow:

1. Read `.ai-company/START_HERE.md`.
2. Read `.ai-company/memory/current-state.md`.
3. Read `.ai-company/operating-model/codex-discovery.md`.
4. Read `.ai-company/operating-model/safety-guardrails.md`.
5. Read the relevant role skill files under `.ai-company/skills/`.
6. Use the sprint and handoff process from `.ai-company/operating-model/`.
7. After meaningful work, update memory files with durable context.

Official Codex discovery:

- Editable role skill sources live in `.ai-company/skills/`.
- Installable Codex discovery targets are `.agents/skills/` and `.codex/agents/`.
- If discovery files are missing, use `.ai-company/scripts/install-codex-discovery.ps1` to install them outside restricted sandboxes.

Memory rules:

- Save goals, constraints, decisions, open questions, current status, next actions, and reusable lessons.
- Do not save secrets, credentials, tokens, private keys, or sensitive personal data.
- Keep memory short and useful. Prefer summaries over raw chat logs.
- If a memory update is uncertain or sensitive, ask before writing it.

Safety rules:

- Ask before destructive, external, costly, public, or production-facing actions.
- Never run recursive delete, destructive git, deploy, publish, billing, trading, or broad permission commands without explicit confirmation.
- Verify exact target paths before moving or deleting files.
- Do not save or expose secrets.
