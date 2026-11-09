---
name: plan-redteam
description: Adversarial team-lead review of a written design spec or implementation plan before anyone executes it. A fresh reviewer agent attacks the plan from every angle with evidence, the author verifies each attack and defends or concedes, the reviewer gives a final verdict per attack, and the agreed change list is shown to the user and then applied. Use whenever a spec or plan document is finished and about to be executed, and whenever the user says "red team", "attack this plan", "tear it apart", "poke holes", "stress test the design", "have a team lead review it", "defend your plan", or "review the plan before we start", even if they don't name this skill. Not for choosing between two named options (use consult) and not for reviewing a code diff (use code-review / ponytail-review).
---

# Plan red team

An author can't grade their own plan: they share its blind spots and tend to agree with the conversation that produced it. A reviewer who has only the documents finds the contradictions, the constraints that can't work, and the privacy and data-loss holes. A one-way review then has two failure modes: the author concedes everything, which bloats the plan, or defends reflexively, which keeps the bugs. So the author must answer each attack with evidence, and the two sides converge on a short agreed change list that the user approves.

## Workflow

### 1. Freeze the brief
Write the reviewer's whole input. It never sees the conversation, so everything it needs must be in the brief:
- **Documents:** absolute paths to the spec, the plan, any overview, and the project CLAUDE.md.
- **Evidence it may check:** sample data, the code paths the plan touches, and a scratch directory for read-only scripts. Say which files hold personal or secret data and must never be quoted.
- **Fixed requirements:** the decisions the user already made, one line each, so the reviewer attacks the plan's execution of them rather than re-arguing them. It may still flag one that is impossible or contradicts another.
- **User conventions** the plan must follow (language, tooling, commit style, banned patterns).

### 2. Dispatch the reviewer
Dispatch the `plan-redteam-lead` agent with the brief. Run it in the background and tell the user it is running. It returns at most 15 attacks, most severe first, in a fixed schema, plus what it tried and failed to break.

### 3. Verify, then answer each attack
Treat every attack as a hypothesis. Check it against the primary source (the document text, the data, the actual semantics of the DB or language) before answering. Then choose one answer per attack:
- **concede**, and restate the exact change;
- **counter-propose** a smaller or different change that removes the same risk;
- **defend**, with evidence: a quote, a computation, or a doc reference.

Concede freely when the attack is right, including when it exposes a false justification in your own doc. Defend only where you have evidence. A defense that is only "it's fine" teaches the reviewer nothing.

Send all answers in one message to the same agent (SendMessage to its ID). Ask for exactly this reply:
- `A<n>: accept | insist | compromise - <exact final change>` for each attack;
- a numbered **agreed change list**, grouped by file.

### 4. One round, then escalate
Do one round of debate. If the reviewer still insists on a point you have evidence against, don't loop: put the point to the user as an open decision, with both positions and the tradeoff.

### 5. Show the user the debate before changing anything
The reviewer's verdict is not the user's approval. Show:
- one table: `# | attack (one line) | author answer | agreed outcome`, with blockers marked;
- one line on what the reviewer could not break;
- any escalated decisions;
- the size of the change list, and which files it touches.

Then ask whether to apply it.

### 6. Apply, verify, commit
- Apply the agreed changes. If you delegate the mechanical edits, pass the exact list and require a grep or diff check back.
- Verify the result yourself: grep for every term the changes removed, and read the changed DDL or interfaces.
- Append a `## Red team` section to the plan: the date, the debate table, and the escalated decisions with the user's answers; the heading must stay exactly `## Red team` (`plan-redteam-gate.sh` matches it).
- Commit as one `docs:` change.

## Notes
- **Size.** For a one-page plan, ask for at most 5 attacks. For a multi-task plan of a system that holds data, 15.
- **Stay in scope.** The reviewer attacks the plan, not the user's goals. If it attacks a fixed requirement, the brief was missing it, or the requirement really is impossible. Say which.
- **Don't manufacture disagreement.** If the reviewer finds nothing serious, report that and move on.
