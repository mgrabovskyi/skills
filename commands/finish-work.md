---
description: Finish the session — verify, write final handoff, push, optionally open PR.
allowed-tools: Read, Write, Edit, Bash, Task
---

# Finish work

End-of-session ritual. Eight steps. Stop at the first that fails.

## 1. Run /mg-harness:verify

Invoke the verify command. If the result is **FAIL**, stop here — ask the user whether to fix now or punt to a follow-up task. Do not proceed to PR.

## 2. Confirm plan completion

Read `.claude/state/plan.md`. Are all checklist items either checked, deferred (with a note), or explicitly cut? If unchecked items remain without a note, ask the user how to handle them.

## 3. Final state.md update

Update `.claude/state/state.md`:

- `status`: `"ready-for-review"`
- `last_checkpoint_at`: now
- `recent_progress`: one-sentence summary of the final state
- `next_step`: `"open PR"` (or `"merge"` if no review process)

## 4. Final CHANGELOG entry

Append a summary entry to `.claude/state/CHANGELOG.md` capturing the *whole task*:

```
## <timestamp> — TASK COMPLETE: <task summary>
- Outcome: <what works now>
- Approach: <high-level summary>
- Files changed: <count + key paths>
- Tests added: <yes/no + count>
- Followups: <any deferred work, or "none">
```

## 5. Commit and push

```bash
git add -A
git commit -m "<task summary>

<2-3 sentence body>"

git push -u origin HEAD
```

## 6. Optionally open PR (gh CLI)

If `${CLAUDE_PLUGIN_OPTION_OPEN_PR_WITH_GH}` is `true` and `gh` is available:

```bash
command -v gh >/dev/null && \
  gh pr create --fill --body-file <(cat <<'BODY'
## What
<2-3 sentences>

## Why
<1-2 sentences>

## How tested
<what passed, what's manual, what's deferred>

## Risk
<anything reviewers should pay attention to>

## Plan snapshot
<paste from .claude/state/plan.md — show what was completed>
BODY
)
```

If `gh` isn't installed, skip this step and tell the user the branch is pushed; they can open the PR manually.

## 7. Report

Tell the user:

- Branch pushed: <branch name>
- PR: <url or "open manually">
- Verify result: PASS
- Followups: <list or "none">

## 8. Session done

Next session can pick up via `/mg-harness:start-work <next-task>`.
