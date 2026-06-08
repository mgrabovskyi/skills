#!/usr/bin/env bash
#
# Test harness for the mg-harness hook scripts.
#
# Feeds each hook simulated stdin + env and asserts exit codes, output, and
# side effects — the same checks done by hand during development, made repeatable.
# A hook that silently no-ops (wrong exit code, missing output, broken parse) is
# the worst failure mode for a plugin everyone installs; this is the net for it.
#
# Run locally:  bash tests/run.sh
# CI runs the same. Exits non-zero if any assertion fails.
#
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPTS="$ROOT/scripts"
PASS=0; FAIL=0
ok()  { PASS=$((PASS+1)); printf '  \033[32mPASS\033[0m %s\n' "$1"; }
bad() { FAIL=$((FAIL+1)); printf '  \033[31mFAIL\033[0m %s\n' "$1"; [ -n "${2:-}" ] && printf '       ↳ %s\n' "$2"; }

# A throwaway project with a committed harness state dir.
new_project() {
  local d; d="$(mktemp -d)"
  (
    cd "$d" || exit 1
    git init -q && git config user.email t@t.t && git config user.name t
    mkdir -p .claude/state
    printf '## Objective\nShip the thing.\n\n## Checklist\n- [ ] do A\n- [x] did B\n' > .claude/state/plan.md
    printf '# State\nstatus: in-progress\nnext_step: wire up A\n' > .claude/state/state.md
    printf '# Changelog\n' > .claude/state/CHANGELOG.md
    : > .claude/state/handoff.md
    git add -A && git commit -qm init
  )
  echo "$d"
}

