---
name: code-comment-policy
description: The user's standard for when to write and when NOT to write code comments, docstrings, and section banners. Use whenever adding, editing, or reviewing comments in any source or test file, or deciding whether a line needs a comment. Default is to write no comments. Also governs existing comments during refactors, moves, and cleanups. Triggers - writing comments, docstrings, section banners, test narration, code review of comments, deleting or rewriting an existing comment.
---

# Code Comment Policy

**Default: write no comments.** Add one only when it carries information a careful reader of the code would otherwise miss.

Add a comment when:
- A hidden constraint, race condition, framework quirk, or workaround for a specific bug makes the code surprising
- A subtle invariant has to be preserved across edits (e.g. "must run before X", "must not throw because the outer handler is the last line of defense")
- A public utility / exported function benefits from a one-paragraph docstring describing intent + edge cases
- A deliberate shortcut with a known ceiling (global lock, O(n²) scan, naive heuristic) - name the ceiling and the upgrade path so it reads as intent, not ignorance: `// global lock; per-account locks if throughput matters`, `# O(n²), fine under ~1k rows; index if it grows`

Do NOT add:
- Comments that **restate what the next line does** ("// loop over users", "// return the result")
- **Test-phase narration** ("// Default mock", "// Lock acquisition succeeds"). If the mock setup needs explanation, put it above the whole test - not as line-by-line voiceover
- **Banners that narrate a `describe` block right below** - the describe label already groups; the banner is pure duplication
- References to the **current ticket, PR, or commit** ("// added for PROJ-639", "// fix for HIGH-15") - those belong in the commit message / PR description and rot as the codebase evolves. *Exception: one-time operational/rollout scripts (runbooks, migration tooling) may reference the tickets and PRs they orchestrate - that context is their purpose, not rot*
- **Docstrings on code you didn't change** - leave existing prose alone unless the change makes it misleading

**Section banners** are allowed at file scope to mark structural transitions that aren't already grouped by `describe` (e.g. `// --- // Module-level mocks // ---`, `// --- // Helpers // ---`, `// --- // Fixtures // ---`), or inside a very long describe block with no inner grouping. Pick one banner style per file and stick to it - prefer dashed `// ---` over equals `// ===`, never mix.

If removing the comment wouldn't confuse a future reader, don't write it. Prefer renaming a variable, splitting a function, or extracting a constant over annotating bad code with prose.

## Existing comments

- Treat every existing comment as load-bearing until proven otherwise. Someone paid a cost to leave it; it may be the only surviving trace of a past incident the code no longer advertises.
- Never delete a comment during a refactor or move unless the code it describes is also removed. Moving code does not justify dropping its comment.
- "Looks redundant" is not sufficient justification for removal.
- If a comment looks stale or wrong, flag it in the response and leave it. Only the user can confirm whether it still reflects reality.
- Never rewrite a comment to change voice or tone. A warning stays a warning.
- If a new comment needs more than about three lines, the code is probably wrong. Fix the code, not the comment.
