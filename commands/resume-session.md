# /resume-session $ARGUMENTS

Resume work from a previous session.

1. If a path is provided in $ARGUMENTS, read that session file
2. If no path is given, list recent files in `~/.claude/sessions/` sorted by date and let the user pick. If the folder is missing or empty, say there are no saved sessions and stop
3. After reading, summarize:
   - What was the goal
   - What was completed
   - What remains to be done
   - Any key context or constraints
4. Confirm the plan with the user before continuing work
