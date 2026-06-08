# Changelog

All notable changes to **mg-harness** are documented here.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the
project uses [semantic versioning](https://semver.org/): patch for tweaks, minor for
new surfaces (skills, commands, hooks), major for renames or removals.

## [0.4.0] — 2026-06-08

### Added
- **`PreCompact` hook** (`scripts/precompact-handoff.sh`) — fires on **manual *and* automatic** compaction. Guarantees a durable `handoff.md` snapshot before context is lost: it writes a mechanical snapshot only when none exists (never clobbering a model-authored handoff) and re-injects the objective + a state-file pointer via `additionalContext`. Always exits 0 — it never blocks compaction. Closes the gap where auto-compaction wiped un-handed-off work.
- **Hook test suite** (`tests/run.sh`) — 23 behavioral assertions across all six hooks (exit codes, output, side effects), plus a GitHub Actions workflow (`.github/workflows/test.yml`) that runs them on every push and PR, with advisory `shellcheck`.

### Fixed
- `checkpoint-freshness.sh` now honors `stop_hook_active`, so a Stop-time nudge can't wedge the session. Previously it relied on Claude Code's consecutive-block backstop, which forced a couple of "can't stop yet" rounds.

## [0.3.1] — 2026-06-08

### Added
- **Honesty & verification** section in `docs/harness-conventions.md` — anti-fabrication rules loaded into every session: don't claim unverified symbols, cite `path:line`, never invent errors/APIs/test output, ask before adding dependencies, and "I don't know" is an acceptable answer.
- The `reviewer` subagent now verifies factual claims about libraries, APIs, and imports — not just diff-vs-plan alignment.

## [0.3.0] — baseline

mg-harness established as the primary plugin of `mgrabovskyi/skills`: six slash commands, five lifecycle hooks, three subagents, the `.claude/state/` file workflow, and the complementary skills (`karpathy-coding-guidelines`, `state-discipline`, `linear-triage-automation`, `linear-handoff`, `morning-briefing`). History before this point is in the git log.

[0.4.0]: https://github.com/mgrabovskyi/skills/releases/tag/v0.4.0
[0.3.1]: https://github.com/mgrabovskyi/skills/releases/tag/v0.3.1
[0.3.0]: https://github.com/mgrabovskyi/skills/releases/tag/v0.3.0
