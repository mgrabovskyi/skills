---
description: Run tests + lints + dispatch the reviewer subagent. Pass/fail report.
allowed-tools: Read, Bash, Task
---

# Verify

Run the full quality gate. Three stages, run in order. **Do not skip stages.**

## Stage 1 — Tests & lints

Run the configured test command (from `${CLAUDE_PLUGIN_OPTION_TEST_COMMAND}`):

!`${CLAUDE_PLUGIN_OPTION_TEST_COMMAND:-echo "no test_command configured in plugin userConfig"}`

If tests fail: report failures to the user, do not proceed to stage 2.

## Stage 2 — Diff audit

Show the current diff against the base branch:

!`git diff --stat $(git merge-base HEAD origin/main 2>/dev/null || git merge-base HEAD origin/master 2>/dev/null || echo HEAD~10) HEAD`

Read `.claude/state/plan.md`. Spot-check that the diff matches the plan:

- Are there changes to files NOT in the plan? If so, are they justified?
- Are there plan items still unchecked? Why?
- Are there changes that look unrelated to the objective? (Scope creep is the most common cause of bad PRs.)

If the diff is suspicious, flag concerns to the user before stage 3.

## Stage 3 — Independent review

Dispatch the **reviewer** subagent with this brief:

> Read `.claude/state/plan.md`, then audit the current diff (`git diff` against `origin/main` or `origin/master`). Score the work on: (1) does it accomplish the plan's objective, (2) is the code well-structured, (3) any obvious bugs or regressions, (4) any test gaps. Run any tests you can re-run. Return a structured report with sections: PASS/FAIL/CONCERNS, then specifics.

After the reviewer returns, summarize for the user:

- Overall: **PASS** | **FAIL** | **CONCERNS**
- Top three findings (if any)
- Recommended next action

If FAIL or CONCERNS, ask the user whether to fix now or note in state.md and continue.
