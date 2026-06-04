#!/usr/bin/env bash
# PreToolUse hook (matcher: Edit|Write|MultiEdit) — run the configured
# verify command before any code change lands.
#
# Exit 0 = allow. Exit 2 = block (stderr fed back to Claude).
#
# Strategy: only run when the verify_command userConfig is set. Run it in
# the project root. If it fails, block with the failure output so Claude
# can correct before retrying.

set -uo pipefail

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
VERIFY_CMD="${CLAUDE_PLUGIN_OPTION_VERIFY_COMMAND:-}"

# No verify command configured — let the edit through silently.
if [[ -z "${VERIFY_CMD}" ]]; then
  exit 0
fi

# Drain stdin (tool input JSON). We're not using it in v0.1.
cat > /dev/null

# Run verify in the project root.
cd "${PROJECT_DIR}" || exit 0

OUTPUT=$(bash -c "${VERIFY_CMD}" 2>&1)
EXIT_CODE=$?

if [[ ${EXIT_CODE} -ne 0 ]]; then
  echo "mg-harness: verify_command failed BEFORE this edit landed." >&2
  echo "Command: ${VERIFY_CMD}" >&2
  echo "" >&2
  echo "Output:" >&2
  echo "${OUTPUT}" >&2
  echo "" >&2
  echo "Fix the existing issues first, or note in state.md why this edit is intentional." >&2
  exit 2
fi

exit 0
