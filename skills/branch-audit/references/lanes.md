# Lanes

Each lane prompt is: "You are the <LANE> lane of a multi-lane final audit. Read <brief path> first; it is your contract. Lane name for IDs and file: `<lane>`." plus the scope below, adapted to the repo's actual stack and paths. Name concrete files; vague scopes produce vague findings.

Every code lane also covers, as a closing section, over-engineering in its area (reinvented stdlib/framework/installed-dep features, abstractions with one implementation, duplicated logic and test setup, swallowed errors, narrating comments) and test gaps for the behaviour it reviewed.

## api-surface (always, when the branch exposes HTTP/RPC)
Attacker and correctness view of every externally reachable entry point.
- Auth: token/code generation entropy, hashing at rest, constant-time compare, expiry, revocation, brute force, rate limits per IP and per identity, client-IP trust behind the host's proxy (X-Forwarded-For).
- HTTP semantics: security headers, `Cache-Control: no-store` on responses carrying secrets, body limits, timeouts aligned with the host's proxy, 404/health routes unthrottled, error body shape and information leaks.
- Every endpoint against the spec's API table and any client guide's state table; races between concurrent requests and background jobs on the same row (separate statements without a transaction or lock).
- Presigned/object-store URLs: what is signed, key namespacing, TTL, overwrite of another tenant's object.
- Framework idiom and DI/module structure.

## data-path (always, when the branch has jobs, queues, migrations or storage)
- State machine of every queue/job: illegal states the schema allows, retries, caps, expiry, idempotency and crash safety between each step (DB commit vs object delete).
- Concurrency: locks shared between jobs, schedules that collide, isolation assumptions, deadlocks.
- Storage edge cases: a missing or misnamed bucket/path reading as empty, partial writes, memory per file at the size cap.
- Migrations: constraints vs states, indexes for every query the code runs, role grants (least privilege), PG-version specifics.
- Backups and restore on paper; what a human sees when a job fails (exit codes, logs, alerts).

## conformance (always)
- Table: every spec requirement and plan global constraint -> implemented / deviated (cite the ruling) / missing.
- Every ruling in the ledger reflected in code and docs; contradictions between rulings; challenge controller rulings with evidence (user rulings are binding).
- Triage every known-open item: must-fix-before-merge / fix-later / drop.
- Doc sync: CLAUDE.md commands, runbooks, env examples, spec vs actual behaviour; banned style (e.g. em-dashes) in changed files.
- Constants duplicated across languages/services that can drift (list both locations).
Keep findings short: this lane's findings are mostly duplicates of other lanes; its table and triage are the value.

## deploy (always, when the branch ships infra, images or dependencies)
- Dependency advisories (`npm audit`, lockfile versions vs OSV), unnecessary new deps.
- Images: base pinning and patch level vs current releases (verify on the release page), non-root, what gets copied, PID 1 signals.
- Infra-as-code validated key by key against the vendor's CURRENT docs (cite URLs): command/entrypoint semantics, network allowlists on databases, secret handling, autodeploy behaviour, cron syntax and time zones, migration step.
- CI presence; what a minimal gate would be.

## client-contract (conditional: the branch ships a contract or guide for another team's client)
A senior engineer on the client platform(s) reads the guide and examples as the implementer would.
- Platform claims checked against current platform docs (background execution limits, OS version differences, storage protection, backup exclusion).
- Every server behaviour the guide states matches the code (status codes, limits, TTLs, reason names, file format vs the parser).
- Rules that can lose user data on the client (deletion triggers, retry caps that misfire under OS scheduling).
- Libraries the guide names actually do what is needed today.

## privacy (conditional: personal, health or financial data)
- Data map table: every place data or identifiers live (buckets, tables, logs, emails, local copies, client queue): what, who can read, retention, deletion path.
- Withdrawal/erasure path end to end; retention of failed and backup objects; identifiers in logs and errors; staging vs production separation; consent alignment for newly collected fields.
- Proposed fixes as engineering steps (a command, a lifecycle rule, a runbook section), not policy essays.

## omissions (always)
Not bugs in existing code: what is ABSENT that a mature team would have built or decided. Walk the system's life on several axes (a user's first day to withdrawal; a request end to end; deploy day, first incident, first schema/format change, 10x scale, a year later; who is on call; money; the clock; the human operators; the second pass through a flow, when the user changes their mind after the result: add, remove, redo, undo) and ask "what happens / who notices / what did we decide". Severity reflects real consequence at the system's realistic scale; include `## Considered and not worth it` and up to 10 ranked `## Suggestions` with cost S/M/L.
Tell it which lanes exist so it skips their ground, and give it one example of the kind of thing wanted (a header nobody asked for, a backup nobody decided).

## Candidates not in the default set
- Dedicated ponytail/over-engineering lane: it tends to yield many Minor findings and few Important ones. Use only when the user asks for simplification specifically; otherwise it is a section in each code lane.
- Separate security and API-correctness lanes, or separate pipeline and DB lanes: merged here because they duplicated each other.
- Performance/load: only with a measured problem or a rehearsal to read.
- Accessibility/UX: for branches with UI.
- Standards/smells lane (from mattpocock code-review): Fowler's smells (long method, large class, long parameter list, feature envy, shotgun surgery, divergent change, data clumps, primitive obsession, duplicated code, speculative generality, message chains, middle man), each reported as smell -> fix, as judgement calls the repo's own standards override, separate from spec conformance. Expect mostly Minor findings, like the ponytail lane; use when the user asks for a maintainability pass.
