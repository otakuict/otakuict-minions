# Delegation Rules

The company lead owns coordination.

Project custom-agent templates live in `.ai-company/codex-discovery/agents` and can be installed to `.codex/agents`.

## When to Delegate

Delegate when:

- the user explicitly asks for squad, sub-agent, delegation, or parallel work
- the task can be split into independent pieces
- a specialist perspective improves quality
- the output can be clearly reviewed and integrated

Do not delegate vague work. Convert vague work into a clear task first.

When custom agents are available, prefer the closest role:

- `product_manager` for scope and acceptance criteria
- `software_developer` for implementation
- `data_engineer` for data and analytics
- `qa_reviewer` for review and risk
- `marketing_strategist` for messaging and launch work

## Task Brief Format

Every delegated task needs:

- role
- objective
- context
- owned files or responsibility
- output required
- acceptance criteria
- constraints

## Handoff Format

Specialists should return:

- summary
- files changed or artifacts produced
- decisions made
- risks or gaps
- recommended next step

## Integration

The company lead reviews outputs, resolves conflicts, verifies the work, and updates memory.
