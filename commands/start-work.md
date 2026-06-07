---
description: Start a new task. Branches, bootstraps state files, produces a plan.
allowed-tools: Read, Write, Edit, Bash, Grep, Glob, Task
argument-hint: <one-line description of the task>
---

# Start work — `$ARGUMENTS`

You are starting a new work session. Follow this ritual exactly.

## 1. Confirm the task

The user provided: `$ARGUMENTS`

If this is missing or vague (less than ~5 words), ask one clarifying question to get a clearer one-sentence description of what success looks like. Then continue.

## 2. Branch

Current git state:
!`git status --short && echo "---" && git branch --show-current`

If the current branch looks like a working branch for this task (was just created, or already named for this work), skip this step.

Otherwise:

- If the working tree is dirty, ask the user how to handle it (stash, commit elsewhere, or skip the branch).
- If clean, create a working branch from the default branch. Branch naming: `<short-kebab-summary>` (e.g. `add-jwt-validation`). If the user has a preferred naming convention, ask once.

## 3. Bootstrap the state directory

Ensure `.claude/state/` exists in the project. If it doesn't, create it and seed the four state files from the templates at `${CLAUDE_PLUGIN_ROOT}/templates/`:

- `.claude/state/plan.md` — will be filled by the planner subagent in the next step
- `.claude/state/state.md` — initialize with: task description, branch, started-at, status `"planning"`
- `.claude/state/handoff.md` — empty for now (created at first compaction)
- `.claude/state/CHANGELOG.md` — append-only log; create with header from template

If `.claude/state/` already exists with old files from a previous task, ask the user before overwriting.

## 4. Plan

Dispatch the **planner** subagent (Task tool) with this brief:

> Read the task description in `.claude/state/state.md`, survey the relevant parts of the codebase (use Read, Grep, Glob freely), and produce a structured plan written to `.claude/state/plan.md`. Follow the format in `${CLAUDE_PLUGIN_ROOT}/templates/plan.md`. Be specific — every checklist item should be small enough to verify in a single test, lint, or visual inspection. Do not implement; produce the plan file only.

After the planner returns:

1. Read `.claude/state/plan.md` and show the user the **Objective** and **Checklist** sections only.
2. Ask: "Plan looks right? Proceed?"
3. If yes: update `state.md` status to `"in-progress"` and start the first checklist item.
4. If no: revise and re-dispatch the planner if needed.

## 5. Establish the loop

Once the plan is approved, **load and follow the `karpathy-coding-guidelines` skill before writing any code**: state assumptions before implementing, keep diffs minimal and surgical, no speculative abstraction or unrequested cleanup, and make sure every changed line traces back to a plan item. Then work the checklist top-to-bottom. After each meaningful change, run `/mg-harness:checkpoint`. At ~50% context use, run `/mg-harness:compact`. When done, run `/mg-harness:finish-work`.

**Do not skip the plan step.** A session without a plan in `.claude/state/plan.md` is one drift warning away from going off the rails.
