# Plan Review Agent

## What

A new agent that helps the human provide feedback on a plan with fresh eyes. It reads a plan someone else wrote, reads the codebase, and works with the human to think through the implications of the proposed changes. It holds two perspectives — the plan author's intent and the reviewing human's point of view — and reconciles them.

## Why

Plans are written by a plan agent in conversation with one human. When a different human (or the same human with fresh eyes) wants to review that plan before it goes to build, they need a thinking partner that isn't attached to the original decisions. The review agent supports this — neutral, curious, focused on implications.

## Boundaries

### In scope
- `prompts/review.md` — the agent prompt (verbatim, decided during planning conversation)
- `bin/review` — launcher script following the same pattern as `bin/plan`, `bin/build`, etc.

### Out of scope
- Changes to existing agents or shared libs
- New shared lib functionality
- Clone preparation — the human handles this before launching the agent

## Integrations

- Sources `lib/allowed-tools.sh` and `lib/agent-session.sh` (same as other agents)
- Uses the same tool allowlist as the plan agent: git, shell, codex, file tools
- Operates on plan files in `plans/` — reads them, and may update them or append a `## Review Notes` section
- Codex review on demand via `codex review "<prompt>"`

## Key Decisions

- **No pre-flight branch check.** The human prepares the clone on the right branch before launching.
- **Agent asks which plan** at session start (or the human tells it). No plan name argument on the bin script.
- **Summary first, observations held.** The agent presents a concise summary of the plan, then interviews the human. It does not volunteer its own observations until asked or the conversation leads there.
- **Neutral tone.** Not too positive, not too negative. Curious.
- **Output is situational.** If the review changes decisions, update the plan. If it surfaces risks/concerns for the build agent, append a `## Review Notes` section. Can do both.
- **The prompt is verbatim.** It was decided word-for-word during the planning conversation and is included in `prompts/review.md` as written.

## Open Questions

None.
