---
name: parallel-ticket-delivery
description: Ship several independent tickets at once, each as its own PR, with one isolated worktree agent per ticket and the main session acting as the only coordinator the user talks to. Use when the user has 2+ independent tickets, issues or plan tasks and wants them delivered in parallel, says "ship these in parallel", "one PR each", "fan these out", or when a plan's tasks fall into waves of file-disjoint work. Not for one ticket (just do it or use the builder agent), not for tasks that share files or depend on each other (serialize them, or use superpowers:subagent-driven-development).
---

# Parallel Ticket Delivery

Ship N independent tickets concurrently: one worktree agent per ticket, each branching from the integration branch and ending in its own PR. You are the coordinator. The user talks only to you, so agents report to you and you report to the user only when something needs them.

**Core principle: parallelism is safe only after you prove the tickets touch disjoint files.** Isolation prevents the mess, and your review gate keeps the quality.

## Step 0 - Project conventions

Read the repo's `CLAUDE.md` for the integration branch, the verify commands (tests, lint, typecheck), the shared files to reserve, and how worktrees get dependencies. If anything is missing, ask the user once, in one question batch, before dispatching anything.

## Step 1 - Prove file-disjointness (the gate)

List the exact files each ticket will touch and confirm that **no file appears in two sets**. Git conflicts are per file, so with disjoint sets the PRs merge in any order with no rebasing. Different files in the same directory are fine. A file in two sets means those tickets are **not** parallel, so serialize them. A migration against a shared DB is shared state, so serialize it too.

- **Don't rationalize an overlap away.** "Both just append a distinct key to the same object, it'll merge cleanly" is false under rebase or linear history. A shared file in two sets means serialize, every time.
- **Watch for shared spines.** Adding a config or env field is never one file. It touches the schema, the typed config, the accessor, `.env.example` and the shared test mock. Two tickets that each "just add a field" collide, so serialize them.
- Overlapping tickets can still run as **waves**: wave 1 is the disjoint set, and wave 2 branches from the integration branch after wave 1 merges.

## Step 2 - Reserve shared files

Name the files that NO agent may touch (shared test utils, lockfiles, DB schema, root config) and put them in the shared brief. **Exception:** if a ticket adds a *required* field to a shared config or type, the shared default or mock must change in that same ticket, or typecheck breaks while unit tests pass. Allow exactly one ticket to touch that file. If two tickets need it, that's an overlap from Step 1, so serialize them.

## Step 3 - One shared brief, one delta per ticket

Write the parts every agent shares **once**, to `<scratchpad>/ptd/brief.md`: the integration branch, setup, reserved files, standards and the report format below. Each dispatch then carries only the brief path plus that ticket's delta: branch name, file scope, task, and its `Done when:` command. Check every delta (scope listed, check command present, branch name unique) before dispatching **any** agent. A bad delta found mid-run costs a whole agent.

Shared brief contents:

```
You are in an isolated git worktree (cwd = worktree root), based on <integration-branch>.
SETUP: git switch -c <your branch>. Restore deps the way the project's CLAUDE.md says
  (a fresh worktree has none) and confirm the test runner works before editing.
SCOPE: edit ONLY the files in your ticket. Do NOT touch: <reserved files>. If you need to, STOP and report blocked.
STANDARDS:
 - TDD: failing test first, then the implementation. Reuse existing fixtures and mock factories.
 - Comments: default zero. No restating code, ticket refs, banners or test-phase narration.
   Keep every existing comment. Only add one for a non-obvious WHY.
 - Update the feature doc if the behavior or contract changed.
 - Run your ticket's `Done when:` command plus lint. Conventional commit, no co-author trailers.
   Push and open a PR to <integration-branch>. Never push to the integration branch.
 - Never dispatch subagents.
REPORT, exactly these fields:
  status: done | failed | blocked
  needs_owner: no | <the one question or decision only the user can answer>
  branch: / pr: / files_changed:
  check_command: / exit_code: / output_tail: (last 20 lines)
  unverified: <what you could not run and why, or "nothing">
```

Dispatch every agent in ONE message: Agent tool, `isolation: "worktree"`, `run_in_background: true`, and an explicit `model` (`sonnet` by default, `opus` for tickets that need design judgment). Keep the ticket list and each agent's identity in `<scratchpad>/ptd/ledger.md`, so a compaction can't make you re-dispatch finished work.

## Step 4 - Review gate (you, per PR)

When an agent reports `done`:
1. Rerun its `check_command` in its worktree yourself. A report is a claim, not evidence.
2. Read the production diff and check correctness, scope (no file outside its lane), comments (nothing forbidden added, no useful comment deleted) and tests (no `.only` or `.skip`).
3. Findings go **back to the same agent** with `SendMessage`, verbatim, since it still has the context. Don't fix it yourself. After 2 rounds that don't close it, dispatch a fresh agent on `opus` with the brief, the delta and both failure outputs.
4. Ledger each ticket as `T<n>: done | PR <url> | review clean` or `T<n>: parked - <finding> - <why>`.

## Step 5 - Talk to the user like a coordinator

The user doesn't watch the agents, so don't narrate them.
- **While it runs:** stay silent except for a `needs_owner` question or a ticket that failed past the fix cap. Batch those questions into one message. When the user asks for status, give one line per ticket.
- **At the end:** one report in attention order: (1) decisions needed, (2) failed or parked tickets with the reason, (3) PRs ready to merge, with links. List every judgment call you made on the user's behalf.

## Worktree gotchas

- Base worktrees on the integration branch synced with origin, not on your current checkout, or agents inherit unrelated WIP.
- Claude Code loads every `CLAUDE.md` in the folders above the worktree. Make sure worktrees land somewhere that doesn't pick up another project's rules.
- **Windows:** a `node_modules` junction to the main checkout (`New-Item -ItemType Junction -Path node_modules -Target <main checkout>\node_modules`) beats a full install. Remove the junction **before** removing the worktree, or git fails with "Filename too long".
- If `node_modules/.bin` goes missing in the main checkout, `npm rebuild` restores it without touching the lockfile.

## Common mistakes

| Mistake | Reality |
|---|---|
| Dispatch without the disjointness check | One shared file means a merge conflict and rework. Prove it first. |
| Forbid a shared file that a new required field depends on | The build breaks while unit tests pass. Let the one owning ticket update it. |
| Trust the agent's "tests pass" | Rerun its check. Agents drift scope and silently delete comments. Read each diff. |
| Fix review findings yourself | You lose the coordinator's clean context and the fix skips review. Send it back to the agent. |
| Relay every agent's progress to the user | The user wants one voice. Only `needs_owner` and the final report reach them. |
| Omit the comment policy from the brief | Agents add banners and narration every time. It's in the shared brief for a reason. |
