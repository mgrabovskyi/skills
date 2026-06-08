#!/usr/bin/env bash
#
# Structural lint for mg-harness skills, commands, and agents.
#
# Enforces the repo's own rules (see CLAUDE.md), the mechanical half of
# "is this skill OK to ship":
#   - every SKILL.md / command / agent has valid frontmatter (name, description)
#   - a skill's `name` matches its directory
#   - shippable skills (engineering/management/productivity) are listed in BOTH
#     their bucket README and the top-level README
#   - deprecated/in-progress skills are NOT listed in the top-level README
#
# This catches the exact drift those rules warn about, before it ships. It does
# NOT judge skill quality or triggering — that's what the anthropic-skills
# evaluators are for. Run locally: bash tests/lint-skills.sh ; CI runs the same.
#
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
PASS=0; FAIL=0
ok()  { PASS=$((PASS+1)); printf '  \033[32mPASS\033[0m %s\n' "$1"; }
bad() { FAIL=$((FAIL+1)); printf '  \033[31mFAIL\033[0m %s\n' "$1"; }

# fm_field <file> <field> — print the value of a top-of-file YAML frontmatter field
fm_field() {
  awk -v f="$2" '
    NR==1 && $0!="---" { exit }
    NR==1 { infm=1; next }
    infm && $0=="---" { exit }
    infm && $0 ~ "^"f":" { sub("^"f":[[:space:]]*",""); print; exit }
  ' "$1"
}

TOP_README="README.md"

echo "Skills ------------------------------------------------"
while IFS= read -r skill; do
  dir="$(dirname "$skill")"; name_dir="$(basename "$dir")"
  bucket="$(basename "$(dirname "$dir")")"
  rel="$dir/SKILL.md"
  fname="$(fm_field "$skill" name)"
  fdesc="$(fm_field "$skill" description)"

  if [ -n "$fname" ]; then ok "name present — $rel"; else bad "missing frontmatter name — $rel"; fi
  if [ -n "$fdesc" ]; then ok "description present — $rel"; else bad "missing frontmatter description — $rel"; fi
  if [ -n "$fname" ]; then
    if [ "$fname" = "$name_dir" ]; then ok "name matches dir — $name_dir"; else bad "name '$fname' != dir '$name_dir' — $rel"; fi
  fi

  case "$bucket" in
    engineering|management|productivity)
      if grep -qF "$rel" "$TOP_README"; then ok "in top-level README — $name_dir"; else bad "NOT in top-level README — $name_dir"; fi
      breadme="skills/$bucket/README.md"
      if [ -f "$breadme" ]; then
        if grep -qF "$name_dir" "$breadme"; then ok "in $bucket README — $name_dir"; else bad "NOT in $bucket README — $name_dir"; fi
      else
        bad "missing bucket README — $breadme"
      fi
      ;;
    deprecated|in-progress)
      if grep -qF "$rel" "$TOP_README"; then bad "$bucket skill MUST NOT be in top-level README — $name_dir"; else ok "$bucket skill absent from top-level README — $name_dir"; fi
      ;;
  esac
done < <(find skills -name SKILL.md | sort)

echo "Commands ----------------------------------------------"
for c in commands/*.md; do
  [ -e "$c" ] || continue
  if [ -n "$(fm_field "$c" description)" ]; then ok "description present — $(basename "$c")"; else bad "missing description — $(basename "$c")"; fi
done

echo "Agents ------------------------------------------------"
for a in agents/*.md; do
  [ -e "$a" ] || continue
  n="$(fm_field "$a" name)"; d="$(fm_field "$a" description)"
  if [ -n "$n" ] && [ -n "$d" ]; then ok "frontmatter ok — $(basename "$a")"; else bad "missing name/description — $(basename "$a")"; fi
done

echo "Bucket README links -----------------------------------"
for breadme in skills/*/README.md; do
  [ -e "$breadme" ] || continue
  bucket="$(basename "$(dirname "$breadme")")"
  while IFS= read -r link; do
    target="skills/$bucket/$link"
    if [ -f "$target" ]; then ok "link resolves — $bucket/$link"; else bad "broken/stale link in $bucket README — $link (no such skill)"; fi
  done < <(grep -oE '\(\./[a-z0-9-]+/SKILL\.md\)' "$breadme" | sed 's#(\./##; s#)##')
done

echo "-------------------------------------------------------"
echo "PASS=$PASS  FAIL=$FAIL"
[ "$FAIL" -eq 0 ]
