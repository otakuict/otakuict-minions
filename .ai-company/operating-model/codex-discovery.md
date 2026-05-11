# Codex Discovery

This file records how the local AI company maps to official Codex discovery behavior.

## Skills

Codex automatically discovers repository skills from `.agents/skills`.

The editable source skills for this AI company live in `.ai-company/skills`. To install them into the official discovery location, run:

```powershell
powershell -ExecutionPolicy Bypass -File .ai-company\scripts\install-codex-discovery.ps1 -Force
```

Installed skill targets:

- `.agents/skills/ai-company-lead/`
- `.agents/skills/ai-product-manager/`
- `.agents/skills/ai-developer/`
- `.agents/skills/ai-data-engineer/`
- `.agents/skills/ai-qa-reviewer/`
- `.agents/skills/ai-marketing-strategist/`

## Custom Agents

Project-scoped custom subagent templates live in `.ai-company/codex-discovery/agents`.

The installer copies them to `.codex/agents`, where Codex can discover project-scoped custom agents.

Current custom agents:

- `company_lead`
- `product_manager`
- `software_developer`
- `data_engineer`
- `qa_reviewer`
- `marketing_strategist`

Custom subagents are useful only when the user explicitly asks for sub-agents, delegation, or parallel agent work.

## AGENTS.md

Root `AGENTS.md` is the workspace instruction entrypoint. It tells future Codex sessions to load `.ai-company` when the user asks for AI company or squad work.

## Local Memory

The local memory in `.ai-company/memory` is a deliberate project artifact. Codex also has an optional built-in Memories feature, but local memory remains useful because it is inspectable, portable, and can be copied with this AI company system.

## Sources

- https://developers.openai.com/codex/skills
- https://developers.openai.com/codex/subagents
- https://developers.openai.com/codex/memories
- https://developers.openai.com/codex/guides/agents-md

