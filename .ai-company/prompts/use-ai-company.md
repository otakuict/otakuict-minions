# Use AI Company Prompt

Copy this into Codex when you want to run work through the local AI company system:

```text
Use $ai-company-lead and my AI company system in `.ai-company/`.

Act as company lead first.

Objective:
<describe the goal>

Context:
<add background, files, business constraints, or audience>

Expected output:
<describe what you want produced>

Definition of done:
<describe how we know it is complete>

Workflow:
1. Read the local AI company memory and operating model.
2. Choose only the roles needed.
3. Create a small sprint plan.
4. Execute the work.
5. Review the output.
6. Update memory files when done.

Safety:
- Follow `.ai-company/operating-model/safety-guardrails.md`.
- Ask before destructive, external, costly, public, or production-facing actions.
```
