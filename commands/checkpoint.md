---
description: Snapshot current progress to state.md, append to CHANGELOG, commit.
allowed-tools: Read, Write, Edit, Bash
argument-hint: [short note about what just got done]
---

# Checkpoint — `$ARGUMENTS`

Lightweight save point. Run frequently — after each meaningful change, or every 15–20 minutes during active work.

## 1. Update state.md

Read `.claude/state/state.md`. Update it in place with:

- `last_checkpoint_at`: current ISO timestamp (use `!`date -u +"%Y-%m-%dT%H:%M:%SZ"`)
- `status`: still in-progress, blocked, or needs-review (pick honestly)
- `recent_progress`: append a 1-2 sentence summary of what was just accomplished. Quote `$ARGUMENTS` if provided.
- `next_step`: what the next concrete action is, in one sentence
- `open_questions`: append anything new the agent is unsure about
- `blockers`: append anything blocking forward progress

Keep `state.md` short — under 150 lines. Move history to `CHANGELOG.md`, not `state.md`.

## 2. Append to CHANGELOG.md

Append one entry to `.claude/state/CHANGELOG.md`:

```
## <ISO timestamp> — <one-line summary>
- Files: <list of files changed since last checkpoint>
- Outcome: <what works now that didn't before>
- Failed approaches (if any): <what didn't work and why — DO NOT SKIP THIS WHEN RELEVANT>
```

The "failed approaches" line is the most valuable part of the changelog. Future sessions read this to avoid repeating mistakes.

## 3. Commit

Stage and commit current changes with a structured message:

```bash
git add -A
git commit -m "checkpoint: <one-line summary>

<2-3 sentence body explaining what changed and why.
Reference the plan checklist item.>"
```

If there's nothing to commit, skip the commit step but still update state.md and CHANGELOG.md (the act of pausing to reflect is the point).

## 4. Report

Tell the user, in one short message:

- Checkpoint saved at <timestamp>
- Status: <status>
- Next step: <next_step>
- Commit: <short hash + message>

That's it. Resume work.
