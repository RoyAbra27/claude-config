#!/usr/bin/env bash
# SessionStart(startup|resume|clear|compact|fork): stdout is injected into Claude's
# context, restoring working state that a summary drops and a fresh start never had.
# Ground truth from the repo, not from what a session file claims was done.
INPUT=$(cat)
HOOK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CWD=$(printf '%s' "$INPUT" | jq -r '.cwd // empty' 2>/dev/null)
[ -n "$CWD" ] && cd "$CWD" 2>/dev/null

SOURCE=$(printf '%s' "$INPUT" | jq -r '.source // "unknown"' 2>/dev/null)
echo "## Working state from the repo (session start: $SOURCE)"
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "- Branch: $(git branch --show-current 2>/dev/null)"
  echo "- Recent commits:"
  git log --oneline -5 2>/dev/null | sed 's/^/    /'
  CHANGES=$(git status --short 2>/dev/null | head -20)
  if [ -n "$CHANGES" ]; then
    echo "- Uncommitted changes:"
    printf '%s\n' "$CHANGES" | sed 's/^/    /'
  fi
fi

# Added 2026-09-02: skill/agent router, injected every session start (incl. compact) the
# same way the superpowers plugin injects using-superpowers. Revised 2026-11-11: no
# <EXTREMELY_IMPORTANT> wrapper; Claude 5 models over-apply shouted rules (claude.dev
# context-engineering post, 2026-07-24).
ROUTER="$HOOK_DIR/skill-router.md"
if [ -f "$ROUTER" ]; then
  echo
  cat "$ROUTER"
fi
exit 0
