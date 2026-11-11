---
name: debugging-protocol
description: The user's debugging rules - scale the process by risk, the repro gate, the ranked hypothesis ledger, the two-attempt loop bound, and DEBUG_MODE probes. Use whenever a bug, failing test, crash, regression or "it doesn't work" report comes up, before proposing a cause or editing code, alongside superpowers:systematic-debugging.
---

# Debugging protocol

- **Scale by risk (revised 2026-11-11):** a local bug on the first attempt gets repro, fix, rerun the repro. The full protocol (approval before editing, hypothesis ledger) starts after one failed fix attempt, or up front for production or data-loss bugs
- Full protocol: propose the diagnosis + fix plan for my approval BEFORE editing code
- **Repro gate (added 2026-11-09):** before hypothesizing, name one command (test, script, curl) you have already run that reproduces my exact symptom and can go green once fixed. No such command yet = building it is the first task
- **Hypothesis ledger (added 2026-09-01, ranked 2026-11-09):** write 3-5 ranked hypotheses, each with the prediction that would falsify it, and show them to me before testing. Keep them as a `tested_hypotheses` list (hypothesis, evidence, verdict) in the session file (`~/.claude/sessions/`), updated after each attempt; check it before proposing the next attempt and never re-test a ruled-out hypothesis
- **Bound the loop:** after 2 failed attempts at the same symptom, stop. Report the diagnosis and what you ruled out. A third variation is not a fix
- **Temporary probes (added 2026-09-02):** tag every temporary log/probe with `DEBUG_MODE:` in its comment so cleanup is one grep; none may reach a commit. Undo a temporary edit by restoring a backup copy or reversing that exact edit, never `git checkout -- <file>` on a file with uncommitted work (added 2026-11-10)
