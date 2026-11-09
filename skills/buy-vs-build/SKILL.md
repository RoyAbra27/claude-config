---
name: buy-vs-build
description: Use before hand-rolling a capability that is a known category (job queue, retry/backoff, scheduler/cron, state machine, parser, auth/RBAC, cache, rate limiter, CSV/Excel export, event bus), including mid-task the moment such code starts appearing, and when the user asks "build vs buy", "does this already exist", "is there a library for this", or "what's out there for X".
---

# Buy vs Build

An agent asked to "add background jobs" writes a tasks table, a polling worker, and a retry column. It works. It is also BullMQ or pg-boss rebuilt badly and owned forever. Ponytail rung 5 catches installed deps only; this catches the rest.

## Search the capability, not the noun

Translate the implementation into the industry term before any search. Searching the user's vocabulary finds blog posts; searching the category finds the field.

| Built | Search |
|---|---|
| table + polling worker + retry count | job queue, background jobs, durable execution |
| retry-with-jitter wrapper | retry / backoff / resilience library |
| setInterval + lockfile | job scheduler, distributed cron |
| role/permission matcher | authorization / policy engine, RBAC |
| handler registry + custom events | pub/sub, event bus |
| wizard diff-and-apply | state machine library |

Unsure of the term? The first search is "what is it called when ...".

## Workflow

1. **Name it.** One line, implementation-free, plus 2-4 canonical terms. Show the user; a wrong name wastes the run.
2. **Inward first.** Manifests (package.json, pyproject.toml), transitive deps, framework built-ins (e.g. NestJS: @nestjs/schedule, @nestjs/throttler, @nestjs/bullmq; Python: APScheduler, Celery, stdlib functools.cache), vendors already paid for (e.g. AWS: SQS, EventBridge, Step Functions). A hit here ends the run. Do not shop for what you already own.
3. **Outward.** Dispatch the `library-scout` agent with the capability, canonical terms, stack, constraints, and a source cap; it runs the searches and returns candidate rows with URL and liveness, never a verdict. One scout is the default; one per lane (ecosystem, commercial, practitioner verdicts) only when stakes are high (own orchestrator vs adopt).
4. **Reduce.** Drop dead options (no release in 2+ years, archived), dedupe, rank by fit to constraints (runtime, infra already running, self-host, real scale). Popularity is a tiebreaker only.
5. **Deliver** 2-4 options max:

| Option | Kind | Why it fits | What you give up | Adoption effort |
|---|---|---|---|---|

Plus three lines: what is already in the stack, what no option covers (stays custom either way), and when rolling your own still wins here (tiny volume, no fan-out, no cross-process coordination).

6. Ask with AskUserQuestion: adopt and remove custom / adopt but keep the custom layer for X / keep custom (record why in one WHY comment) / research more. Never rip out working code on your own initiative.

## Evidence contract

Models invent plausible packages. This skill is worthless if it recommends `@vercel/queue-kit`.

- Always web search. Memory produces hypotheses; only search produces candidates.
- Every candidate has a URL seen in results this run and a liveness signal (last release, last commit, live docs or pricing page).
- Versions, pricing, limits, license: quoted from the source or omitted. Never estimated.
- An empty result is a real finding. Report it.
- A skill that always says "adopt" is a reflex, not research. At low volume the 40-line version often wins; say so when it does.
