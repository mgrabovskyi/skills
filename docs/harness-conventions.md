# mg-harness — conventions

> This file is bundled with the `mg-harness` plugin and loaded into every Claude Code session where the plugin is installed. It establishes how the harness works. Project-level `CLAUDE.md` files merge with this — they extend, they do not override.

## How the harness works

**Files are the source of truth, not chat.** Every long-running task has a state directory at `.claude/state/` with four files (`plan.md`, `state.md`, `handoff.md`, `CHANGELOG.md`). These files persist; chat does not.

**Every task starts with a plan.** Use `/mg-harness:start-work <description>` to begin. The planner subagent writes `.claude/state/plan.md` before any code is touched. No code without a plan.

**Checkpoint often.** Use `/mg-harness:checkpoint` after meaningful changes. The act of pausing to summarize is the point.

**Capture failed approaches.** When something doesn't work, log it in `CHANGELOG.md` with the reason. This is the single highest-leverage thing the harness does — it keeps future sessions from repeating known mistakes.

**Compact before you have to.** Use `/mg-harness:compact` at ~50% context. Don't let context degrade to the point of incoherence.

**Verify before finishing.** Use `/mg-harness:verify` to run the full quality gate (tests + reviewer subagent). Never run `/mg-harness:finish-work` without a passing verify.

## The commands

| Command | When | What it does |
|---|---|---|
| `/mg-harness:start-work <description>` | Beginning a task | Branches, bootstraps state, plans |
| `/mg-harness:plan [note]` | Plan needs revision | Re-runs the planner subagent |
| `/mg-harness:checkpoint [note]` | Every 15–20 min during work | Saves state, commits |
| `/mg-harness:compact [focus]` | At ~50% context | Writes handoff, prepares for reset |
| `/mg-harness:verify` | Before review | Tests + reviewer subagent audit |
| `/mg-harness:finish-work` | Task complete | Verify, push, optional PR via gh |

## When the harness pushes back

The hooks may push back: a `verify-edit.sh` failure blocks a code change, a `checkpoint-freshness.sh` warning fires before session end, the drift anchor re-injects the plan on every prompt. **Treat these as signal, not noise.** They exist because long-running agent work fails in predictable ways, and the hooks catch those failure modes before they propagate.

If a hook is wrong for your project, configure it via `claude plugin config mg-harness`. Don't fight the hook in chat — fix the configuration.

## Customizing per-project

Project-level conventions go in the project's own `CLAUDE.md` — that file merges with this one. Use the project-CLAUDE.md template at `${CLAUDE_PLUGIN_ROOT}/templates/project-CLAUDE.md` as a starting point.
