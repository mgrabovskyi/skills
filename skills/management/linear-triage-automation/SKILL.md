---
name: linear-triage-automation
description: Event-driven automation that runs when an issue enters a team's Triage column in Linear. Handles duplicate detection, priority parsing from free text, owner assignment via Triage Intelligence with domain-based fallback, and moving the issue out of Triage. Use when the user asks to "triage Linear issues", "auto-triage", "process the Triage queue", "set priority and assign", "clear the Triage column", "run Linear triage", or "run linear-triage-automation". Org-agnostic — expects a routing table and a triage fallback owner to be supplied by the calling team. Does NOT handle handing tickets between engineers (use linear-handoff), and does not cover anything expressible as a native Linear Triage Rule (label→assignee/priority/team) — those belong in Linear, not an agent.
---

# Linear Triage Automation

## Scope and Layering

This skill is meant to sit on top of Linear's native triage capabilities, not replace them. Keep responsibilities split as follows:

- **Triage Rules (Linear, deterministic):** anything mechanical and rule-based — `label → assignee`, `label → priority`, `label → team/project`, status moves. Configure these in Linear itself; they are cheaper and more reliable than agent logic.
- **Triage Intelligence (Linear, AI-assisted):** assignee suggestions, related-issue / duplicate detection, label suggestions. Read its outputs; don't duplicate them.
- **This agent (fuzzy work only):** parsing free-text priority hints from descriptions and titles, inferring root-cause domain when labels are missing, deciding when to fall back, and posting the exact templated comments defined in Steps 1–3 when those steps require a comment.

If a task can be expressed as a Triage Rule, prefer that path and skip the agent.

## Trigger

**When an issue enters Triage** in the target team, run the steps below in order. Process one issue fully before moving to the next.

## Step 1 — Duplicate Check

Before touching priority or assignee, check for duplicates:

1. If **Triage Intelligence** has surfaced a high-confidence related/duplicate issue, treat it as a candidate.
2. Confirm the candidate is genuinely a duplicate: same root cause, same surface, same affected scope. Near-misses ("similar bug, different module") are **not** duplicates.
3. If confirmed:
    - Link the new issue to the original as a duplicate using Linear's duplicate relation.
    - Set the new issue's status to the team's configured **duplicate-resolution status** (default: `Canceled`).
    - Add this exact comment: `Marked as duplicate of <ORIGINAL-ID>. Closing in favor of the original.`
    - **Stop processing this issue.** Do not run Steps 2–5.
4. If no high-confidence duplicate exists, or the surfaced candidate is not a real duplicate, continue to Step 2.

## Step 2 — Set Priority

Parse explicit priority hints from the issue, in this search order:

1. Issue **description** — look for a line matching `Priority: <value>` (case-insensitive). Allow simple Markdown like `**Priority:** High` or `_Priority:_ p1`.
2. Issue **title** — look for the same `Priority: <value>` pattern, or a leading priority token such as `[P1]`, `(urgent)`, `P0:`.
3. Match case-insensitively and ignore surrounding Markdown punctuation.

Map the parsed value to Linear's five priority levels:

| Hint values | Linear Priority |
|---|---|
| `urgent`, `p0`, `critical`, `blocker`, `sev0`, `sev1`, `1` | **Urgent** |
| `high`, `p1`, `sev2`, `2` | **High** |
| `medium`, `normal`, `default`, `p2`, `sev3`, `3` | **Medium** |
| `low`, `minor`, `p3`, `sev4`, `4` | **Low** |
| `none`, `no priority`, `n/a`, `0` | **No priority** |

**Best-practice rubric** — use only when the issue contains a free-text severity description but no explicit code (e.g., "this is breaking prod for everyone"):

- **Urgent** — production outage, security or PII/PHI exposure, data loss or corruption, paying-customer blocker with no workaround, regulatory deadline today.
- **High** — significant customer impact with an awkward workaround, broken core flow for a meaningful subset of users, time-sensitive work tied to an upcoming launch.
- **Medium** — non-urgent bug, quality-of-life improvement, internal tooling, scoped feature work, planned enhancement.
- **Low** — cosmetic issues, nice-to-haves, low-traffic edge cases, backlog cleanup.
- **No priority** — unscoped ideas, exploratory work, items still needing discovery or more information.

**Rules:**

- If no explicit `Priority:` field or recognizable priority token exists, **leave priority unchanged**.
- If a hint exists but the value is unclear, conflicting, or maps to multiple buckets, **leave priority unchanged** and add this exact comment:

  `Unable to set priority automatically due to ambiguous priority value.`

## Step 3 — Assign Owner

Only assign if the issue currently has **no assignee**. If an assignee is already set (by Triage Rules, by Triage Intelligence auto-apply, or by a human), skip this step entirely.

