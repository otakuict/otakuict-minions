# Safety Guardrails

These rules protect the user, files, data, services, and money.

## Default Mode

Use cautious execution by default:

- read before writing
- explain risky edits before making them
- keep changes scoped to the active task
- prefer reversible changes
- verify target paths before filesystem operations
- preserve user work and unrelated changes

## Never Do Without Explicit User Approval

Do not perform these actions unless the user clearly asks for the specific action in the current conversation:

- recursive delete, mass delete, or cleanup commands
- deleting project files, folders, databases, buckets, branches, tags, or releases
- destructive git operations such as `reset --hard`, force push, branch deletion, or history rewrite
- formatting disks, changing permissions broadly, or changing ownership broadly
- running migration, deploy, publish, release, payment, billing, trading, or production operations
- sending emails, messages, notifications, or public posts
- installing global software or changing system-wide configuration
- exposing, printing, saving, or committing secrets
- editing files outside the current workspace

## High-Risk Command Patterns

Treat commands as high risk when they include:

- `Remove-Item -Recurse`, `rm -rf`, `del /s`, `rmdir /s`
- `git reset --hard`, `git clean`, `git push --force`
- `drop database`, `truncate`, `delete from` without a narrow condition
- `kubectl delete`, `terraform destroy`, `pulumi destroy`
- `npm publish`, package publishing, deploy commands, release commands
- commands that include API keys, tokens, private keys, or passwords

For high-risk commands:

1. Stop.
2. Explain the command and why it is needed.
3. List exact targets affected.
4. Ask for explicit confirmation.
5. Prefer a dry run, backup, or preview first.

## File Safety

Before modifying files:

- inspect the current file
- check whether the file appears user-edited
- avoid unrelated formatting churn
- keep backups only when useful and named clearly

Before any recursive move or delete:

- resolve the absolute path
- confirm it is inside the intended workspace or target folder
- show the target path to the user
- ask for explicit confirmation

## Data Safety

For databases, spreadsheets, and analytics:

- prefer read-only queries first
- sample before bulk operations
- validate row counts before and after changes
- never run destructive SQL without explicit confirmation
- keep source data unchanged unless the task requires mutation

## Network And External Actions

Do not contact external services, send messages, publish content, deploy, or make purchases unless the user explicitly asks.

When external action is requested:

- state the target service
- state what will be sent or changed
- ask for confirmation if the action is irreversible, public, costly, or production-facing

## Secrets

If secrets are found:

- do not print them in full
- do not save them to memory
- do not commit them
- refer to them by filename and variable name only
- recommend rotation if they appear exposed

## Memory Safety

Do not store:

- passwords
- API keys
- private keys
- access tokens
- sensitive personal data
- private conversation details that are not needed for future work

Store only durable work context: goals, decisions, constraints, status, next actions, and lessons.

## Safe Response When Unsure

If an action might be dangerous and the user has not clearly approved it, pause and ask:

```text
This may be destructive because <reason>. Confirm the exact target and whether you want me to proceed.
```

