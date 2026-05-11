# AI Company Starter

This folder is a local operating system for running Codex like a small AI company.

Use it when you want role-based work across any purpose, such as software, data, marketing, research, operations, planning, or product strategy.

## How to Activate

Use one of these prompts:

```text
Use $ai-company-lead for this task.
```

```text
Use my AI company system for this task.
```

```text
Run this as a sprint using the AI company workflow.
```

```text
Act as company lead, choose the needed roles, and update memory when done.
```

## Startup Checklist

1. Read `memory/current-state.md`.
2. Read `identity/company-principles.md` and `identity/communication-style.md`.
3. Read `operating-model/codex-discovery.md`.
4. Read `operating-model/safety-guardrails.md`.
5. Read the relevant operating model files.
6. Choose only the roles needed for the objective.
7. Define acceptance criteria before execution.
8. Update memory after meaningful work.

## Folder Map

- `identity/`: stable personality, values, and communication preferences.
- `memory/`: persistent local memory about work, decisions, status, and lessons.
- `operating-model/`: sprint process, delegation rules, memory rules, and quality standards.
- `skills/`: editable source skills for the AI company roles.
- `codex-discovery/`: project custom-agent templates and Codex config template.
- `scripts/`: setup helpers, including discovery installation.
- `templates/`: reusable documents for briefs, tasks, reviews, and decisions.
- `projects/`: optional per-project workspaces.
- `prompts/`: starter prompts you can reuse.

## Codex Discovery Install

Official Codex skill discovery uses `.agents/skills`. Project custom agents use `.codex/agents`.

To install this AI company into those discovery locations, run:

```powershell
powershell -ExecutionPolicy Bypass -File .ai-company\scripts\install-codex-discovery.ps1 -Force
```

Restart Codex after installing discovery files if new skills or agents do not appear.

## Default Operating Mode

The main Codex agent acts as company lead. It may use sub-agents for bounded specialist work when the user explicitly asks for squad, sub-agent, delegation, or parallel agent work.

If sub-agents are not available or not requested, the main agent should still use the role files as perspectives and produce the requested outputs directly.

## Safety Mode

All roles must follow `operating-model/safety-guardrails.md`.

Any destructive, external, costly, public, or production-facing action requires explicit user approval before execution.
