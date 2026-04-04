# Multi-Org Clone Support

## What

Replace the single-org `.repo` config with a new `.repos` file that supports a default remote and per-repo overrides. This lets `bin/clone` work with repos spread across multiple GitHub orgs.

## Why

The current `.repo` config only supports one remote/org. When repos live in different orgs, cloning doesn't work without manual URL juggling.

## How It Works

`.repos` file format:

```
default=git@github.com:my-main-org
some-repo=git@github.com:my-other-org
```

- `default` is required. Used for any repo without a specific override.
- Any other line is `repo-name=remote-base-url`.
- The clone script still appends `/{repo-name}.git` to the resolved remote.
- Comments (`#`) and blank lines are allowed (same as current `.repo` parsing).

## Scope

**In scope:**
- New `.repos` config file format (replaces `.repo`)
- Update `bin/clone` to read `.repos` — check for repo-specific override, fall back to `default`
- New `.repos.example` showing both default and an override
- Update `.gitignore` — replace `.repo` with `.repos`
- Delete `.repo.example`

**Out of scope:**
- No changes to `bin/plan`, `bin/build`, `bin/task`, `bin/status` (they don't read `.repo`)
- No changes to `.env.{repo}` or `.vscode.{repo}` conventions (keyed off repo name, unaffected)
- No backwards compatibility with `.repo`

## Integrations

- **`bin/clone`** — only consumer of `.repo` today, only file that needs logic changes
- **`.gitignore`** — swap `.repo` to `.repos`

## Key Decisions

- `.repos` replaces `.repo` entirely (no migration, no backwards compat)
- Override granularity is at the org/remote level (not full URL). Script still appends `/{repo-name}.git`.
- `.repos` is gitignored (same as `.repo` was)

## Open Questions

None.

## What to Test

**Files changed:** `bin/clone`, `.gitignore`, `.repos.example`, `README.md`. Deleted: `.repo.example`.

**Happy path:**
- Create `.repos` with only `default=...` — `bin/clone <repo>` should use the default remote
- Create `.repos` with `default=...` and `my-repo=...` — `bin/clone my-repo` should use the override; `bin/clone other-repo` should use the default
- Comments (`#`) and blank lines in `.repos` should be ignored

**Error cases:**
- Missing `.repos` file — should get a clear error pointing to `.repos.example`
- `.repos` exists but has no `default` line — should get `ERROR: 'default' not set`

**Edge cases:**
- Repo name that matches no override — falls back to default
- Multiple overrides in the file — only the matching one is used

**Docs:**
- `README.md` setup instructions reference `.repos.example` / `.repos` (not `.repo`)
- `.repos.example` has a working example with default + commented override
