---
name: state-discipline
description: Use whenever writing, updating, or reading the mg-harness state files (.claude/state/plan.md, state.md, handoff.md, CHANGELOG.md). Ensures consistent format and captures failed approaches. Triggers on phrases like "update state", "write handoff", "checkpoint", "log to changelog", or any modification of files under .claude/state/.
---

# State discipline

This skill enforces the format and conventions of the mg-harness state files. The point: a fresh session — or another collaborator — can pick up any task without re-orienting.

## The four state files

| File | Lifetime | Purpose | When updated |
|---|---|---|---|
| `plan.md` | One task | What we're doing and how | Once at start, revised when scope changes |
| `state.md` | One session | Where we are right now | Every checkpoint |
| `handoff.md` | One compaction | Dense summary for next session | At every compact |
| `CHANGELOG.md` | Append-only | History of every meaningful change | After each edit (auto, via hook) + at each checkpoint (summary) |

## Rules

**1. Files are the source of truth. Chat is not.** If chat history says one thing and `state.md` says another, the file wins. If you find a discrepancy, update the file and tell the user.

**2. `state.md` is short.** Cap at 150 lines. The point is fast rehydration, not history. Move history to `CHANGELOG.md`.

**3. `CHANGELOG.md` is append-only.** Never edit prior entries. Never delete entries. If you discover a prior entry was wrong, append a correction entry.

**4. Capture failed approaches.** This is the single most valuable thing the changelog does. When you try something and it doesn't work, write *why* in the changelog. Future sessions read these entries to avoid repeating mistakes.

**5. `handoff.md` is dense.** A fresh session must be able to read it in 60 seconds. If yours is over 200 lines, you are summarizing wrong.

**6. `plan.md` checklist items are atomic.** Each item should be verifiable in one test, lint, or visual inspection. "Implement auth" is not an item; "Add `verifyAccessToken` to `src/auth/jwt.ts` with unit tests" is.

## Format references

When writing or updating any state file, follow the template structure exactly. Templates live at `${CLAUDE_PLUGIN_ROOT}/templates/`:

- `plan.md`
- `state.md`
- `handoff.md`
- `CHANGELOG.md`

## When you are about to violate a rule

Stop. Explain to the user which rule you would violate and why you think it's necessary. Wait for confirmation before proceeding. The discipline is what makes the harness work; without it the state files become as unreliable as chat history.
