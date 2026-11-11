## Skill and agent router

When a situation below applies, use the listed skill or agent and say so in one line: "Using <name> to <purpose>". Process skills (brainstorming, debugging, consult, buy-vs-build) come before implementation. A quick question, lookup, or summary needs no skill. This table replaces the superpowers "1% chance, invoke it" rule.

| Situation | Reach for |
|---|---|
| New feature, behavior change, "let's build X", "add an endpoint/module/flow" | superpowers:brainstorming first; `buy-vs-build` the moment a known category appears; `testing-workflow` (spec first) before implementation |
| Bug, failing test, unexpected behavior, "it doesn't work" | Scaled by risk per CLAUDE.md Debugging: first attempt is repro, fix, rerun; superpowers:systematic-debugging with the hypothesis ledger after a failed fix or on production bugs; probes tagged `DEBUG_MODE:`; then `testing-workflow` (failing repro test), then verification-before-completion |
| About to write a queue, retry/backoff, scheduler/cron, parser, auth/RBAC, cache, rate limiter, export, or event bus | `buy-vs-build` (it dispatches the `library-scout` agent) |
| I proposed a plan or architecture that is expensive or hard to reverse, or the user says "are you sure", "double check", "second opinion" | `consult` (it dispatches `consult-side` agents) for a choice between options |
| A written spec or implementation plan is finished and about to be executed, or the user says "red team", "attack/poke holes in this plan", "team lead review" | `plan-redteam` (it dispatches `plan-redteam-lead`, then you defend each attack with evidence); `plan-redteam-gate.sh` blocks ExitPlanMode without it |
| A self-contained code change with a runnable check, delegated off the main thread | `builder` agent; brief ends with `Done when: <command>`, which you rerun before accepting |
| Session ending, or the user says "reflect", "what went wrong", "learn from this session" | `/reflect` (the final `/save-session` runs it too) |
| "Where is X used", "how does Y work", "which files touch Z" across many files | `explore-cheap` agent, not the built-in Explore |
| NestJS module, DI, guard, interceptor, pipe, microservice design | `nestjs-expert` agent |
| Product ideas, "what would make this 10x", "dream up features", competitor or UX research for a roadmap | `product-dreamer` agent; `anthropic-skills:deep-research` instead for a broad multi-source report outside one product |
| Drafting or translating any Hebrew text people will read (UI strings, video, deck, marketing, email, social, docs) | `hebrew-copywriter` agent, before it ships |
| Writing a comment, or a refactor/move over commented code | `code-comment-policy` (existing comments are load-bearing; never drop them silently) |
| Behavior change near feature docs, diagrams, state machines, env vars | `doc-sync` in the same change |
| Just edited CLAUDE.md, a SKILL.md, an agent, a hook, or this file | `prompt-shake` on the diff |
| Reviewing a diff | `ponytail-review` for over-engineering, `/simplify` to apply cleanups, `/code-review` for correctness. Pick the one the request names or implies; run several only when the user asks. superpowers:requesting-code-review only as the review step inside subagent-driven-development |
| A large branch (15+ commits, or auth/personal data/infra/public API) is about to merge or ship, or the user says "full audit", "massive review", "what did we miss", "multiple reviewers" | `branch-audit` (parallel Opus lanes, one consolidator, user decisions, one fix wave); add `security-audit` as the security lane when auth, personal data or a public API is touched |
| Security question, focused vuln review, "pen test", "security audit" of a codebase | `security-audit` (Cloudflare; token heavy); `/security-review` for just the pending diff |
| Architecture or flow diagram, ERD, sequence, or a one-page explainer to share | `archify` |
| Redesign or improve a website or landing page, Android app UX/UI, or a new marketing page | `frontend-flow` (chains impeccable, `/hallmark`, the android skills, mobile MCP); not impeccable or hallmark directly |
| "Improve the architecture", find refactor/deepening opportunities across a repo | `/improve-codebase-architecture` (user-invoked) |
| Steps only the user can do (cloud console, secrets, CI setup, cutover) | `wizard` to generate a guided bash script, instead of a long prose checklist |
| About to say "done", "fixed", "passing" | superpowers:verification-before-completion: run the command, paste the output |
| New or edited skill | `skill-creator:skill-creator` (not superpowers:writing-skills), with `evals/evals.json` alongside it |
| Drive or screenshot a web page | `agent-browser` CLI via Bash for headless checks (`snapshot -i`, `close` when done); `claude-in-chrome` only when the user's logged-in Chrome is needed |
| Break a plan or spec into dependency-ordered tickets | `to-tickets` |
| Several independent tickets to ship as separate PRs, or a plan wave of 2+ file-disjoint tasks | `parallel-ticket-delivery`; propose it and confirm before dispatching (it runs several agents at once) |

Examples:
- "Add a retry wrapper around the S3 client" -> `buy-vs-build` before writing it (check framework built-ins and installed deps, then `library-scout`), then `testing-workflow`.
- "Move sessions from Postgres to Redis, sketch the plan" then "are you sure?" -> `consult`, two `consult-side` dispatches in one message, verify their factual claims, then report.

Red flags. These thoughts mean stop and check the table:

| Thought | Reality |
|---|---|
| "It's a 30-line retry/queue/cache, faster to just write it" | That is exactly the case `buy-vs-build` exists for. Installed deps first, then search. |
| "The plan looks solid, no need for a second opinion" | The author cannot grade its own plan. A fork between options means `consult`; a finished plan about to be executed means `plan-redteam`. |
| "That comment looks redundant, I'll drop it while I'm here" | Existing comments are load-bearing. Flag it, never delete it silently. |
| "I'll just grep for it quickly" | Fan-out search belongs in `explore-cheap`. Keep file dumps out of this context. |
| "I edited CLAUDE.md, done" | Run `prompt-shake` on the diff. Rules only grow otherwise. |
| "Tests probably pass" | Run them. Paste the output. Then say done. |
