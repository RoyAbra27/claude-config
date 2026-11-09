#!/usr/bin/env bash
# PostToolUse(Edit|Write): format/lint TS/JS on save using the project's OWN
# eslint/prettier (nearest node_modules/.bin). No-ops silently when absent.
# Non-blocking by contract: always exit 0 so a formatter never blocks Claude.
set -o pipefail
INPUT=$(cat)
FILE=$(printf '%s' "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null)
[ -z "$FILE" ] && exit 0
[ -f "$FILE" ] || exit 0

case "$FILE" in
  *.ts|*.tsx|*.js|*.jsx|*.mjs|*.cjs) ;;
  *) exit 0 ;;
esac

# Walk up from the file's directory to find the project's local tool binary.
find_bin() {
  local dir="$1" name="$2" parent
  # Stop when dirname makes no progress: catches "/" and "." but also Windows
  # drive roots ("C:" is a dirname fixpoint in Git Bash, which looped forever).
  while [ -n "$dir" ]; do
    if [ -x "$dir/node_modules/.bin/$name" ]; then
      printf '%s' "$dir/node_modules/.bin/$name"; return 0
    fi
    parent=$(dirname "$dir")
    [ "$parent" = "$dir" ] && return 1
    dir=$parent
  done
  return 1
}

DIR=$(dirname "$FILE")
if ESLINT=$(find_bin "$DIR" eslint); then
  "$ESLINT" --fix "$FILE" >/dev/null 2>&1 || true
fi
if PRETTIER=$(find_bin "$DIR" prettier); then
  "$PRETTIER" --write "$FILE" >/dev/null 2>&1 || true
fi
exit 0
