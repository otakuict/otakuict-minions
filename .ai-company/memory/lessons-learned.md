# Lessons Learned

## 2026-05-05

- For reusable AI company work, separate role behavior from memory. Role files describe how agents work; memory files describe what the company knows.
- Persistent memory should summarize durable facts and decisions, not preserve raw chat logs.
- Official Codex discovery expects skills in `.agents/skills`; keeping editable source in `.ai-company/skills` needs an installer or copy step.
- Built-in Codex Memories are useful recall, but required team rules should remain in explicit local files such as `AGENTS.md` and `.ai-company`.
- Safety rules must be explicit and loaded at startup. The most useful rule is not "never do risky work"; it is "pause, show exact targets, and require confirmation before risky work."
- In Next.js 16, `next lint` is not a valid script pattern for this app; use `eslint .` with `eslint.config.mjs`.

## 2026-05-13

- On Windows, "import from iPhone" and "build your own iPhone USB importer" are different problem classes. Treat the second one as a native-integration project, not a small Electron feature.
- For a practical media-ingest MVP, own the archive workflow and report quality first. Use supported folder-based inputs before betting on device-level integration.
- A PowerShell plus `Shell.Application` bridge is fast to prototype for portable-device access, but JSON array normalization and copy-completion handling need explicit guardrails.
