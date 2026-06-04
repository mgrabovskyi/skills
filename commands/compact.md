---
description: Write a structured handoff and reset context. Run at ~50% context use.
allowed-tools: Read, Write, Edit, Bash
argument-hint: [focus area, e.g. "auth wiring"]
---

# Compact — focus: `$ARGUMENTS`

You are nearing context exhaustion. Capture what matters into a structured handoff before you lose it, then prepare for a clean context reset.

## 1. Write handoff.md

Read the current state files and produce a fresh `.claude/state/handoff.md` from the template at `${CLAUDE_PLUGIN_ROOT}/templates/handoff.md`. The handoff is what a *fresh session* will read to pick up exactly where this one ended.

The handoff must include:

- **Objective** (copy from plan.md — verbatim, do not paraphrase)
- **Status** — what's done, what's in-flight, what's not started
- **Most recent change** — the last commit hash + summary
- **Active focus** — `$ARGUMENTS` if provided, else inferred from the last few interactions
- **In-flight decisions** — anything the agent is mid-decision on; note the options considered
- **Failed approaches & why** — synthesize from CHANGELOG since session start
- **Open questions for the user** — anything blocking
- **Next concrete action** — one sentence, specific enough to start without re-asking

Critical discipline: the handoff should be **dense**, not exhaustive. A fresh session should be able to read it in 60 seconds and start working. If the handoff is over 200 lines, you are summarizing wrong.

## 2. Verify state.md and CHANGELOG.md are current

If state.md hasn't been updated since the last significant change, update it now. If CHANGELOG.md is missing recent edits, append them.

## 3. Commit the handoff

```bash
git add .claude/state/handoff.md .claude/state/state.md .claude/state/CHANGELOG.md
git commit -m "compact: handoff before context reset

<2-3 line summary of what's preserved>"
```

## 4. Tell the user

Report:

- Handoff written to `.claude/state/handoff.md`
- Active focus going forward: <focus>
- Next concrete action: <next>
- Suggest: run `/compact` (Claude Code's built-in compaction) now with the prompt: *"Focus on `$ARGUMENTS`. The full state is in .claude/state/handoff.md which will be reloaded on session resume."*

The `SessionStart` hook will re-inject the handoff into the next context window automatically.
