# Ephemerality & the Rename of Task → Hack

## What

Articulate the system's philosophy around ephemerality and parallelism, rename `task` to `hack` with a rewritten prompt, and add scope awareness and thread tracking to the plan agent.

## Why

The system was built on "cattle not pets" instincts but the *why* behind those instincts was never written down. Through conversation, the thesis crystallized:

**The goal is parallelism. Ephemerality is how you get there.**

You cannot run N agents concurrently if any of them require babysitting, share state, carry bloated context, or need the human in the middle. Every design choice in this system — ephemeral clones, one-shot builds, plan-as-handoff — exists so work can fan out.

Meanwhile, `task` had a confused identity. Its prompt said "design + build for small features" — which is just a shortcut around plan/build. The reason it survives (as `hack`): **hack is for work where the planning artifact shouldn't live in git.** Either because no meaningful plan is possible (debugging, CSS iteration, investigation) or because the plan is too trivial to persist (tiny fixes). It's not a lesser plan/build — it's a different mode for a different kind of work.

## What's Already Done (by the plan agent)

These changes were made during the planning session because they're context-dependent work — writing and framing that required the conversational context to get right.

- **README "Why Ephemerality" section** — drafted during the planning session but pulled back out by the user for further tone/structure iteration. Not currently in README.md. The philosophy, principles, and structure are captured in the plan sections below. The user will re-add this section to the README themselves — the build agent should NOT attempt to write it.
- **Hack agent prompt** — opening paragraph rewritten in `prompts/task-agent.md`. New framing: "exploratory work, debugging, UI iteration, and small changes." Dropped "small features" identity. Kept the two-phase structure (it wasn't broken — it just needed reframing, not removal). Kept "wait for approval" as "wait for the human to approve the approach."
- **Plan agent prompt** — added Scope Awareness section (think about whether the plan fits in a single build session, flag when it's growing too big) and Thread Tracking section (track open/resolved discussion threads, let the human explore, gently surface when threads pile up).

## What's Left for the Build Agent (mechanical work)

- Rename `bin/task` → `bin/hack` and update all internal strings: usage text, tab title (`TASK:` → `HACK:`), `agent=task` → `agent=hack` in session writes
- Rename `prompts/task-agent.md` → `prompts/hack-agent.md`
- Update README: agent descriptions (Task Agent → Hack Agent), workflow section (`bin/task` → `bin/hack`), file tree listing (`task` → `hack` in both `bin/` and `prompts/`)
- Update `bin/status` references from `task` → `hack` (agent type display, coloring)
- Update any references in `lib/agent-session.sh` or `lib/allowed-tools.sh` if they mention task
- Update `docs/multi-org-clone.md` — references `bin/task` in its out-of-scope section

## Out of Scope

- No new features or scripts
- No changes to `bin/clone` or `bin/build`
- No changes to the build agent prompt (but noted as a future recommendation: add a pre-flight scope check where the build agent reads the plan and gut-checks whether the work fits in one session before starting)
- No temp-docs feature (punted)
- No context-monitoring in hack agent (future work — agent tracks its own context health and flags when the session is getting long)

## Key Decisions

- `task` → `hack`. The name signals: not precious, exploratory, in-the-loop. Pairs with plan/build: plan = think, build = execute, hack = get in there.
- Hack survives because it has a clear cogent reason: **work where the planning artifact shouldn't live in git.** Not a shortcut — a different mode for different work.
- The two-phase structure in the hack prompt stays. It wasn't broken — the identity framing was. The phases protect against the agent coding before understanding the problem.
- The plan agent should think about scope (will this fit in one build session?) and track discussion threads (always track, rarely push back).
- Context-dependent work (writing, framing, decisions) stays in the session that produced it. Mechanical work (renames, wiring) hands off to the build agent. It's a spectrum, not a binary.

## Open Questions

None.
