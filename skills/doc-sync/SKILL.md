---
name: doc-sync
description: The user's rule that behavior changes must keep documentation in sync within the SAME change - feature docs, module-level CLAUDE.md, diagrams, state machines, status tables, env vars. Use whenever changing code behavior that has associated docs, or when a doc reference may have gone stale. Triggers - behavior change with docs, updating diagrams/state machines, renamed function or removed branch referenced in docs, webhook/contract changes.
---

# Documentation Sync

- If a feature has dedicated docs (e.g. `docs/<feature>.md` or a module-level `CLAUDE.md`), behavior changes MUST update the doc in the same change - webhooks, contracts, state machines, diagrams, env vars all stay in sync.
- When a behavior change invalidates a diagram, state machine, or status table, update the diagram/table - not just the prose.
- When a doc reference becomes stale (renamed function, removed branch, dead webhook), fix it - don't leave misleading text in place.
- High-level overview docs (root `CLAUDE.md`, `README.md`) only need updates for architectural shifts (new service, new tech, new env var), not per-feature tweaks.
- Same bar as tests: untouched docs on a behavior-changing change is a defect.
