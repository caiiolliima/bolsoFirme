#!/usr/bin/env bash
# check-docs.sh — validates the public documentation set.
#
#   1. every relative markdown link resolves to a file that exists
#   2. no stray TBD/TODO/FIXME markers outside the allow-list
#   3. no Portuguese prose leaked into the English documentation
#
# Exit 0 = clean, 1 = findings printed to stdout.
set -uo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root" || exit 1

status=0

# Public documentation only. docs/superpowers/ holds process artifacts (specs,
# plans) rather than product documentation, and is intentionally exempt.
#
# --others --exclude-standard includes files that exist but are not yet staged,
# which matters because this script runs before each commit: without it, a
# freshly written document would be skipped and pass by not being looked at.
mapfile -t files < <(
  git ls-files --cached --others --exclude-standard '*.md' \
    | grep -v '^docs/superpowers/' \
    | sort -u
)

if [ "${#files[@]}" -eq 0 ]; then
  echo "check-docs: no markdown files tracked yet"
  exit 0
fi

# --- 1. relative links resolve ---------------------------------------------
broken=""
for f in "${files[@]}"; do
  dir="$(dirname "$f")"
  targets="$(grep -oE '\]\([^)]+\)' "$f" \
    | sed -E 's/^\]\(//; s/\)$//' \
    | grep -vE '^(https?://|mailto:|#)' || true)"
  while IFS= read -r target; do
    [ -z "$target" ] && continue
    path="${target%%#*}"
    [ -z "$path" ] && continue
    if [ ! -e "$dir/$path" ]; then
      broken+="  $f -> $target"$'\n'
    fi
  done <<< "$targets"
done
if [ -n "$broken" ]; then
  echo "Broken relative links:"
  printf '%s' "$broken"
  status=1
fi

# --- 2. stray placeholders --------------------------------------------------
# The CLAUDE.md commands section and the README setup section are deliberately
# unfinished until Phase 0 lands; both label themselves "pending Phase 0".
placeholders="$(grep -nE '\b(TBD|TODO|FIXME)\b' "${files[@]}" \
  | grep -v 'pending Phase 0' || true)"
if [ -n "$placeholders" ]; then
  echo "Unlabeled placeholders:"
  echo "$placeholders" | sed 's/^/  /'
  status=1
fi

# --- 3. Portuguese leakage --------------------------------------------------
# The tilde and cedilla characters are effectively absent from English prose,
# which makes them a cheap, low-false-positive signal for untranslated text.
portuguese="$(grep -nE '[ãõç]' "${files[@]}" || true)"
if [ -n "$portuguese" ]; then
  echo "Portuguese text in English documentation:"
  echo "$portuguese" | sed 's/^/  /'
  status=1
fi

if [ "$status" -eq 0 ]; then
  echo "check-docs: clean"
fi
exit "$status"
