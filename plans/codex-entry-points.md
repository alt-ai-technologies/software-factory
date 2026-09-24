# Codex Entry Points

## What

Add Codex versions of the factory's six interactive roles. Each gets a prompt in `prompts/codex/` and a launcher with a `-codex` suffix. The human chooses the agent by command name; existing commands continue launching Claude.

| Command | Arguments | Prompt |
| --- | --- | --- |
| `bin/plan-codex` | `<clone-dir> [feature-name]` | `prompts/codex/plan.md` |
| `bin/build-codex` | `<clone-dir>` | `prompts/codex/build.md` |
| `bin/hack-codex` | `<directory>` | `prompts/codex/hack.md` |
| `bin/plan-review-codex` | `<clone-dir>` | `prompts/codex/plan-review.md` |
| `bin/build-review-codex` | `<clone-dir>` | `prompts/codex/build-review.md` |
| `bin/plan-merge-codex` | `<clone-dir> <branch-a> <branch-b>` | `prompts/codex/plan-merge.md` |

The prompt files also work when pasted into an existing Codex session or explicitly read by the agent. They must not depend on being started by a factory launcher to understand their role.

## Why

The human wants to use Codex for planning, building, and the other factory roles, while keeping the established workflow. There are no specific behavior problems to solve yet; the prompts will be tuned through use. Separate prompt files make that iteration straightforward. Suffixes make the new commands easy to discover with shell completion.

## Behavior

### Launching Codex

- Match the corresponding existing command's arguments, directory resolution, and opening task. A directory can be an existing path or the name of a clone alongside software-factory. Paths containing spaces must work.
- Start an interactive Codex session with the target repository as its working directory. Provide the selected prompt's contents and the role-specific opening task as the initial user message. The prompt contents are literal text, never evaluated as shell code.
- Inherit the user's normal Codex configuration, including model, reasoning, permissions, sandbox, approvals, and configured integrations. Do not select a profile, override settings, or edit Codex configuration or target-repo instruction files.
- Keep the existing role-specific starts: planning uses the supplied feature name or asks for one; building looks for the relevant plan; hack asks what the human wants to do; the review roles establish their review target; merge planning receives both branch names.
- Fail clearly on missing required arguments, a missing target directory, a missing prompt, or an unavailable `codex` executable. Validate these before merge preflight performs repository operations. Propagate the Codex process's exit status.
- Use small shared bash helpers for common Codex startup behavior. Keep the entry points simple; the builder decides the internal factoring.

### Merge preflight

`bin/plan-merge-codex` preserves the current `bin/plan-merge` preflight behavior: require a clean working tree, fetch origin, validate both branches, and create local branches for remote-only inputs using the existing behavior. A preflight failure prevents the interactive session from starting. Neither launcher performs the actual merge.

The implementation should share the existing preflight logic where practical, without changing the Claude command's behavior. The current script does not enforce the pushed-branch check mentioned in an older plan; adding that requirement is outside this change.

These shell checks apply when using the merge launcher. When its prompt is used directly, it must not claim the launcher checks have already run: the agent should establish the repository state and branch inputs before analyzing them.

### Codex prompts

Start from the six existing prompts and make narrowly scoped adaptations:

- Preserve the conversational planning style, detailed interviewing, thread tracking, scope awareness, and plan-file handoffs. Planning produces a plan; it does not authorize implementation. The build role executes the selected plan autonomously. Hack still waits for explicit approval of the approach before building.
- Preserve each role's existing branch-check behavior and local commit conventions. A branch choice already approved in the conversation should not be asked again.
- Follow applicable `AGENTS.md` guidance and read `CLAUDE.md` when it contains the target repo's conventions. Respect repo-specific validation instructions, including this repository's no-tests convention, rather than assuming Python commands apply to every project.
- Use tool-neutral wording where the originals name Claude-specific tools. Remove assumptions about Claude authoring existing commits.
- Remove all `.agent-session` instructions. Codex launchers do not read or write session markers or manage terminal titles. A missing factory session marker must not affect any role.
- Keep the factory's workflow rule that the human pushes; do not push, reset, or change remotes autonomously. These are agent instructions. Actual command permissions come from the user's inherited Codex settings; this change does not reproduce Claude's tool allowlist.
- Do not read `.env` files or run code that reads them. Use configured connectors or authenticated CLIs for service access.

Keep each prompt self-contained so the human can use it directly. Independent tuning of the Codex and Claude prompts is intentional; no prompt generation or synchronization system is needed.

