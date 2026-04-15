# Merge Agent

## What

A new agent that helps bring two diverged branches back together. It works in two phases using two existing patterns:

1. **`bin/plan-merge`** — an interactive planner that analyzes both branches, reads the plans from each side, identifies overlaps and wrinkles, and interviews the human to produce a convergence plan (a `.merge.md` file in `plans/`).
2. **`bin/build`** — the existing build agent executes the merge plan. Its prompt gets a new section teaching it how to handle `.merge.md` plans differently from feature plans.

The merge planner is a domain reconciliation agent. It doesn't just look at git conflicts — it understands what each branch was trying to accomplish by reading the plans, commit messages, and code. It surfaces the real issues: features built on a structure that got refactored out, duplicate implementations, semantic conflicts that git would merge cleanly but that break at runtime.

## Why

When multiple features are built in parallel across ephemeral clones, branches diverge. Git merge handles the mechanics, but the hard part is understanding how two lines of domain work interact. This agent reads the plans from both sides — the *intent* behind the changes — and uses that to produce an intelligent convergence plan. The plan may include real build work (e.g., adapting features from one branch to fit the other's refactored architecture), not just conflict marker resolution.

## How the Merge Planner Works

### Pre-flight (script-level, in `bin/plan-merge`)

Before launching claude, the script:
- Checks working tree is clean (no uncommitted changes)
- Checks everything is committed
- Checks branch is pushed to remote
- Fetches origin and validates both input branches exist

If any check fails, the script exits with a message telling the human to fix it. No claude session gets started.

### Analysis Phase (in the agent)

1. Find the merge base between the two branches
2. Read diffs from merge base to each branch — what changed on each side
3. Identify overlapping files (changed on both branches)
4. Read plans added on each branch since the merge base — understand the intent
5. For changes without plans, read commit messages and code (most commits are Claude-written, so messages are descriptive)

### Interview Phase

The agent presents its findings and interviews the human. This follows the plan agent's style — listen, ask non-obvious questions, dig into the domain. The agent:
- Makes sure it understands the plans and why the changes were made on each side
- Thinks about overlaps and potential issues between them
- Checks code/diffs to see what's actually happening
- Brings recommendations to the human, highlighting wrinkles
- Takes the opportunity to elevate the domain-level understanding of what both branches accomplished

This is not about priority ("which branch wins"). It's about making everything work together. There may be real work required — not just merge resolution.

The planner also recommends which branch should be the **base** — the branch the merge starts from, with the other merged in. This is a domain decision, not a mechanical one: "main's refactored structure is the foundation, adapt altbot's features to fit" vs the reverse. The recommendation and reasoning go into the merge plan.

### Output

A convergence plan written to `plans/<date>-<descriptive-name>.merge.md`. The `.merge.md` suffix signals this is a convergence plan, not a feature plan. The name should reflect the domain, e.g., `plans/26-04-14-bringing-altbot-into-main.merge.md`.

The merge plan must include:
- The exact branch names and SHAs that were analyzed
- The merge base SHA
- Which branch is the recommended base, and why
- The domain-level analysis of what each branch accomplished
- Overlapping areas and how to handle them
- Any real build work required beyond conflict resolution

The plan is written but **not committed** during the interview. After codex + human review and approval, the planner:
1. Checks out the recommended base branch (e.g., `main`)
2. Creates a new branch (e.g., `merge/altbot-into-main`)
3. Commits the merge plan as the first commit on that branch

This way the plan lives on the merge branch — neither source branch is modified. The build agent picks it up from there.

## How the Build Agent Handles Merge Plans

The build agent's prompt gets a new section for handling `.merge.md` plans. The existing build workflow (validate with pytest + ruff, commit incrementally, codex review) stays the same. The differences:
- The merge plan is the authority — it specifies the merge order, which branch to merge in, and how to bring them together. The builder follows it.
- Pure conflict resolution skips test-first — but if the merge plan calls for real build work (e.g., adapting features to a refactored architecture), the builder writes tests for that work first, same as a normal build.

The human makes a PR from the resulting branch.

## Invocation

```bash
bin/plan-merge <clone-dir> <branch-a> <branch-b>
```

Branches are symmetric in invocation — order doesn't matter. The planner figures out the right merge order and base branch during the interview, and the merge plan specifies it for the builder.

## Scope

**In scope:**
- New `bin/plan-merge` script with pre-flight checks
- New `prompts/plan-merge.md` prompt
- Update `prompts/build.md` with a merge-plan execution section
- Add `git fetch`, `git merge`, `git merge-base`, `git rev-list`, `git ls-tree`, `git merge-tree` to `GIT_TOOLS` and their `-C` variants to `GIT_C_TOOLS` in `lib/allowed-tools.sh`
- Add `comm` to `SHELL_TOOLS`
- Update `README.md` — new agent description, workflow section, file tree
- Rename `prompts/build-agent.md` → `prompts/build.md` and `prompts/hack-agent.md` → `prompts/hack.md` (already done during planning)
- Update `bin/build` and `bin/hack` to reference renamed prompt filenames (already done during planning — no content changes to hack, just the filename)

**Out of scope:**
- No `bin/merge` executor script — `bin/build` handles execution
- No driver/observer agents (future work from original vision)
- No always-running/monitoring mode — this is on-demand
- No playground branch for the planner — analysis is read-only. The planner creates a merge branch only after the plan is approved.

## Integrations

- **`bin/plan-merge`** — new script, follows the pattern of `bin/plan`
- **`prompts/plan-merge.md`** — new prompt
- **`prompts/build.md`** — updated with merge-plan handling section
- **`lib/allowed-tools.sh`** — new git commands added to `GIT_TOOLS` and `GIT_C_TOOLS`; `comm` added to `SHELL_TOOLS`
- **`lib/agent-session.sh`** — used by `bin/plan-merge` for session tracking (existing, no changes needed)

## Key Decisions

- Named "merge" — short, easy to spell, implies careful bringing-together. `bin/plan-merge` tab-completes from `bin/plan`.
- The merge planner is a domain reconciliation agent, not a git conflict resolver. It reads plans to understand intent, not just conflict markers.
- No separate executor — the build agent handles merge plan execution with a prompt section that adjusts its workflow for `.merge.md` plans.
- Pre-flight checks are script-level, not prompt-level. Dirty state would break the analysis, so don't waste a claude session on it.
- Branches are symmetric in invocation — order doesn't matter. But the planner recommends which one is the base during the interview, based on domain understanding.
- Context hierarchy for understanding changes: plans > commit messages > code.
- New git tools (`fetch`, `merge`, `merge-base`, `rev-list`, `ls-tree`, `merge-tree`) added to all agents via `GIT_TOOLS`. These are all read-only or local-only — no remote-write risk. Ephemeral clones are disposable anyway.
- The merge plan is committed as the first commit on the new merge branch — neither source branch is modified.
- The merge plan captures exact SHAs and merge base so the build agent works against the same state the planner analyzed.
- Prompt file renames (`build-agent.md` → `build.md`, `hack-agent.md` → `hack.md`) bundled into this plan since they were done during the planning session.

## What to Test

### `bin/plan-merge` script
- **Happy path:** Run `bin/plan-merge <clone-dir> main <feature-branch>` with both branches existing locally — should pass pre-flight and launch claude
- **Clean tree check:** Make an uncommitted change in the clone, run `plan-merge` — should error before launching claude
- **Staged changes check:** Stage a file without committing, run `plan-merge` — should error
- **Missing branch:** Run with a branch name that doesn't exist locally or on origin — should error
- **Remote-only branch:** Delete a local branch but keep its remote, run `plan-merge` — should create a local tracking branch and proceed
- **Tab title:** Verify terminal tab shows `MERGE: <label>` during session
- **Session marker:** Check `.agent-session` shows `agent=plan-merge` and correct states (running → done/interrupted)

### `prompts/plan-merge.md` (merge planner prompt)
- The four phases (Analysis, Interview, Write Plan, Create Merge Branch) are clearly described
- Plan output format includes all required fields (branch names, SHAs, merge base, recommended base, etc.)
- Rules prohibit modifying source branches or attempting the actual merge

### `prompts/build.md` (merge-plan handling)
- The "Handling Merge Plans" section instructs merging by SHA, not branch name
- Pure conflict resolution skips test-first; real build work uses test-first
- Merge commit comes first, then incremental build work

### `lib/allowed-tools.sh`
- `GIT_TOOLS` includes: `git fetch`, `git merge`, `git merge-base`, `git rev-list`, `git ls-tree`, `git merge-tree`
- `GIT_C_TOOLS` includes the `-C` variants of all the above
- `SHELL_TOOLS` includes `comm`

### `README.md`
- Merge Planner listed in "The Agents" section between Build Agent and Hack Agent
- Workflow step 4 "Merge (when branches diverge)" with correct invocation
- File tree includes `bin/plan-merge`, `prompts/plan-merge.md`
- Permissions section lists the new git commands

## Open Questions

None.
