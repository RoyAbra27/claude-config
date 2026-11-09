---
name: branch-audit
description: Full multi-lane audit of a whole feature branch before merge or first deploy - parallel Opus reviewers for the API surface, the data path, spec conformance, deploy and supply chain, the client contract, privacy, and omissions (what nobody thought to build), then one consolidated, verified list with user decisions and a single fix wave. Use when a large branch (roughly 15+ commits, or anything touching auth, personal data, payments, infra or a public API) is about to merge or ship, at the end of subagent-driven-development instead of a single final reviewer when the user wants depth, and whenever the user says "full audit", "massive review", "review everything", "audit the branch", "multiple reviewers", "what did we miss", or "don't be hesitant about tokens". Not for a small diff (use /code-review or ponytail-review) and not for a plan before execution (use plan-redteam).
---

# Branch audit

One reviewer reviewing a big branch finds what its prompt points at and misses the rest: multi-lane audits typically surface things like a missing `Cache-Control: no-store` on token responses, a data store with no backup, or a crash in a client integration guide, none of which a correctness review asks about. But lanes overlap badly when each rediscovers the same open items. So: fewer, sharper lanes; every lane gets the list of already-known open items; one consolidator merges; the controller verifies before the user sees anything.

Cost: about 130-230k tokens per lane on Opus, ~1-1.5M per audit. Say so before dispatching unless the user already waived it.

## Workflow

### 1. Package the branch
- `MERGE_BASE=$(git merge-base <base-branch> HEAD)`. Write one file with the commit list, `--stat`, and `-U10` diff, excluding lockfiles and generated files (`':!*.lock' ':!**/package-lock.json' ':!**/openapi.json' ':!**/*.d.ts'` and the like). Put it in the session scratchpad or another temp dir, never in the repo.
- Collect the **known-open list**: binding user rulings not yet implemented, parked or deferred findings, must-fix items from earlier reviews (from the SDD ledger if there is one). Lanes report the *status* of these, they do not rediscover them.

### 2. Freeze the shared brief
Fill `references/brief-template.md` into a file next to the package. It carries the system summary, inputs, hard rules (read-only, no tests that reset shared DBs, no secrets or real data printed, no subagents) and the fixed finding format. Every lane reads it first; the lane prompt adds only scope.

### 3. Pick lanes and dispatch in one message
Lanes and their scopes are in `references/lanes.md`. Always: `api-surface`, `data-path`, `conformance`, `deploy`, `omissions`. Conditional: `client-contract` (the branch ships a contract or guide for another team's client), `privacy` (personal, health or financial data). Dispatch all chosen lanes in ONE message, background, `model: opus`, general-purpose (or the matching expert agent type, e.g. `nestjs-expert` for a NestJS API surface). Each writes `audit-<lane>.md` and replies with counts and Important+ titles only.

While they run, relay each completion to the user in two or three lines: counts, and the Important titles in plain words. Don't wait silently for all of them.

### 4. Consolidate
When all lanes are back, dispatch one Opus consolidator with `references/consolidator.md`. It merges duplicates, re-verifies every Important+ and every code fix against HEAD, buckets items (FIX-CODE, USER-DECISION, FIX-DOCS, DEFER, DROP), drafts the fix-wave units, and writes lane statistics.

### 5. Decide with the user
- Put every USER-DECISION to the user with AskUserQuestion: the options, your recommendation first, the cost of each in one line.
- Record each answer as a ruling (ledger or session file).

### 6. One fix wave, one re-review
- Write a fix brief: scope = FIX-CODE + FIX-DOCS + decided items; explicitly out of scope = DEFER, DROP, undecided. One implementer (Opus), tests first, commit per work unit, data-loss units first.
- Then one scoped re-review of the fix range against the item list. Residuals get adjudicated, not a second wave.

### 7. Feed the skill
Append the lane statistics (raw, duplicates, unique verified, unique Important+) to `references/lane-history.md`. A lane that produces no unique Important+ across three audits gets merged or cut. Write entries with the codenames in that file and finding classes only: never product names, branch names, SHAs, ticket IDs or bug specifics.

## Notes
- If the user asks "is there any reviewer we didn't dispatch?", answer from `references/lanes.md` "Candidates not in the default set" before inventing one.
- Check `git status` after the lanes return: lanes never edit the repo.
