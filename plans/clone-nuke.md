# Clone Nuke

## What

A `bin/clone-nuke` command that safely deletes an ephemeral clone directory after verifying no work would be lost.

## Why

Ephemeral clones pile up. You need a way to confidently delete them without manually checking each one. The `--check` flag lets you query "is this nukable?" without committing to the delete.

## Usage

```
bin/clone-nuke <directory>           # check + delete
bin/clone-nuke <directory> --check   # check only, no delete
```

## Safety Checks (all must pass)

1. **Is a git repo** — directory exists and contains `.git`
2. **Has `.agent-session`** — confirms it's a clone this system created
3. **Not in detached HEAD** — if HEAD is detached, fail immediately (something weird happened)
4. **Clean working tree** — no uncommitted changes (staged or unstaged)
5. **No untracked files** — nothing sitting outside git's knowledge. Note: system-generated files like `.agent-session`, `.env`, `.mcp.json`, `.vscode/` will trigger this if they're not in the repo's `.gitignore`. That's intentional — the fix is to add them to `.gitignore` in the target repo, not to carve out exceptions here.
6. **All local branches pushed** — every local branch must have a remote tracking branch, and the local branch must not be ahead of it
7. **No stashes** — `git stash list` must be empty

## Behavior

- **All checks pass + no `--check`:** `rm -rf <directory>`, print a one-liner like `Nuked <dir>`
- **All checks pass + `--check`:** print that it's nukable, exit 0
- **Any check fails:** print which checks failed, exit non-zero (regardless of `--check`)

## Boundaries

- Single directory at a time. No sweep/batch mode.
- No interactive confirmation prompt. Pass/fail only.
- Does not care about `.agent-session` state (running, done, etc.) — only the git-level checks matter.

## Integrations

- Sources `lib/agent-session.sh` for the `AGENT_SESSION_FILE` constant (consistency with the rest of the system)
- Lives in `bin/` alongside `clone`, `status`, `build`, etc.
- Follows the same conventions: `set -euo pipefail`, pure bash, no external dependencies beyond git

## Key Decisions

- `--check` not `--dry-run` — it's answering "is this nukable?" not "show me what would happen"
- Agent running state is irrelevant — if the git checks pass, it's nukable regardless of PID/state
- A local branch with no remote tracking branch at all is a fail — unpushed work
- Untracked files block the nuke — they represent work outside git's knowledge

## Open Questions

None.
