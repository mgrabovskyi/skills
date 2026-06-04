#!/usr/bin/env bash
# Stop hook — check whether state.md is stale relative to recent edits.
# Exit 2 with a message in stderr nudges the agent to run /mg-harness:checkpoint
# before ending the session.
#
# "Stale" heuristic: state.md hasn't been modified in 30 minutes OR there
# are uncommitted changes OR CHANGELOG.md has been touched more recently
# than state.md.

set -uo pipefail

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
STATE_FILE="${PROJECT_DIR}/.claude/state/state.md"
CHANGELOG="${PROJECT_DIR}/.claude/state/CHANGELOG.md"

# No state file — nothing to check.
if [[ ! -f "${STATE_FILE}" ]]; then
  exit 0
fi

# Cross-platform mtime in seconds. GNU stat first, then BSD/macOS.
mtime() {
  stat -c %Y "$1" 2>/dev/null || stat -f %m "$1" 2>/dev/null || echo 0
}

NOW=$(date +%s)
STATE_MTIME=$(mtime "${STATE_FILE}")
STATE_AGE_MIN=$(( (NOW - STATE_MTIME) / 60 ))

STALE=false

# Condition 1: state.md untouched for 30+ minutes.
if [[ ${STATE_AGE_MIN} -gt 30 ]]; then
  STALE=true
fi

# Condition 2: CHANGELOG was touched more recently than state.md.
if [[ -f "${CHANGELOG}" ]]; then
  CHANGELOG_MTIME=$(mtime "${CHANGELOG}")
  if [[ ${CHANGELOG_MTIME} -gt ${STATE_MTIME} ]]; then
    STALE=true
  fi
fi

# Condition 3: uncommitted changes.
if git -C "${PROJECT_DIR}" diff --quiet 2>/dev/null && git -C "${PROJECT_DIR}" diff --cached --quiet 2>/dev/null; then
  HAS_UNCOMMITTED=false
else
  HAS_UNCOMMITTED=true
fi

if [[ "${STALE}" == "true" || "${HAS_UNCOMMITTED}" == "true" ]]; then
  echo "mg-harness: state.md is stale or you have uncommitted changes." >&2
  echo "- state.md last updated: ${STATE_AGE_MIN} minutes ago" >&2
  echo "- uncommitted changes: ${HAS_UNCOMMITTED}" >&2
  echo "" >&2
  echo "Run /mg-harness:checkpoint before ending the session so the next one can resume cleanly." >&2
  echo "(If you intentionally want to stop without checkpointing, run /mg-harness:checkpoint with a note explaining why.)" >&2
  exit 2
fi

exit 0
