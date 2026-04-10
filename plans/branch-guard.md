# Branch Guard for Agents

## What

All three agent prompts (plan, build, hack) get a pre-flight check: if the current branch is `main`, ask the human if that's intentional before proceeding.

## Why

It's easy to start a session and forget to branch. Committing to main when you meant to be on a feature branch is annoying to undo. A quick "hey, you're on main — is that intentional?" at the start catches it early.

## Behavior

- At session start, the agent checks the current git branch.
- If the branch is `main`, the agent asks the human: something like "You're on main — is that intentional, or should we create a feature branch?"
- If the human says main is fine, the agent moves on. No gatekeeping.
- If the human wants a branch, the agent creates it (or asks for a name) and continues.
- If already on a non-main branch, no mention of it — just proceed normally.

## Scope

**In scope:**
- Add the same branch-check instruction to `prompts/plan.md`, `prompts/build-agent.md`, and `prompts/hack-agent.md`

**Out of scope:**
- No bash-level checks or blocking in `bin/` scripts
- No different behavior per agent type — same check for all three
- No enforcement — the human can say "main is fine" and the agent respects it
- No detached HEAD handling — `bin/clone` leaves you on main, so detached HEAD means someone did something outside the system

## Integrations

- **`prompts/plan.md`** — add branch check to "How You Work" section
- **`prompts/build-agent.md`** — add branch check to "How You Work" section
- **`prompts/hack-agent.md`** — add branch check to "Phase 1: Design" section

## Key Decisions

- Prompt-level, not bash-level. The agent asks, it doesn't block. The human might have a good reason to be on main.
- Same behavior for all three agents. No per-agent variation.

## Open Questions

None.
