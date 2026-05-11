# Current State

Last updated: 2026-05-05

## Active Objective

Build an educational Next.js Pokedex app using the public Pokemon API.

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

## User Preferences

- The user wants a reusable AI company, not something tied to one repo.
- The user wants multiple roles such as team lead, data engineer, developer, and marketing.
- The user wants local file memory so personality and work context can persist.

## Next Actions

- Run the Pokedex app locally from `projects/pokedex-nextjs` with `npm.cmd run start -- -p 3000 --hostname 127.0.0.1` after build, or `npm.cmd run dev` from a normal terminal if the sandbox is not blocking dev server child processes.
- Open `AI_COMPANY_USAGE.md` when instructions are needed.
- Use the starter prompt in `prompts/use-ai-company.md`.
- Restart Codex if newly installed skills or custom agents do not appear in the current session.
- Rerun the discovery installer after safety or role skill changes so `.agents/skills` and `.codex/agents` receive the latest source.
- Create a project under `projects/` when there is a specific objective.
- Update memory after meaningful work.
