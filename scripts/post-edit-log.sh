#!/usr/bin/env bash
# PostToolUse hook (matcher: Edit|Write|MultiEdit) — append a one-line
# entry to CHANGELOG.md for every code edit.
#
# Receives the tool call JSON on stdin. Extracts the file path and writes
# a one-liner. Silent on success.

set -uo pipefail

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
CHANGELOG="${PROJECT_DIR}/.claude/state/CHANGELOG.md"

# Skip silently if no state dir.
if [[ ! -d "$(dirname "${CHANGELOG}")" ]]; then
  exit 0
fi

# Read the tool JSON from stdin. Extract file_path (key used by Edit/Write/MultiEdit).
INPUT=$(cat)

# Quick & dependency-free extraction. Looks for the file_path field in JSON.
FILE_PATH=$(echo "${INPUT}" | sed -n 's/.*"file_path"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)
TOOL_NAME=$(echo "${INPUT}" | sed -n 's/.*"tool_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)

# If we couldn't parse, write a minimal entry instead of failing.
TS=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
if [[ -n "${FILE_PATH}" ]]; then
  echo "- ${TS} — ${TOOL_NAME:-edit} ${FILE_PATH}" >> "${CHANGELOG}"
else
  echo "- ${TS} — ${TOOL_NAME:-edit} (path unparsed)" >> "${CHANGELOG}"
fi

exit 0
