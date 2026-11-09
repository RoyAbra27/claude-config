# /reflect

Turn this session's mistakes into the smallest durable fix. Propose only, and apply nothing without approval.

1. List what went wrong in this session, with evidence from the transcript: user corrections, failed attempts, steps that were redone, rules that were ignored, and tool calls that were denied or blocked. Skip anything that only matters to this one task. If nothing qualifies, say "nothing to reflect" and stop.
2. For each item, check whether an existing rule already covers it: grep `~/.claude/CLAUDE.md`, the relevant `SKILL.md`, `hooks/skill-router.md` and memory.
   - Covered but ignored: propose tightening that rule, or move it up one ratchet layer (CLAUDE.md rule, then a hook in `hooks/guard.sh`).
   - Not covered: propose the smallest fix in the narrowest place, in this order of preference: a line in the skill that was running, then a memory entry, then a CLAUDE.md rule (dated YYYY-MM-DD).
3. Show each proposal as `{problem, evidence, file, exact diff}`, with at most 5 proposals and the highest-impact ones first. Then wait.
4. Apply only the proposals the user approves. When a fix edits a skill that has `evals/evals.json`, add an eval case for it: the prompt that failed this session and the expected behavior, so a later eval run shows whether the fix holds.
5. When a session file exists, add a **Reflection** section to it: what was proposed, what was applied and what was rejected.