Choose exactly one owner using this cascade, stopping at the first confident match:

1. **Triage Intelligence suggestion.** If Triage Intelligence has **auto-applied** an assignee, accept it and stop. If it has **strongly surfaced** a single suggested assignee (high confidence, on the target team), take that suggestion — it wins over the routing table because it incorporates signal the routing table can't see (recent ownership, code-area expertise, related work).
2. **Routing table.** If the issue carries a label matching a functional area in the routing table, assign to the configured owner for that area.
3. **Root-cause domain inferred from title + description:**
    - UI, visual, styling, layout, accessibility → **frontend** owner
    - API behavior, data model, service logic, business rules in code → **backend** owner
    - Deployment, networking, CI/CD, observability, databases, runtime, secrets → **infra** owner
    - Third-party protocol, webhook, ETL, external-system behavior → **integrations** owner
    - Product workflow, configuration, in-app process, admin tooling → **product** owner
    - Auth, permissions, compliance, vulnerability handling → **security** owner
4. **Fallback.** If no confident match exists, assign to the configured **triage fallback owner** and add this exact comment:

   `Routed to triage fallback. Please reassign if needed.`

**Tie-breakers** (apply in order):

- Visible visual or cosmetic problem → frontend.
- Workflow, configuration, or business-rule problem → product.
- Protocol-level or external-integration behavior → integrations.
- Runtime, provisioning, or cross-cutting performance issue → infra.
- Auth or vulnerability dimension → security.
- Do **not** route by customer or account name alone — always route by domain.
- When two domains apply, route to the one that owns the **root cause**, not the visible symptom.

**Conflict between Triage Intelligence and routing table:** Triage Intelligence wins when its confidence is high. If its suggestion conflicts with a label-based route and confidence is low or absent, prefer the routing table. Never split-assign.

## Step 4 — Decide Whether to Move Out of Triage

After Steps 2 and 3, evaluate the issue's resulting state against this matrix. The issue moves to the team's post-triage status (default: `Todo`) **only** when explicitly indicated; otherwise it stays in Triage.

| Priority outcome | Assignee outcome | Action |
|---|---|---|
| Set (Urgent / High / Medium / Low) | Non-fallback owner (from Triage Intelligence, routing table, or domain inference) | **Move to `post_triage_status`** (default `Todo`) |
| Set (Urgent / High / Medium / Low) | Already assigned before Step 3 (skipped) | **Move to `post_triage_status`** (default `Todo`) |
| Set (Urgent / High / Medium / Low) | Fallback owner | Stay in Triage — fallback comment signals a human is needed |
| Unchanged or `No priority` | Non-fallback owner | Stay in Triage — needs a priority decision |
| Unchanged or `No priority` | Fallback owner | Stay in Triage |
| Ambiguous priority (comment posted) | Any | Stay in Triage |

Rule of thumb: an issue leaves Triage only when **both** a real priority and a real owner are in place. Any fallback, ambiguity, or missing-priority state keeps it in Triage for human review.

## Step 5 — Comment Policy

- Perform every successful action **silently** — no comment when priority is set, owner is assigned, or status is moved.
- **Only** post a comment in these three cases, using the exact text given:
    - Duplicate confirmed (Step 1).
    - Ambiguous priority value (Step 2).
    - Fallback assignment (Step 3).
- Do **not** stack multiple bot comments on the same issue in one pass — at most one comment per run.

## Configuration

This skill is organization-agnostic. The invoking team must supply the following config. The recommended machine-safe form is a flat `key -> handle` mapping; any equivalent representation (YAML, JSON, structured prompt) is fine as long as keys match exactly.

**Routing table:**

```
frontend     -> user
backend      -> user
infra        -> user
integrations -> user
product      -> user
security     -> user
```

**Other settings:**

```
triage_fallback_owner    -> user
post_triage_status       -> Todo
duplicate_status         -> Canceled
```

Notes:

- Keys must match the area names used in Step 3 exactly (`frontend`, `backend`, `infra`, `integrations`, `product`, `security`).
- Values are Linear user handles or member IDs.
- `post_triage_status` and `duplicate_status` must match status names that exist in the target team's workflow.
- Areas the team doesn't have should be omitted; the cascade will fall through to the fallback owner for issues in those domains.

Example invocation:

> Run linear-triage-automation on team `Platform`.
> Routing: `frontend -> @sam`, `backend -> @jules`, `infra -> @priya`, `integrations -> @kai`, `product -> @noor`, `security -> @rae`.
> `triage_fallback_owner -> @eng-lead`, `post_triage_status -> Todo`, `duplicate_status -> Canceled`.