### Peer review

Codex remains the reviewer even when Codex is the driving agent. Describe this as a separate review, without promising a different model. Do not add a Claude reviewer.

Preserve the existing review triggers: required for plan, build, and merge planning; on request for hack and the two human-facing review roles. Run one review, share its full result, and stop for the human's judgment. Do not automatically fix findings or rerun the review.

Resolve the contradictory review instructions in the Codex planning prompt: review the named plan with a focused custom prompt about design completeness, contradictions, and missing concerns. Do not also require a branch-diff code review before presenting the plan. Merge planning likewise reviews its named convergence plan. Build review targets the feature changes against the appropriate base. A custom review prompt and `--base` are separate invocation forms and must not be combined.

Place validation, required handoff notes, and the role's pre-review work before its review-and-stop boundary so the instructions do not imply continuing autonomously after showing the results. Planning and merge planning still require human approval before committing the plan or creating the merge branch, as appropriate.

## Boundaries

**In scope:**
- Six Codex prompt files and six executable launchers.
- Small shared helpers for Codex startup and, where useful, existing merge preflight.
- README updates covering command selection, arguments, inherited configuration, direct prompt use, and the fact that Codex sessions are not tracked by the factory dashboard.

**Out of scope:**
- Changing the existing Claude prompts or the behavior of existing commands.
- Removing session tracking from the existing factory commands, status dashboard, or clone lifecycle.
- New provider-selection flags, global defaults, model selection logic, skills, plugins, or application integration.
- Changes to clone creation, environment-file handling, cleanup, or the plan handoff format.
- Implementation of any feature described by a target project's plan during a planning session.

## Integrations

- **`prompts/`** supplies the existing role behavior; **`prompts/codex/`** holds the new independent variants.
- **`bin/`** gains the six entry points while preserving existing command interfaces.
- **`lib/`** can hold shared launch/preflight helpers. **`lib/allowed-tools.sh`** remains specific to the Claude launchers; Codex does not receive its flags or allowlists.
- **`lib/agent-session.sh`**, **`bin/status`**, **`bin/clone`**, and **`bin/clone-nuke`** retain their existing responsibilities. Codex sessions provide no new lifecycle signals to them.
- **Target repositories** provide codebase guidance and `plans/` handoff artifacts. Launcher prompts must use paths relative to the target repository for feature and merge plans.
- **Codex CLI** provides interactive sessions and the existing `codex review` subprocess. The installed CLI help supports an initial prompt and working-directory selection; see the [official command reference](https://learn.chatgpt.com/docs/developer-commands). Codex's automatic repo guidance is described in [AGENTS.md discovery](https://learn.chatgpt.com/docs/agent-configuration/agents-md).

## Key Decisions

- Command names use `-codex` suffixes for completion, rather than an agent-selection flag.
- Codex prompts live in `prompts/codex/` and can evolve independently.
- Launchers inherit Codex settings. The factory supplies the role, target repository, and opening task.
- Codex continues providing peer review. The human decides what to do with findings.
- New Codex entry points do not participate in session tracking.
- This is a first usable version for iteration, not a redesign of the factory workflow.

## Validation

Use shell syntax checks and temporary smoke checks; do not introduce a test suite into this repository. A temporary stand-in for the Codex executable can verify argument passing and exit handling without starting real agent work. Use disposable repositories for merge-preflight checks.

- Each launcher selects its matching prompt, target directory, and opening task. Planning handles both supplied and omitted feature names; merge planning passes both branches.
- Absolute paths, sibling clone names, and paths containing spaces resolve correctly. Multiline prompt content and shell-like text arrive literally.
- The invocation does not override model, profile, sandbox, approval, or other Codex settings and contains no Claude flags.
- Missing prerequisites and failed merge preflight prevent launch with a useful error; nonzero Codex exits remain nonzero.
- Merge preflight retains clean-tree, fetch, and branch-validation behavior, including remote-only branches.
- Codex launchers neither create nor modify `.agent-session`, including when one already exists. Direct prompt use works without a marker.
- Existing Claude commands retain their behavior after any shared-helper extraction.
- Prompt inspection confirms role boundaries, review-and-stop behavior, target-repo guidance, and removal of tracking instructions. Record any subsequent real-session observations as prompt iteration, not as automated validation claims.

## Open Questions

None currently. Prompt refinements will follow actual use.
