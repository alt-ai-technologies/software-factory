# Software Factory

A machine that builds software. The core idea: decompose the work of building software into discrete phases with clear handoffs, where each phase has an explicit driver — either a human or an agent — and the other plays a supporting role. The more discrete the phases, the more independently each can be optimized, measured, and progressively automated.

## The pipeline

Every feature flows through three phases:

**Define → Build → Test**

Each phase reads instructions from the previous phase, does its work, and writes instructions for the next. The plan file is the medium — different sections are addressed to different downstream consumers.

### Define (human drives)

The human decides what to build. This is the one phase that demands full human attention by design — it's where intent gets articulated, scope gets bounded, and tradeoffs get decided.

The Interviewer Agent serves the human: it extracts and structures their thinking, asks non-obvious questions, pushes on vague requirements, surfaces contradictions, and reads the existing codebase to ask informed questions about boundaries and integrations. It uses the Review Tool internally to get a second opinion on the plan before presenting findings to the human.

The human is the principal. The agent is a skilled interviewer that doesn't just transcribe but challenges — ultimately producing a formal plan that the human couldn't or wouldn't write themselves. The human brings the intent, the agent brings the rigor.

The output is a plan file containing instructions for the Build phase: what the feature does, why it's being built, what's in scope, what it touches, key decisions, and open questions. The plan includes whatever level of implementation detail the Build Agent needs to execute cleanly — sometimes that's just boundaries and integrations, sometimes it's specific file changes and tool additions. The scope of detail is driven by the complexity of the work.

**Why this matters:** The quality of the Define phase determines how autonomously the rest of the pipeline can run. A thorough definition means the Build Agent is executing against a well-structured spec, not interpreting vague intent. The investment of human attention here buys automation downstream.

### Build (agent drives)

The Build Agent picks up the plan and executes. It reads the codebase, writes tests first, then builds the implementation. It commits incrementally, follows the target repo's conventions, and uses the Review Tool internally to catch issues before escalating.

The Human Reviewer is on call — the Build Agent pulls them in for judgment calls it can't resolve on its own, but the agent decides what's worth escalating and what it can handle. The agent is in charge; the human serves the agent.

The Build Agent mutates the plan file as it works: adding implementation notes where the build deviated from the original plan, and writing a "What to Test" section — instructions for the Test phase. By the time building is done, the plan reflects what was actually built, not just what was intended.

**Why this matters:** The authority inversion from Define is deliberate. You spend human attention where it's most valuable (deciding what to build) and let the agent run where it's most efficient (actually building it). The Build Agent doesn't need to understand why — it needs to understand what and how.

### Test (human drives)

The Human Tester judges the work. They use the plan (including the Build Agent's "What to Test" notes) and the working system to decide: does this do what was intended?

The Domain QA Agent assists — but it's not a generic agent that lives in this repo. It's something the target repo builds for itself. Early on, the human tester does everything. Over time, the target repo develops domain-specific QA that handles more: driving features under test, validating outputs (database state, logs, API responses — whatever matters in your domain), checking regression. The automation boundary isn't designed upfront — it's discovered through operation.

Testing doesn't mutate the plan — it reads it. The output is a gate decision, not a document.

## The gate

Testing produces one of three outcomes:

**Ship** — The feature works. Merge it, done.

**Merge** — The feature works, but it needs to be integrated with other branches or systems. This triggers the Merge path.

**Retry** — Something is wrong. Back through the pipeline.

## The merge path

When multiple feature branches need to come together, the Merge Agent analyzes both sides — reading plans, diffs, and commit messages to understand the intent behind each branch, not just the git conflicts. It identifies overlapping areas, semantic conflicts that git would merge cleanly but that break at runtime, and any real build work required beyond conflict resolution.

**Merge → Build → Test → Gate**

The Merge phase is agent-driven. The Merge Agent does the heavy lifting: finding the merge base, analyzing the divergence, surfacing issues. It interviews the human for judgment calls on ambiguous points, but the agent drives the investigation and produces the plan.

This is the same authority pattern as Build — agent in charge, human on call. The Merge Agent produces a `.merge.md` plan file, which the Build Agent picks up and executes through a normal Build → Test cycle.

## The review tool

The Review Tool is infrastructure, not a role. It's a different model (currently Codex) providing a second opinion — different strengths, different blind spots, that's the point of cross-model review.

Any agent can invoke it. The Interviewer Agent uses it to review plans before presenting to the human. The Build Agent uses it to review code before deciding what to escalate. The Merge Agent uses it to review convergence plans. In every case, the driving agent decides how to filter and present the findings — the Review Tool never talks to the human directly.

## The plan as instructions

The plan file is a chain of handoffs where each phase writes instructions for the next:

- **Define** writes instructions for the builder: what to build, boundaries, integrations, key decisions, and whatever implementation detail helps the Build Agent execute
- **Build** writes instructions for the tester: what was built, what deviated, what to test
- **Merge** writes instructions for the merge builder: merge sequence, conflict resolution, build work required

The format is a markdown file in `plans/`. The content changes meaning at each handoff.

## Hack mode

Not everything flows through the pipeline. Hack mode (`bin/hack`) is for work where the planning artifact shouldn't live in git — debugging, CSS iteration, investigation, tiny fixes. It's not a lesser Define → Build — it's a different mode for a different kind of work. The human and agent collaborate in a single interactive session: design the approach together, then the agent builds it.

## Infrastructure

### Ephemeral repos

Cattle, not pets. Every feature gets its own clone, its own workspace, its own agent. When the feature merges, the repo gets nuked. The remote is the only source of truth — everything local is disposable.

This is load-bearing, not just a nice-to-have. It means features can be built in parallel without stepping on each other. It means a bad build can be thrown away without consequence. It means the merge path exists because branches are genuinely independent.

### Permissions

No `--dangerously-skip-permissions`. Agents get an explicit allowlist of tools. They can read, write, commit, and run tests. They cannot push, reset, or modify remotes. The human pushes when satisfied.

### Key principles

**Get the integrations right because they're expensive to fix.** Get the implementation details right because they help the Build Agent execute cleanly. Don't sweat perfection — a good plan with rough edges beats an overpolished plan that took too long.

**The plan is the handoff, not a perfect spec.** The conversation produces shared understanding. The plan captures the key decisions, boundaries, and enough detail for the Build Agent to not get stuck. The agent figures out the rest.

**Codebase conventions belong in the target repo.** The agent prompts handle process and behavior. The target repo's `CLAUDE.md` handles how to write code that fits.

## Progressive automation

The deeper purpose of this architecture is to create a system that progressively automates itself.

Every phase is a discrete box. Each box is a separate prompt you can tune independently, a separate evaluation surface you can measure, a separate automation candidate, and a separate failure mode. When something goes wrong, you know which box failed.

You can't automate a monolith. You can only automate a discrete box. The more boxes, the more granular your automation frontier becomes.

The Domain QA Agent is the clearest example — but it lives in the target repo, not here. Early on, the human tester does everything. Over time, the target repo's QA agent handles more: driving features under test, validating domain-specific outputs, checking regression. The human focuses on what requires genuine judgment. The boundary between human and agent isn't designed upfront — it's discovered through operation.

This applies everywhere. The Interviewer Agent might eventually handle routine feature definitions without full human attention. The Build Agent might eventually need fewer human judgment calls. The Merge Agent already runs with minimal human input.

The trajectory: more discrete boxes, each independently optimizable, with the human touch points shrinking over time. Define stays human-heavy by design — that's where you want full human attention. Everything else is progressively automatable.
