#!/usr/bin/env bash
# UserPromptSubmit hook — re-anchor the agent to the current plan before each turn.
#
# v0.1 strategy: soft re-anchoring. On every user prompt, if a plan exists,
# echo the plan's objective + the current open checklist items into context.
# This combats drift by re-injecting the goal at every turn — the agent
# sees the plan as recently as it sees the user's prompt.
#
# v0.2 (future): replace the static dump with a small Haiku call that
# compares the prompt to the plan and only emits a warning on divergence.

set -uo pipefail

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
PLAN_FILE="${PROJECT_DIR}/.claude/state/plan.md"

# Skip silently if drift check disabled via plugin config.
if [[ "${CLAUDE_PLUGIN_OPTION_DRIFT_CHECK_ENABLED:-true}" != "true" ]]; then
  exit 0
fi

# Skip silently if no plan exists — nothing to re-anchor to.
if [[ ! -f "${PLAN_FILE}" ]]; then
  exit 0
fi

# Extract objective + unchecked checklist items. The plan template uses:
#   ## Objective
#   <one sentence>
#   ## Checklist
#   - [ ] item
#   - [x] done item
OBJECTIVE=$(awk '/^## Objective/{flag=1; next} /^## /{flag=0} flag' "${PLAN_FILE}" \
  | grep -v '^[[:space:]]*$' | head -n 5 || true)

UNCHECKED=$(awk '/^## Checklist/{flag=1; next} /^## /{flag=0} flag' "${PLAN_FILE}" \
  | grep -E '^- \[ \]' || true)

# Don't inject if we found neither.
if [[ -z "${OBJECTIVE}" && -z "${UNCHECKED}" ]]; then
  exit 0
fi

echo "<harness-drift-anchor>"
echo "Current plan re-anchor. If the user's prompt is unrelated to these items,"
echo "consider pausing to confirm direction before proceeding."
echo ""
if [[ -n "${OBJECTIVE}" ]]; then
  echo "Objective: ${OBJECTIVE}"
fi
if [[ -n "${UNCHECKED}" ]]; then
  echo ""
  echo "Open checklist items:"
  echo "${UNCHECKED}"
fi
echo "</harness-drift-anchor>"
