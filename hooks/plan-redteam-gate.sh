#!/usr/bin/env bash
# Added 2026-10-26 (ratchet): every plan gets a plan-redteam pass before it is executed.
# PreToolUse(ExitPlanMode): exit 2 BLOCKS unless the plan has a "## Red team" section
# (written by plan-redteam step 6) or an explicit opt-out line "red-team: skip - <reason>".
# PostToolUse(Write|Edit) on docs/superpowers/{plans,specs}/*.md: reminder only (no single
# tool call means "about to execute" there, so it cannot block).
INPUT=$(cat)
TOOL=$(printf '%s' "$INPUT" | jq -r '.tool_name // empty' 2>/dev/null)

if [ "$TOOL" = "ExitPlanMode" ]; then
  PLAN=$(printf '%s' "$INPUT" | jq -r '.tool_input.plan // empty' 2>/dev/null)
  if [ -z "$PLAN" ]; then
    F=$(printf '%s' "$INPUT" | jq -r '.tool_input.planFilePath // empty' 2>/dev/null)
    # ponytail: falls back to the newest plan file; wrong with two plan-mode sessions at once.
    [ -z "$F" ] && F=$(ls -t "$HOME"/.claude/plans/*.md 2>/dev/null | head -1)
    [ -n "$F" ] && [ -f "$F" ] && PLAN=$(cat "$F")
  fi
  if printf '%s' "$PLAN" | grep -qE '^##[[:space:]]+Red team|^red-team: skip - [^[:space:]]'; then
    exit 0
  fi
  echo "Blocked by plan-redteam gate: run the plan-redteam skill on this plan first; its apply step adds a '## Red team' section. For a trivial plan, add the line 'red-team: skip - <reason>' to the plan file instead, then call ExitPlanMode again." >&2
  exit 2
fi

if [ "$TOOL" = "Write" ] || [ "$TOOL" = "Edit" ]; then
  F=$(printf '%s' "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null | sed 's#\\#/#g')
  if printf '%s' "$F" | grep -qE 'docs/superpowers/(plans|specs)/[^/]+\.md$'; then
    jq -n --arg f "$F" '{hookSpecificOutput: {hookEventName: "PostToolUse", additionalContext: ("Plan/spec edited: " + $f + ". Before executing it, run the plan-redteam skill (or record red-team: skip - <reason> in the file for a trivial change).")}}'
  fi
fi
exit 0
