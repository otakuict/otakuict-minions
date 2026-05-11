# AI Company Usage Guide

This project contains a reusable local AI company system for Codex.

Use it when you want Codex to work like a small team with roles such as company lead, product manager, developer, data engineer, QA reviewer, and marketing strategist.

## Quick Start

Start Codex in this folder:

```powershell
cd C:\Users\pattharaphon.o\Desktop\personal\otakuict-minions
```

Use this prompt:

```text
Use $ai-company-lead and my AI company system.

Objective:
<what you want to achieve>

Context:
<background, files, audience, constraints, or business rules>

Expected output:
<what Codex should produce>

Definition of done:
<how we know the work is complete>

Follow safety guardrails.
Update memory when done.
```

## Example

```text
Use $ai-company-lead and my AI company system.

Objective:
Create a plan for launching a small invoice tracking SaaS.

Context:
Target users are freelancers and small agencies.

Expected output:
Product scope, 1-week sprint plan, landing page copy, and launch checklist.

Definition of done:
The plan is clear enough to start implementation.

Follow safety guardrails.
Update memory when done.
```

## Available Skills

Use one role directly when you do not need the full company workflow:

```text
Use $ai-company-lead to plan this as a small sprint.
```

```text
Use $ai-product-manager to turn this idea into requirements and acceptance criteria.
```

```text
Use $ai-developer to implement this feature and verify it.
```

```text
Use $ai-data-engineer to inspect this data and define reliable metrics.
```

```text
Use $ai-qa-reviewer to review this work for bugs, risks, and test gaps.
```

```text
Use $ai-marketing-strategist to write positioning, campaign copy, or launch messaging.
```

## Using The Squad

Subagents only run when you explicitly ask for delegation or parallel agent work.

Example:

```text
Use my AI company system.

Spawn product_manager, software_developer, qa_reviewer, and marketing_strategist.

Objective:
<goal>

Have the company lead coordinate the sprint, collect each role's output, review it, and update memory.
Follow safety guardrails.
```

Installed custom agents:

- `company_lead`
- `product_manager`
- `software_developer`
- `data_engineer`
- `qa_reviewer`
- `marketing_strategist`

## Memory

Persistent local memory lives in:

- `.ai-company/memory/current-state.md`
- `.ai-company/memory/work-log.md`
- `.ai-company/memory/decisions.md`
- `.ai-company/memory/open-questions.md`
- `.ai-company/memory/lessons-learned.md`

Useful prompt:

```text
Read the AI company memory before starting and update memory when done.
```

Save durable context only:

- goals
- constraints
- decisions
- current status
- next actions
- open questions
- reusable lessons

Do not save:

- passwords
- API keys
- private keys
- access tokens
- sensitive personal data
- unnecessary raw chat history

## Safety Guardrails

All roles must follow:

```text
.ai-company/operating-model/safety-guardrails.md
```

The AI company must ask before:

- recursive delete or mass cleanup
- destructive git commands
- deploy, publish, release, or production operations
- production database writes
- sending emails, messages, notifications, or public posts
- billing, trading, purchases, or other costly actions
- broad permission or ownership changes
- editing outside the workspace
- exposing, saving, or committing secrets

Recommended prompt line:

```text
Follow safety guardrails. Ask before destructive, external, costly, public, or production-facing actions.
```

## New Project Workflow

Use this when starting a new objective:

```text
Use $ai-company-lead and my AI company system.

Create a new project called <project-name> under `.ai-company/projects`.

Objective:
<goal>

Create:
- project brief
- initial backlog
- first sprint brief
- memory update

Follow safety guardrails.
```

## Important Files

- `AGENTS.md`: workspace instructions for Codex.
- `.ai-company/START_HERE.md`: main operating guide.
- `.ai-company/prompts/use-ai-company.md`: reusable starter prompt.
- `.ai-company/skills/`: editable source skills.
- `.agents/skills/`: installed Codex skill discovery folder.
- `.codex/agents/`: installed custom agent configs.
- `.ai-company/operating-model/safety-guardrails.md`: safety rules.

## Updating Skills

Edit source skills in:

```text
.ai-company/skills/
```

Then reinstall them into Codex discovery:

```powershell
powershell -ExecutionPolicy Bypass -File .ai-company\scripts\install-codex-discovery.ps1 -Force
```

Restart Codex if new or updated skills do not appear.

## Recommended Habit

For any meaningful work, ask Codex to:

1. read memory
2. choose roles
3. define acceptance criteria
4. execute the work
5. review the result
6. update memory
7. follow safety guardrails

