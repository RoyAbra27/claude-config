---
name: prompt-shake
description: Use after editing a CLAUDE.md, SKILL.md, agent definition, hook message, or system prompt, when a prompt file feels bloated or repetitive, when doing the Ratchet review of rules, or when the user says "prompt-shake", "shake this prompt", or "tighten this skill".
---

# Prompt Shake

Every line is guilty until proven load-bearing. Target: the fewest lines that still cover 100% of needed cases.

## Proofs (a line survives only if one holds)

- **Coverage**: cut it and a real required case falls through.
- **Redundancy**: not already said elsewhere in this file or in a file loaded alongside it (CLAUDE.md, hook output, plugin skills). Same rule twice: keep one.
- **Subsumption**: not a special case of a broader rule already present. Fold it in.
- **Default-knowledge**: a competent model would not do this unprompted.
- **Load-bearing**: output actually changes with vs without the line.
- **Hook-enforced** (this setup): a rule guard.sh already blocks stays in prose only if the model must know it up front to avoid a wasted blocked call. Otherwise cut and let the hook speak.

## Workflow

1. Scope is the working diff of the prompt file when one exists, else the whole file. Read the whole file either way so a new line duplicating an old one is caught, but recommend edits inside the diff window (target the new line, not the old).
2. Audit line by line. Tag each survivor with the proof that keeps it.
3. Report a findings table: `line/block | failed proof + evidence | action (cut / collapse / fold / keep)`. Recommend only. Do not edit yet.
4. Apply only what the user approves, only inside scope.

## Guardrails

- Leanness is not lossy: preserve intent and every load-bearing constraint.
- Justify a cut by showing behavior is unchanged, not by "feels redundant".
- Never add rules or "improve" wording. Subtraction only.
