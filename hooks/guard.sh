#!/usr/bin/env bash
# PreToolUse(Edit|Write|Bash|PowerShell): hard guard. Exits 2 to BLOCK (stderr = reason
# shown to Claude). Fires before permission-mode checks, so it holds even under
# bypassPermissions. Keep patterns narrow; this is a firewall, not a linter.
INPUT=$(cat)
command -v jq >/dev/null || { echo "Blocked by guard hook: jq is not installed, so the guard can't inspect tool calls. Install jq (winget install jqlang.jq / brew install jq / apt install jq)." >&2; exit 2; }
TOOL=$(printf '%s' "$INPUT" | jq -r '.tool_name // empty' 2>/dev/null)

if [ "$TOOL" = "Bash" ] || [ "$TOOL" = "PowerShell" ]; then
  CMD=$(printf '%s' "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)
  # Narrowed 2026-10-29: rm/push match only outside quotes, so a grep pattern or echo that
  # names them passes; DROP/TRUNCATE still match quoted text because SQL arrives quoted.
  # ponytail: quote stripping is per line, and `bash -c "rm -rf x"` now passes; the
  # auto-mode classifier is the backstop. Cases live in guard.test.sh.
  UNQUOTED=$(printf '%s' "$CMD" | sed -E "s/'[^']*'//g; s/\"[^\"]*\"//g")
  # Added 2026-11-10: SDD plan workspaces are git-ignored scratch; allow rm -rf when every target is under .superpowers/sdd/.
  if printf '%s' "$UNQUOTED" | grep -qE '^[[:space:]]*rm[[:space:]]+-rf([[:space:]]+(\./)?\.superpowers/sdd/[A-Za-z0-9._-]+/?)+[[:space:]]*$'; then exit 0; fi
  if printf '%s' "$UNQUOTED" | grep -qiE '(^|[[:space:];&|])rm[[:space:]]+-[a-z]*r[a-z]*f|[[:space:]]rm[[:space:]]+-[a-z]*f[a-z]*r|git[[:space:]]+push([[:space:]]+[^;&|]*)?[[:space:]](--force([[:space:]]|=|$)|-f([[:space:]]|$))'     || printf '%s' "$CMD" | grep -qiE 'DROP[[:space:]]+(TABLE|DATABASE|SCHEMA)|TRUNCATE[[:space:]]+TABLE'; then
    echo "Blocked by guard hook: command matches a destructive pattern (rm -rf / git push --force / DROP|TRUNCATE). If this is truly intended, run it yourself in the terminal." >&2
    exit 2
  fi
  # Added 2026-11-09 (ported from mattpocock git-guardrails): commands that discard local work.
  # Case-sensitive on purpose: `branch -d` (merged only) must pass while `-D` blocks.
  if printf '%s' "$UNQUOTED" | grep -qE 'git[[:space:]]+(reset[[:space:]]+([^;&|]*[[:space:]])?--hard|clean[[:space:]]+([^;&|]*[[:space:]])?-[a-zA-Z]*f|branch[[:space:]]+([^;&|]*[[:space:]])?-D([[:space:]]|$)|(checkout|restore)[[:space:]]+(--[[:space:]]+)?\.([[:space:];&|]|$))'; then
    echo "Blocked by guard hook: command discards local work (git reset --hard / clean -f / branch -D / checkout . / restore .). If this is truly intended, run it yourself in the terminal." >&2
    exit 2
  fi
  # Added 2026-09-01 (ratchet): no bot attribution trailers in commits.
  # Narrowed 2026-09-02: `git commit` must start a command segment, so the strings inside a
  # quoted test script or heredoc do not trigger it.
  if printf '%s' "$CMD" | grep -qE '(^|&&|;|\|)[[:space:]]*git[[:space:]]+commit' && printf '%s' "$CMD" | grep -qi 'co-authored-by'; then
    echo "Blocked by guard hook: commit message contains a Co-Authored-By trailer. Re-run the commit without any bot attribution line (CLAUDE.md rule)." >&2
    exit 2
  fi
  # Added 2026-09-02 (ratchet): no secret-shaped strings in what Claude commits.
  # ponytail: regex grep on the staged diff; swap for gitleaks if false negatives show up.
  if printf '%s' "$CMD" | grep -qE 'git[[:space:]]+commit'; then
    SECRET_RE='(^|[^A-Za-z0-9_])(sk-ant-[A-Za-z0-9_-]{20,}|sk-[A-Za-z0-9]{32,}|gh[pousr]_[A-Za-z0-9]{20,}|AKIA[0-9A-Z]{16}|xox[baprs]-[A-Za-z0-9-]{10,})|BEGIN (RSA |EC |OPENSSH |DSA )?PRIVATE KEY'
    DIFF=$(git diff --cached -U0 2>/dev/null)
    if printf '%s' "$CMD" | grep -qE '(^|[[:space:]])(-[a-zA-Z]*a[a-zA-Z]*|--all)([[:space:]]|$)'; then
      DIFF="$DIFF
$(git diff HEAD -U0 2>/dev/null)"
    fi
    HIT=$(printf '%s\n' "$DIFF" | grep -E '^\+' | grep -E "$SECRET_RE" | head -3 | cut -c1-120)
    if [ -n "$HIT" ]; then
      echo "Blocked by guard hook: the diff about to be committed contains a secret-shaped string:" >&2
      printf '%s\n' "$HIT" >&2
      echo "Unstage or redact it. If it is a documented placeholder, the user commits manually." >&2
      exit 2
    fi
  fi
  exit 0
fi

# Added 2026-09-01 (ratchet): no em-dashes in new Edit|Write content; use '-'.
# ponytail: edits whose old_string already has an em-dash are exempt, so
# preserving existing text never blocks; tighten to per-occurrence diff if abused.
EMDASH=$(printf '\342\200\224')
NEW=$(printf '%s' "$INPUT" | jq -r '.tool_input.content // .tool_input.new_string // empty' 2>/dev/null)
# Narrowed 2026-09-02: throwaway scripts in the session scratchpad are exempt; the rule is
# about files that ship.
TARGET=$(printf '%s' "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null | tr '\\' '/')
if printf '%s' "$NEW" | grep -qF "$EMDASH" && ! printf '%s' "$TARGET" | grep -qE 'AppData/Local/Temp/claude/|^/tmp/claude'; then
  OLD=$(printf '%s' "$INPUT" | jq -r '.tool_input.old_string // empty' 2>/dev/null)
  if ! printf '%s' "$OLD" | grep -qF "$EMDASH"; then
    echo "Blocked by guard hook: new content contains an em-dash. Use a regular hyphen (-) per CLAUDE.md. Edits preserving existing em-dashes are allowed." >&2
    exit 2
  fi
fi

# Edit|Write: protect secrets, lockfiles, and .git internals.
FILE=$(printf '%s' "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null)
[ -z "$FILE" ] && exit 0
BASE=$(basename "$FILE")

# Allow the harmless env templates that are meant to be edited/committed.
case "$BASE" in
  .env.example|.env.template|.env.sample|.env.dist) exit 0 ;;
esac

case "$FILE" in
  */.git/*)
    echo "Blocked by guard hook: '$FILE' is inside .git/. Use git commands, don't hand-edit repo internals." >&2
    exit 2 ;;
esac

case "$BASE" in
  .env|*.env|.env.*|credentials.json)
    echo "Blocked by guard hook: '$BASE' looks like a secrets file. Edit it manually if intended." >&2
    exit 2 ;;
  package-lock.json|yarn.lock|pnpm-lock.yaml|poetry.lock|uv.lock|Cargo.lock|composer.lock|Gemfile.lock)
    echo "Blocked by guard hook: '$BASE' is a lockfile. Change dependencies via the package manager, not by editing the lockfile." >&2
    exit 2 ;;
esac
exit 0
