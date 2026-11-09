---
name: consult
description: Use when the assistant has proposed a plan, architecture, fix, or design and the user says "double check", "are you sure", "second opinion", "proof this", or "argue both sides", and before committing to any decision that is expensive or hard to reverse.
---

# Consult

Asking the same thread "are you sure?" fails: it grades its own work, shares its own blind spots, and agrees with whatever was already discussed. Move the proposal to a fresh reader.

## Effort

| Level | When | Dispatch |
|---|---|---|
| light (default) | narrow fix, plain "second opinion" | one context-free subagent develops both sides |
| standard | real technical or product fork | two subagents, one side each, dispatched in one message, first round isolated |
| deep | expensive or hard to reverse | standard, then one exchange where each side steelmans the other before answering |

All subagents here run the same model family; say so in the report. A fresh context removes thread bias, not model bias. Never pass conversation history to the subagents (no `fork`).

## Workflow

1. **Freeze the proposal** into a standalone brief: objective, exact proposed mechanism, hard constraints and invariants, alternatives already rejected and why. No advocacy.
2. **Name the fork** in one sentence: optimize for A accepting cost X, or for B accepting cost Y. If one side violates a hard requirement, or the disagreement is factual (needs a measurement, not a debate), skip to "No live fork".
3. **Brief neutrally.** Not "I chose Redis because it is fast, agree?" but "Durable jobs under constraints [..]. Fork: Postgres-backed simplicity vs Redis-backed queue runtime. Argue the assigned side as the strongest complete approach; name its costs, failure modes, and when the other side should win."
4. **Dispatch** the `consult-side` agent per the effort table: light = one call with YOUR SIDE: BOTH; standard = two calls in one message, SIDE A and SIDE B; deep = standard, then one more round where each side receives the other's block. Pass BRIEF, FORK, YOUR SIDE, and REPO PATH only. It returns a fixed schema (position, protects, sacrifices, failure modes, other side wins when, factual claims with evidence).
5. **Verify** every factual claim against the code or docs before reporting it. Subagent findings are hypotheses.
6. **Report** (no transcripts):
   - Common ground
   - Side A: case, what it protects, the price it accepts
   - Side B: same
   - The actual disagreement: the one assumption or value that separates them
   - Recommendation for now, with the adjusted proposal
   - Minority warning preserved: what the chosen side risks missing
   - Reopen when: the observable evidence or threshold that should bring the other side back

**No live fork**: report verified common ground, why the fork collapsed, and the decisive constraint or the measurement needed next. Do not manufacture disagreement.

The user decides. A recommendation is not permission to implement.
