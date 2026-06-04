---
name: session-handoff
description: Use when a multi-session leader workflow needs to be paused and resumed in a fresh chat — strategy planning, roadmap review, hiring loop, postmortem drafting, vendor evaluation, OKR shaping, performance-review writing. Triggers on phrases like "hand off this session", "compact this chat for tomorrow", "save my state and pick up later", "I'm running out of context", "create a handoff doc", "checkpoint this conversation", or "snapshot this work for the next session". Produces a structured handoff focused on decisions, asks, and stakes — not a chat summary — and writes it to a destination the user picks (temp file, project state file, Notion page, or Slack canvas).
---

> **Deprecated as of v0.2.0.** This skill is superseded by the harness commands `/mg-harness:compact` (writes a structured handoff at end of session) and the `SessionStart` hook (auto-reloads it on the next session). It is preserved here for history. See [README.md](../../../README.md#5--multi-session-work-loses-state-and-you-re-derive-it-every-time) failure mode #5.


# Session Handoff

Compact the current conversation into a **structured leader-shaped artifact** so a fresh agent — or future-you — can pick up the work without re-deriving context.

This skill is not a chat summary. It is an opinionated brief: decisions made, decisions still open, asks, stakes, and an explicit next-session prompt. A person should be able to act on it directly. A fresh agent should be able to load it as state.

## Companion skills — which handoff do you want?

| If you want to... | Use |
|---|---|
| Hand off a **chat session** to another agent session (this skill) | `session-handoff` |
| Hand off open **Linear tickets** to another engineer (PTO, role change, transfer) | [`linear-handoff`](../../management/linear-handoff/SKILL.md) |
| Get a minimal free-form agent context dump to `/tmp` | Matt Pocock's [`/handoff`](https://github.com/mattpocock/skills/blob/main/skills/productivity/handoff/SKILL.md) — install his marketplace separately if you want the leaner variant |

Decide by the **subject** of the handoff: this conversation, a stack of tickets, or a generic chat dump.

## Step 1 — Confirm scope

Open with one sentence stating what you're about to do: produce a structured handoff for `<topic of the session>`, so a fresh chat can continue without re-deriving context. Ask the user to confirm or correct the topic before proceeding. Keep it short.

If the user has already specified the topic and destination in their message (e.g., "save this strategy session to Notion"), skip to Step 3.

## Step 2 — Pick destination

Use `AskUserQuestion` (or a direct natural-language ask) to choose where the handoff lands. The destination shapes the format and the audience:

- **Temp file** (`mktemp -t handoff-XXXXXX.md`) — default. Lives on disk; future agents read it with `Read`. Use for one-off, same-machine handoffs.
- **Project state file** (`.claude/state/handoff.md` in the current repo) — when the work belongs to a specific repo or project. Compatible with the `adia-engineering` harness pattern. The handoff becomes part of the repo's working state.
- **Notion page** — if a Notion MCP is connected and the work belongs alongside other strategy / planning docs. Ask whether to *append to an existing page* (rolling handoff) or *create a new page* (one-off).
- **Slack canvas** — if a Slack MCP is connected and the handoff needs visibility to a team or co-leader.

If the chosen destination's MCP isn't available, surface that and fall back to the temp file. Don't silently substitute a different destination.

## Step 3 — Compose the handoff

Use this exact structure. Sections in this order:

```
# [Topic] — Handoff
**From:** [previous session description]  **To:** [next session intent]
**Date:** [ISO date]

## Where we are
1–3 sentences. State of the work *as of this moment*. Not the history — the now.

## Decisions made
Bulleted list of decisions that were *closed* this session. Each item:
- **What** was decided
- **Alternative(s)** considered
- **Why** this option won

If none, write: "No decisions closed in this session."

## Decisions still open
Bulleted list of decisions *named* but not closed. Each item:
- The question
- Options considered
- What's blocking closure (missing data, missing stakeholder, missing deadline)

If none, write: "No open decisions."

## Asks
Specific things this leader needs from specific people. Each item:
- **Who** (name + role)
- **What** (concrete thing, not a topic)
- **By when** (date or trigger)
- **Why** (one line of stakes)

Use "need," not "want." If it's not a real ask, don't list it.

## Stakes & deadlines
What's the cost of slipping? Which dates are hard? Which are soft?

## Artifacts touched
File paths, URLs, ticket IDs, doc links — *not* their content. The next session reads them on demand.

## What the next session should do
A direct prompt for the next agent. Imperative voice. Scoped.
End with: "Load these skills if helpful: [list]."
```

Two rules:

- **Decisions and asks are the load-bearing sections.** If the output is mostly *Where we are*, you're writing a summary, not a handoff. Stop and re-think what actually needs to transfer.
- **No duplication of existing artifacts.** If a PRD exists at `docs/foo.md`, reference it under *Artifacts touched* — don't restate it inline. The handoff is a bridge, not a memory.

## Step 4 — Write and confirm

1. Write the handoff to the chosen destination using the appropriate tool (file write for temp / state file, Notion MCP for pages, Slack MCP for canvas).
2. Show the path or URL back to the user.
3. Surface a one-line **resume command** the user can paste into a fresh chat:

   ```
   Read [destination path or URL]. Resume the work described under "What the next session should do."
   ```

4. If the destination requires manual review before the next session uses it (e.g., a Notion page in a shared space), say so explicitly.

## Step 5 — Optional cleanup

If the current chat is near its context limit, suggest the user `/clear` or start a fresh session — the handoff doc now holds the state. Don't force this; some users prefer to continue in the same chat after creating the handoff as a safety net.

## Ground rules

- **One artifact per handoff.** Don't split across multiple files — that defeats the point.
- **Don't write a handoff while the session is still in active discovery.** If decisions are still being negotiated, the asks aren't crisp, or the user is still exploring options, the handoff will be premature. Push back: "We're still in the open-decisions phase — is now the right time to hand off, or do you want to land more decisions first?"
- **Never include credentials, PHI, customer-identifying data, or unredacted strategy that wouldn't survive a leak.** If the session discussed any of these, flag it and offer to redact before writing.
- **The "What the next session should do" section is the only one a fresh agent will execute on.** Make it explicit, scoped, and short. Vague ("continue the work") is a failure mode.
- **Rolling handoffs are valid.** If appending to an existing Notion page, prepend a dated divider and don't rewrite the prior content.