echo "bash -n (syntax) ----------------------------------------"
for s in "$SCRIPTS"/*.sh; do
  if bash -n "$s" 2>/dev/null; then ok "syntax $(basename "$s")"; else bad "syntax $(basename "$s")"; fi
done

echo "load-state.sh -------------------------------------------"
P="$(new_project)"
out="$(CLAUDE_PROJECT_DIR="$P" bash "$SCRIPTS/load-state.sh" 2>&1)"; rc=$?
{ [ $rc -eq 0 ] && printf '%s' "$out" | grep -q "mg-harness-context"; } && ok "injects context" || bad "injects context" "rc=$rc"
D="$(mktemp -d)"
out="$(CLAUDE_PROJECT_DIR="$D" bash "$SCRIPTS/load-state.sh" 2>&1)"; rc=$?
{ [ $rc -eq 0 ] && [ -z "$out" ]; } && ok "silent when no state dir" || bad "silent when no state dir" "rc=$rc"
rm -rf "$P" "$D"

echo "drift-check.sh ------------------------------------------"
P="$(new_project)"
out="$(CLAUDE_PROJECT_DIR="$P" CLAUDE_PLUGIN_OPTION_DRIFT_CHECK_ENABLED=true bash "$SCRIPTS/drift-check.sh" 2>&1)"
printf '%s' "$out" | grep -q "harness-drift-anchor" && ok "re-anchors plan" || bad "re-anchors plan" "$out"
printf '%s' "$out" | grep -q "do A" && ok "includes open checklist item" || bad "includes open checklist item"
out="$(CLAUDE_PROJECT_DIR="$P" CLAUDE_PLUGIN_OPTION_DRIFT_CHECK_ENABLED=false bash "$SCRIPTS/drift-check.sh" 2>&1)"
[ -z "$out" ] && ok "silent when disabled" || bad "silent when disabled" "$out"
rm -rf "$P"

echo "verify-edit.sh ------------------------------------------"
P="$(new_project)"
CLAUDE_PROJECT_DIR="$P" CLAUDE_PLUGIN_OPTION_VERIFY_COMMAND='true'  bash "$SCRIPTS/verify-edit.sh" <<<'{}' >/dev/null 2>&1 && ok "pass -> exit 0" || bad "pass -> exit 0"
CLAUDE_PROJECT_DIR="$P" CLAUDE_PLUGIN_OPTION_VERIFY_COMMAND='false' bash "$SCRIPTS/verify-edit.sh" <<<'{}' >/dev/null 2>&1; [ $? -eq 2 ] && ok "fail -> blocks (exit 2)" || bad "fail -> blocks (exit 2)"
CLAUDE_PROJECT_DIR="$P" bash "$SCRIPTS/verify-edit.sh" <<<'{}' >/dev/null 2>&1 && ok "unset verify_command -> exit 0" || bad "unset verify_command -> exit 0"
rm -rf "$P"

echo "post-edit-log.sh ----------------------------------------"
P="$(new_project)"
printf '{"tool_name":"Edit","tool_input":{"file_path":"%s/src/a.ts"}}' "$P" | CLAUDE_PROJECT_DIR="$P" bash "$SCRIPTS/post-edit-log.sh" >/dev/null 2>&1
grep -q "src/a.ts" "$P/.claude/state/CHANGELOG.md" && ok "appends a changelog entry" || bad "appends a changelog entry"
rm -rf "$P"

echo "checkpoint-freshness.sh ---------------------------------"
P="$(new_project)"
CLAUDE_PROJECT_DIR="$P" bash "$SCRIPTS/checkpoint-freshness.sh" <<<'{"stop_hook_active":false}' >/dev/null 2>&1 && ok "clean repo -> allow stop (0)" || bad "clean repo -> allow stop (0)"
echo "dirty" >> "$P/.claude/state/state.md"
CLAUDE_PROJECT_DIR="$P" bash "$SCRIPTS/checkpoint-freshness.sh" <<<'{"stop_hook_active":false}' >/dev/null 2>&1; [ $? -eq 2 ] && ok "uncommitted -> nudge (2)" || bad "uncommitted -> nudge (2)"
CLAUDE_PROJECT_DIR="$P" bash "$SCRIPTS/checkpoint-freshness.sh" <<<'{"stop_hook_active":true}' >/dev/null 2>&1 && ok "loop guard -> allow stop (0)" || bad "loop guard -> allow stop (0)"
rm -rf "$P"

echo "precompact-handoff.sh -----------------------------------"
D="$(mktemp -d)"
CLAUDE_PROJECT_DIR="$D" bash "$SCRIPTS/precompact-handoff.sh" <<<'{"trigger":"auto"}' >/dev/null 2>&1 && ok "no state dir -> exit 0" || bad "no state dir -> exit 0"
rm -rf "$D"
P="$(new_project)"   # handoff.md starts empty
CLAUDE_PROJECT_DIR="$P" bash "$SCRIPTS/precompact-handoff.sh" <<<'{"trigger":"auto"}' >/dev/null 2>&1 && ok "always exits 0 (never blocks compaction)" || bad "always exits 0"
{ [ -s "$P/.claude/state/handoff.md" ] && grep -q "Objective" "$P/.claude/state/handoff.md"; } && ok "writes mechanical handoff when empty" || bad "writes mechanical handoff when empty"
printf 'MODEL HANDOFF keep-me\n' > "$P/.claude/state/handoff.md"
CLAUDE_PROJECT_DIR="$P" bash "$SCRIPTS/precompact-handoff.sh" <<<'{"trigger":"manual"}' >/dev/null 2>&1
grep -q "MODEL HANDOFF keep-me" "$P/.claude/state/handoff.md" && ok "never clobbers an existing handoff" || bad "never clobbers an existing handoff"
if command -v jq >/dev/null 2>&1; then
  out="$(CLAUDE_PROJECT_DIR="$P" bash "$SCRIPTS/precompact-handoff.sh" <<<'{"trigger":"auto"}' 2>/dev/null)"
  printf '%s' "$out" | jq -e '.hookSpecificOutput.hookEventName=="PreCompact" and (.hookSpecificOutput.additionalContext|type=="string")' >/dev/null 2>&1 \
    && ok "emits valid additionalContext JSON" || bad "emits valid additionalContext JSON" "$out"
else
  echo "  (jq absent — skipping JSON-output assertion)"
fi
rm -rf "$P"

echo "---------------------------------------------------------"
echo "PASS=$PASS  FAIL=$FAIL"
[ "$FAIL" -eq 0 ]
