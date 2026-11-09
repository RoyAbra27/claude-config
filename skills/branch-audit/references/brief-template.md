# Final whole-branch audit - shared brief

Repo: <absolute path> (<OS; shells available>). Branch `<branch>`, from <base branch> at <merge-base short sha>, HEAD <sha> (<N> commits). <One paragraph: what was built and why.>

## What was built
- <component>: <one line each, with paths>

<Data sensitivity and threat model in the user's words, e.g. "personal data; keep ourselves safe from attacks and bots".>

## Inputs (read what your lane needs; don't read everything)
- Spec (binding authority): <path>
- Plan: <path> (Global Constraints near the top)
- Branch diff, lockfiles and generated files excluded: <package path> (<size>; starts with commit list + stat; read in ranges or grep it, or read files at HEAD)
- Ledger / rulings: <path>. `U-*` (user) rulings are binding; controller rulings MAY be challenged with evidence.
- Known open items (report their STATUS, do not rediscover them): <path or inline list>
- Other evidence: <rehearsal report, earlier reviews>
- Project rules: <repo CLAUDE.md>, <user global rules and the ones that matter here>

## Hard rules
- READ-ONLY. Do not edit, create or delete repo files, commit, run migrations, or write to any database or bucket. Read-only commands are fine. Do not run test suites that reset shared state (<name them>): other lanes run concurrently.
- Never print real data rows, `.env` values or secrets. Do not open <real-data paths>.
- Do not dispatch subagents.
- Verify each finding against the file at HEAD. No concrete evidence (quoted line or command output), no finding. External facts need a URL.
- Severity: Critical (data loss, security breach, data corruption), Important (real bug or risk that should block merge), Minor (should fix, not blocking), Nit.

## Output
Write findings to `<workspace>/audit-<lane>.md` (the one file you may write), one block per finding:

```
### <LANE>-<n>
- severity: Critical | Important | Minor | Nit
- category: <kebab-case>
- claim: <one sentence>
- location: <path:line> (at HEAD)
- evidence: <quoted code / command + output, short>
- failure_scenario: <concrete input/state -> wrong outcome>
- proposed_fix: <smallest fix; the test that should cover it>
- confidence: high | medium | low
```

End with `## Verdict` (merge-ready yes/no and why) and `## Checked and clean` (what you looked at and found fine).

Reply to the controller with ONLY: the file path, counts per severity, and the titles of Critical/Important findings (one line each).
