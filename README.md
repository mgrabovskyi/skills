# mg-harness

**[Claude Code](https://docs.claude.com/en/docs/claude-code) skills and harness rituals for engineering leaders.**

The coding-agent ecosystem optimizes for engineers writing code. An engineering leader's job is wider than that — code, operational queues, communication, decisions, multi-week initiatives that span dozens of sessions. The skills and rituals here are the parts of that wider job I've shaped Claude around. They're small, opinionated, and meant to make your week *less* reactive, not just faster.

## Quickstart (30-second setup)

```
/plugin marketplace add mgrabovskyi/skills
/plugin install mg-harness@mg-harness
```

That installs the plugin. Two surfaces show up:

- **Skills** — auto-triggered expertise. You describe what you want; the right skill loads. No commands to memorize.
- **Harness** — seven slash commands (`/mg-harness:start-work`, `/mg-harness:grill`, `/mg-harness:checkpoint`, …), six lifecycle hooks, and three subagents that turn a single session into a reliable multi-session workflow.

After install, set the two userConfig values for the verification hooks:

```
/plugin config mg-harness
```

Set `verify_command` (e.g. `npm run lint --silent`) and `test_command` (e.g. `npm test --silent`) for any repo you'll use the harness in. Both are optional; without them the harness still works, just without the auto-verify gates.

## Why these skills and rituals exist

I built these to fix failure modes I kept hitting when applying a coding agent across the whole job, not just code.

### #1 — The agent overbuilds and "improves" things you didn't ask it to touch

> "Perfection is achieved not when there is nothing more to add, but when there is nothing left to take away."
>
> — Antoine de Saint-Exupéry

**The Problem.** You ask for a small change. You get a sprawling diff. Adjacent code gets "improved." Variables get renamed. Error handling appears for impossible cases. Abstractions appear "for flexibility." Reviewing the PR takes longer than writing it would have.

**The Fix** is to load discipline rules **before** the agent writes anything:

- [`karpathy-coding-guidelines`](skills/engineering/karpathy-coding-guidelines/SKILL.md) — surfaces assumptions, enforces minimal diffs, demands verifiable success criteria, and pushes back against speculative abstraction or unrequested cleanup.

The bar to clear: every changed line traces directly back to what you asked for.

> **Tip.** Install this skill on the repo *before* the first agent-written change, not after. Once a codebase has been "improved" by an undisciplined agent, the cleanup cost is higher than the original work.

### #2 — Triage is half mechanical work and half judgment, and the mechanical half eats your week

> "There is nothing so useless as doing efficiently that which should not be done at all."
>
> — Peter Drucker

**The Problem.** Most issue triage is mechanical: parse priority hints, route by domain, dedupe. Linear's native features (Triage Rules, Triage Intelligence) already cover the deterministic half. The judgment half — "this `_Priority:_ p1` buried in the description means Urgent", "this is the same root cause as INF-2104" — is what actually burns calendar time when a human does it.

**The Fix** is to layer agent behavior *on top of* Linear's native triage, not in place of it:

- [`linear-triage-automation`](skills/management/linear-triage-automation/SKILL.md) — runs when an issue enters Triage. Handles only the fuzzy parts: free-text priority parsing, duplicate confirmation, domain inference, and the decision to move out of Triage or leave for a human. Org-agnostic — takes a routing table and a fallback owner from the calling team.

If a triage task can be expressed deterministically, it does not belong in an agent loop.

### #3 — Signal is scattered across Slack, Teams, and email, and the morning catch-up has no edges

> "Clarity about what matters provides clarity about what does not."
>
> — Cal Newport, *Deep Work*

**The Problem.** Your morning starts with hundreds of unread items across multiple tools. Most are noise. The useful items — explicit asks, places you were mentioned, things that shipped, things that are blocked — are buried.

**The Fix** is a scheduled task that does the synthesis before you sit down:

- [`morning-briefing`](skills/productivity/morning-briefing/SKILL.md) — configures a recurring scheduled task. Each morning it pulls the last 24h from Slack/Teams + email and posts a four-section summary (needs from me, mentions, updates, blockers) to a destination you pick.

The skill *builds and installs* the task. The task does the daily work.

### #4 — Handoffs between engineers lose context, and the new owner pays the tax

> "Adding manpower to a late software project makes it later."
>
> — Frederick P. Brooks Jr., *The Mythical Man-Month*

**The Problem.** An engineer goes on PTO, switches teams, or leaves. Their tickets get reassigned — usually with a one-line comment — and the new owner spends a day reconstructing where the work actually is.

**The Fix** is to make context the **precondition** for reassignment, not the afterthought:

- [`linear-handoff`](skills/management/linear-handoff/SKILL.md) — given two engineers, gathers Linear state plus git branch and PR status for every open ticket, composes a structured handoff comment per ticket, shows the drafts back to you for confirmation, and only then posts and reassigns.

The skill posts the comment **before** reassigning — the new owner never sees the ticket in their queue without the context already on it.

### #5 — Multi-session work loses state, and you re-derive it every time

> "The faintest ink is more powerful than the strongest memory."
>
> — Chinese proverb

**The Problem.** The biggest work — a multi-week refactor, an RFC draft, an OKR shaping exercise, a vendor evaluation, a hiring loop — doesn't fit in one chat. You hit the context limit mid-thought, or you stop for the day. When you come back, the first twenty minutes go to re-explaining where things landed, what was decided, and what's still open. The agent re-asks questions you already answered. Decisions that were *closed* get quietly re-litigated. The cost compounds across sessions.

**The Fix** is a *full harness*: state files the agent reads on every session start, structured handoffs at every compaction, and lifecycle rituals that make the discipline automatic instead of relying on you to remember it.

Seven slash commands, six hooks, three subagents, all under the `/mg-harness:` namespace:

| Command | When | What it does |
|---|---|---|
| `/mg-harness:start-work <description>` | Beginning a task | Branches, bootstraps `.claude/state/`, dispatches the **planner** subagent |
| `/mg-harness:grill [topic]` | Before planning a non-trivial task | Interviews you one decision at a time; records resolved decisions to `state.md` |
| `/mg-harness:plan [note]` | Plan needs revision | Re-runs the planner |
| `/mg-harness:checkpoint [note]` | Every 15–20 min during work | Updates `state.md`, appends `CHANGELOG.md`, commits |
| `/mg-harness:compact [focus]` | At ~50% context | Writes a dense `handoff.md` for the next session |
| `/mg-harness:verify` | Before review | Runs `test_command` + dispatches the **reviewer** subagent |
| `/mg-harness:finish-work` | Task complete | Verifies, pushes, optionally opens a PR via `gh` |

And six hooks that run silently in the background:

- `SessionStart` — auto-injects `state.md`, `plan.md`, `handoff.md`, and the last 50 CHANGELOG entries into context
- `UserPromptSubmit` — re-anchors the agent to the plan on every prompt (combats drift)
- `PreToolUse(Edit/Write)` — runs your `verify_command` before any edit lands; exit 2 blocks the edit
- `PostToolUse(Edit/Write)` — appends a one-line entry to `.claude/state/CHANGELOG.md` for every edit
- `Stop` — nudges you to checkpoint if state is stale relative to recent diffs
- `PreCompact` — on manual *or* automatic compaction, ensures a durable `handoff.md` snapshot exists so auto-compaction never wipes out un-handed-off work

The bar to clear: a fresh agent reading `.claude/state/handoff.md` should be able to **act**, not summarize.

> **Tip.** The harness is for work that lives in files in a git repo — code, strategy docs, RFC drafts, OKR pages, postmortems. Use the same commands across all of them; the discipline is what matters, not the file type. For Notion-only work, use the existing `morning-briefing` skill to surface deltas and treat each Notion page as its own state artifact.

> **Note.** This approach supersedes the earlier `session-handoff` skill, which was a lighter-weight predecessor. It has been moved to `skills/deprecated/`. New work should use the harness commands.

### Summary

The bet behind this collection: the highest-leverage thing an engineering leader can do with an agent is **not** "have it write more code." It's **shape your existing work so less of it lands on your calendar**, and **make multi-session work survive context resets** so big initiatives don't keep starting from scratch. These skills and harness rituals are the part of that bet I've shipped publicly.

## Reference

### Engineering — daily code work

- **[karpathy-coding-guidelines](skills/engineering/karpathy-coding-guidelines/SKILL.md)** — Karpathy-style coding discipline: surface assumptions, favor minimal diffs, define verifiable success criteria, avoid speculative abstraction. Use before letting Claude write or edit application code.

### Management — people, process, operational queues

- **[linear-triage-automation](skills/management/linear-triage-automation/SKILL.md)** — Event-driven Linear triage: duplicate detection, free-text priority parsing, owner assignment via Triage Intelligence with a routing-table fallback, and moving issues out of the Triage column.
- **[linear-handoff](skills/management/linear-handoff/SKILL.md)** — Hand off an engineer's open Linear tickets to another engineer with full context (Linear state + git branch + PR status), as a confirmed batch.

### Productivity — cross-cutting daily workflow

- **[morning-briefing](skills/productivity/morning-briefing/SKILL.md)** — Recurring daily rollup of Slack/Teams + email activity, delivered as a four-section summary (asks, mentions, updates, blockers) at the time and destination you pick.
- **[state-discipline](skills/productivity/state-discipline/SKILL.md)** — Auto-triggers when the agent is writing to `.claude/state/*` files. Enforces the format and conventions of the harness state files: plan, state, handoff, CHANGELOG.

### Harness — long-running work

Seven slash commands, listed above in failure mode #5. Each command file is in [`commands/`](commands/); each is a markdown file with frontmatter and can be edited directly.

Three subagents in [`agents/`](agents/), invoked by the commands via the Task tool:

- **[planner](agents/planner.md)** — produces `.claude/state/plan.md`. Reads task description + codebase; writes the plan file only.
- **[researcher](agents/researcher.md)** — bounded codebase investigation. Returns a compressed report.
- **[reviewer](agents/reviewer.md)** — independent audit of diff vs. plan. Scores PASS / CONCERNS / FAIL.

Six hook scripts in [`scripts/`](scripts/), wired in [`hooks/hooks.json`](hooks/hooks.json), with a behavioral test suite in [`tests/run.sh`](tests/run.sh) (run in CI). See the [harness conventions doc](docs/harness-conventions.md) for the full rationale and how to use the state files day-to-day.

## Layout

```
.
├── .claude-plugin/
│   ├── plugin.json             # plugin manifest
│   └── marketplace.json        # one-entry marketplace, points at this plugin
├── skills/
│   ├── engineering/            # daily code work
│   ├── management/             # people, process, queues
│   ├── productivity/           # cross-cutting daily workflow (incl. state-discipline)
│   ├── in-progress/            # drafts not yet ready to ship
│   └── deprecated/             # retired skills, kept for history
├── commands/                   # /mg-harness:* slash commands
├── agents/                     # planner, researcher, reviewer subagents
├── hooks/
│   └── hooks.json              # SessionStart, UserPromptSubmit, PreToolUse, PostToolUse, Stop, PreCompact
├── scripts/                    # shell scripts invoked by hooks
├── tests/                      # run.sh — behavioral tests for the hook scripts (CI)
├── templates/                  # state file templates (plan, state, handoff, CHANGELOG, project-CLAUDE)
├── docs/                       # notes and conventions (harness-conventions.md, workspace-conventions/)
├── CLAUDE.md                   # contributor rules for this repo
├── CHANGELOG.md                # release history (keepachangelog format)
└── README.md
```

A skill is a directory containing `SKILL.md`. The directory name matches the `name` in the frontmatter. Supporting files (templates, longer references) live alongside `SKILL.md` in the same directory and are loaded only when the skill needs them.

A slash command is a single markdown file in `commands/`. The filename (without `.md`) becomes the command name; the YAML frontmatter declares `description`, `allowed-tools`, and `argument-hint`; the body is the prompt template.

A subagent is a single markdown file in `agents/` with YAML frontmatter declaring `name`, `description`, `tools` (allowlist), and `model`. The body is the system prompt.

## Adding a new skill

1. **Pick a bucket:**
   - Code-writing or code-reviewing work → `skills/engineering/`
   - People, process, or operational queues → `skills/management/`
   - Cross-cutting daily workflow, not code-specific → `skills/productivity/`
   - Not ready to ship → `skills/in-progress/`

2. **Create** `skills/<bucket>/<skill-name>/SKILL.md` with frontmatter:

   ```
   ---
   name: skill-name
   description: One sentence describing when Claude should use this skill — name concrete trigger situations or phrases, not just topics.
   ---

   # Body
   ```

3. **List it** in the bucket's `README.md` (if any) and in the top-level `README.md` Reference section.

4. **Bump** the plugin's `version` in `.claude-plugin/plugin.json` (semver — patch for tweaks, minor for new skills, major for renames or removals).

Skills in `in-progress/` and `deprecated/` **do not** appear in the top-level `README.md`.

## Adding a new harness command

1. **Create** `commands/<command-name>.md` with frontmatter:

   ```
   ---
   description: What the command does, one sentence.
   allowed-tools: Read, Write, Edit, Bash, ...
   argument-hint: <hint shown to the user>
   ---

   Prompt body. Use $ARGUMENTS for positional args, !`shell command` to inject
   command output, @path/to/file to inject file contents.
   ```

2. **If the command needs a subagent**, add it to `agents/` with a narrow `tools` allowlist.

3. **If the command needs background discipline**, add a hook script to `scripts/` and wire it in `hooks/hooks.json`.

4. **List it** in the top-level `README.md` Reference section.

5. **Bump** the plugin version.

See [CLAUDE.md](CLAUDE.md) for the full contributor rules.

## License

[MIT](LICENSE)
