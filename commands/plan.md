---
description: Dispatch the planner subagent to write or revise .claude/state/plan.md.
allowed-tools: Read, Task
argument-hint: [optional revision note]
---

# Plan — `$ARGUMENTS`

Dispatch the **planner** subagent with the following brief:

> Read `.claude/state/state.md` for the current task description, survey the relevant codebase, and produce or revise `.claude/state/plan.md`. Follow the template at `${CLAUDE_PLUGIN_ROOT}/templates/plan.md`. Be specific — every checklist step should be small enough that a single verification can confirm it.
>
> If `$ARGUMENTS` is provided, treat it as a revision note: read the existing plan.md and revise based on the note, preserving anything that's already done.
>
> Do not implement. Do not edit application code. Your output is the plan file only.

After the planner returns, read the new `plan.md` and show the user:

1. The **Objective** (one sentence)
2. The **Checklist** (numbered items)
3. Any **Open questions** the planner flagged

Ask: *"Plan looks right? Anything to revise before I start?"*

Do not begin implementation until the user confirms.
