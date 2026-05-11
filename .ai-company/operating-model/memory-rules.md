# Memory Rules

Memory is stored as local Markdown files.

## Startup

At the start of AI company work:

1. Read `memory/current-state.md`.
2. Read relevant identity and operating-model files.
3. Read project-specific files if the task belongs to a project.
4. Read role skill files for selected roles.
5. If skill discovery is needed, check `operating-model/codex-discovery.md`.
6. Before risky work, check `operating-model/safety-guardrails.md`.

## Shutdown

After meaningful work:

1. Update `memory/current-state.md`.
2. Append a dated entry to `memory/work-log.md`.
3. Add decision records to `memory/decisions.md`.
4. Update `memory/open-questions.md`.
5. Add reusable improvements to `memory/lessons-learned.md`.

## What To Save

Save:

- active objective
- current status
- next actions
- constraints
- user preferences
- important decisions and reasons
- reusable lessons
- unresolved questions

Do not save:

- passwords
- API keys
- private keys
- access tokens
- raw private conversations
- sensitive personal data unless explicitly approved

## Codex Built-In Memories

Codex has an optional built-in Memories feature. Treat built-in memories as a helpful recall layer, not the only source of required rules.

Keep durable company rules, role behavior, project status, and decisions in `.ai-company` so they are inspectable and portable.

## Memory Quality

Good memory is short, durable, and action-oriented.

Prefer:

```text
Decision: Use local Markdown memory because it is portable and easy to inspect.
Reason: The user wants a reusable company system in this folder.
```

Avoid:

```text
The user and assistant talked for a while about memory.
```
