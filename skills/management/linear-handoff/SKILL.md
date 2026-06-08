---
name: linear-handoff
description: Use when an engineer is handing off their open Linear tickets to another engineer — PTO coverage, role change, team transfer, sprint transition, or leaving the company. Triggers on phrases like "hand off my tickets to X", "transfer my Linear work to Y", "reassign my open issues with context", "I'm going on PTO, cover my tickets", "engineer handoff", "ticket transfer", or a slash-style "/handoff from=alice to=bob". Gathers Linear state plus git branch and PR status for each ticket, posts a structured handoff comment, and only reassigns after explicit confirmation. Requires a Linear MCP, git, and the gh CLI. Does NOT trigger for triaging the incoming Triage queue (use linear-triage-automation) or for routine status updates on tickets.
---

# Linear Handoff

Hand off an engineer's open Linear tickets to another engineer **with full context**: current Linear state, branch state, open PRs and review status, and a structured "what's done / what's left / next steps" summary posted as a comment on each ticket before reassignment.

The failure mode this skill exists to prevent is context-free reassignment — the kind where a ticket appears in the new owner's queue with no idea what's been tried, what's blocked, or where the code lives. Every reassignment goes through a handoff comment first.

## Prerequisites

The skill assumes the current workspace has:

- **A Linear MCP server connected** (any flavor — Linear's official MCP, a vendor proxy, or a self-hosted equivalent). The skill uses whichever tool names that MCP exposes; this file deliberately does not hardcode them.
- **`git`** available locally.
- **`gh` CLI** available and authenticated against the relevant GitHub org.

If any are missing, stop at Step 0 and surface what's missing. Don't try to work around it — the handoff will be incomplete without that signal.

## Step 0 — Sanity check

Before parsing arguments, verify the three prerequisites above. If anything fails, stop and tell the user which prerequisite is missing.

## Step 1 — Parse inputs

The skill needs two engineers: `from` and `to`. The user may give them in several shapes:

- Slash-style: `from=alice to=bob`
- Natural language: "hand off Alice's tickets to Bob", "transfer everything from alice@example.com to bob"
- Email prefixes, full emails, display names, or Linear usernames

Extract both. If either is missing or ambiguous, stop and ask:

> Usage: `/handoff from=<engineer> to=<engineer>` — or describe the handoff in plain language (e.g., "hand off Alice's tickets to Bob").

## Step 2 — Resolve users in Linear

1. List users via your Linear MCP's user-listing tool.
2. Match `from` and `to` against display name, full name, or email. Partial match is fine.
3. If a match is ambiguous (multiple plausible matches) or not found, stop and ask the user to clarify which person they meant.
4. Confirm aloud: "Handing off work from **[from name]** to **[to name]**." Wait for the user to acknowledge before proceeding.

## Step 3 — Gather open tickets for `from`

1. List issues assigned to `from`'s Linear user ID. Exclude statuses **Done**, **Canceled**, **Archived** (and any equivalent terminal state the workspace uses).
2. Set the result limit high enough to capture everything; if the API paginates, follow `hasNextPage` / `cursor` until exhausted. Do **not** truncate silently.
3. If no open tickets exist, report "No open tickets found for [from]" and stop.
4. Present the result as a table:

   | # | Ticket | Status | Priority | Team | Title |
   |---|--------|--------|----------|------|-------|

5. Ask: "Hand off **all** tickets, or specify ticket numbers (e.g., `1, 3, 5`)?" Wait for confirmation before continuing.

## Step 4 — Gather context per ticket

For each selected ticket, collect from three sources:

### Linear
- Full ticket details: description, labels, priority, parent/sub-issue relations.
- Comments (read all, not just the latest).
- Linked PR URLs from attachments.

### Branch and PR state
- Run `git fetch --prune` first so remote refs are current.
- Detect the repo's default branch (don't assume `main`):
  ```bash
  git symbolic-ref --short refs/remotes/origin/HEAD | sed 's@^origin/@@'
  ```
  Fall back to `main` only if the symbolic-ref lookup fails.
- Check for the ticket's `gitBranchName` locally and remotely:
  ```bash
  git branch -a --list "*<gitBranchName>*"
  ```
