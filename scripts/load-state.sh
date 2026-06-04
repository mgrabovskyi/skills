#!/usr/bin/env bash
# SessionStart hook — inject current task state into Claude's context.
# stdout from this script is appended to the session's initial context.
#
# Strategy: read .claude/state/{state,plan,handoff}.md and the last few
# CHANGELOG entries from the project. Skip silently if state directory missing.

set -uo pipefail

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
STATE_DIR="${PROJECT_DIR}/.claude/state"

# Silent exit if no state directory — fresh project, nothing to inject.
if [[ ! -d "${STATE_DIR}" ]]; then
  exit 0
fi

echo "<mg-harness-context>"
echo "The mg-harness plugin is loading your current task state."
echo "These files persist across sessions — they are the source of truth, not chat history."
echo ""

# --- state.md ---
if [[ -f "${STATE_DIR}/state.md" ]]; then
  echo "## .claude/state/state.md (current session state)"
  echo ""
  cat "${STATE_DIR}/state.md"
  echo ""
fi

# --- plan.md ---
if [[ -f "${STATE_DIR}/plan.md" ]]; then
  echo "## .claude/state/plan.md (current task plan)"
  echo ""
  cat "${STATE_DIR}/plan.md"
  echo ""
fi

# --- handoff.md (only if non-empty — exists after a compaction) ---
if [[ -s "${STATE_DIR}/handoff.md" ]]; then
  echo "## .claude/state/handoff.md (handoff from previous session)"
  echo ""
  cat "${STATE_DIR}/handoff.md"
  echo ""
fi

# --- CHANGELOG.md — last ~50 lines, enough for recent failed approaches ---
if [[ -f "${STATE_DIR}/CHANGELOG.md" ]]; then
  echo "## .claude/state/CHANGELOG.md (recent entries — read for failed approaches)"
  echo ""
  tail -n 50 "${STATE_DIR}/CHANGELOG.md"
  echo ""
fi

# --- git context ---
echo "## Git context"
echo ""
echo "Branch: $(git -C "${PROJECT_DIR}" branch --show-current 2>/dev/null || echo "(not a git repo)")"
echo ""
echo "Recent commits:"
git -C "${PROJECT_DIR}" log --oneline -5 2>/dev/null || true
echo ""

# --- Reminder ---
echo "## Reminders"
echo "- Run /mg-harness:checkpoint after meaningful changes."
echo "- Run /mg-harness:compact at ~50% context usage."
echo "- Run /mg-harness:verify before /mg-harness:finish-work."
echo "- If state files conflict with chat history, the files are correct."
echo "</mg-harness-context>"