- If a branch exists:
  - Commits ahead of default branch: `git log <default>..<branch> --oneline`
  - Files-changed summary: `git diff <default>...<branch> --stat`
  - Open PRs: `gh pr list --head <branch> --json number,title,state,url,reviewDecision`
  - If a PR exists: `gh pr view <number> --json reviews,comments` to capture review status and recent review comments.
- If no branch exists: note "No branch created yet."

### Code
- If the ticket description names specific file paths, read those files briefly to confirm they still exist and to capture their current shape. Do **not** read everything — only what the ticket explicitly references. The goal is context, not a code audit.

## Step 5 — Compose the handoff comment

For each ticket, build a structured comment in this format:

```
## Handoff: [from name] → [to name]
**Date:** [today's date]

### Current Status
- **Linear status**: [status]
- **Branch**: `<branch-name>` ([X] commits ahead of [default branch]) — or "No branch yet"
- **PR**: [link] (state: [open/closed/merged], review: [approved/changes-requested/pending]) — or "No PR yet"
- **Key files changed**: [from `git diff --stat`, or "N/A"]

### What's Done
- [bullets derived from commit messages, PR description, Linear comments]

### What's Left
- [unmet acceptance criteria from the ticket]
- [known blockers, dependencies, or open questions surfaced in comments]

### Key Decisions Made
- [design or scope decisions from PR review comments or Linear comments]
- [if none found: "No recorded decisions — check with [from name] if needed."]

### Suggested Next Steps
1. [concrete first step to resume the work]
2. [subsequent steps]

### Quick Start
[If branch + PR exist]: Review the open PR at [url], then `git checkout <branch>`.
[If branch only]: `git checkout <branch>` to pick up where [from name] left off.
[If neither]: Start fresh from the ticket description.
```

Two rules for the comment:

- **Every claim must trace to a source you read.** Don't invent decisions, fabricate progress, or guess at what's left. If you can't find it, say so.
- **If a section is empty, say so explicitly** ("No PR yet", "No recorded decisions"). Never leave a header without content.

## Step 6 — Confirm before posting

Present all generated handoff comments back to the user in a single batch. Ask:

> Ready to post these summaries and reassign tickets? (yes / no / edit ticket N)

- **yes** → proceed to Step 7.
- **edit ticket N** → surface that ticket's draft, accept edits inline, then ask again.
- **no** → stop. No comments posted, no reassignments.

This gate is **non-negotiable**. The skill never posts and reassigns without an explicit yes.

## Step 7 — Execute

For each selected ticket, in sequence:

1. Post the handoff comment on the Linear ticket.
2. Reassign the ticket to the `to` engineer.
3. If either step fails, **stop and report which ticket failed at which step**. Do **not** continue with the remaining tickets — fix the failure (or have the user fix it) and resume from the failed ticket.

Posting before reassigning matters: the new owner should never see the ticket in their queue before the context exists on it.

## Step 8 — Final report

Once all tickets are processed, present:

```
## Handoff Complete: [from name] → [to name]

| Ticket | Title | Status | Branch | PR | Comment posted |
|--------|-------|--------|--------|-----|----------------|
| [ID]   | [title] | [status] | yes/no | yes/no | yes |

[X] tickets handed off successfully.
```

## Ground rules

- **Two human-confirmation gates** — Step 3 (which tickets) and Step 6 (post + reassign). Never skip either.
- **Never reassign without posting the handoff comment first.** Context-free reassignment is the exact failure mode this skill exists to prevent.
- **Detect re-handoffs.** Before posting, scan the ticket's existing comments for a `## Handoff:` header. If one exists, surface it to the user and ask whether to layer a new handoff on top or stop. Don't blindly stack duplicate handoffs.
- **Graceful degradation.** If `git` or `gh` is unavailable, the skill still works — it just skips the branch/PR section per ticket and notes "Branch/PR state unavailable: [reason]" in the comment. The handoff is more valuable incomplete than not at all.
- **No PHI or secrets in comments.** If the ticket description or attached PR contains anything that looks like sensitive data (credentials, PHI, customer IDs), redact it in the handoff comment and flag it back to the user before posting.
