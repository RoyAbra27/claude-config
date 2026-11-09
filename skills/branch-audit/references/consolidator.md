# Consolidator prompt

Dispatch on Opus, background, after every lane has returned.

"You consolidate a multi-lane code audit. Repo <path>, branch <branch> at HEAD <sha>. Read <brief path> for context and hard rules (read-only; no state-resetting tests; no subagents; no secrets or real data). Then read every lane file: <list>. Binding user rulings: <where>.

Write ONE file `<workspace>/audit-merged.md` with:

1. `## Merged findings`: one block per distinct issue, duplicates across lanes merged. Fields: id M<n>; title; severity (your own after verification; note lane disagreements and why you chose); sources (all lane IDs); verified: yes/no/partial with file:line at HEAD and a short quote; bucket: FIX-CODE | USER-DECISION | FIX-DOCS | DEFER | DROP; proposed_fix (smallest; for FIX-CODE name the test that should fail first); conflicts (items or rulings it interacts with, e.g. one lane's 'delete it' vs another's 'keep it for retry').
   - USER-DECISION only for real tradeoffs: options plus your recommendation in two lines.
   - DROP needs a one-line reason.
   - Re-verify every Critical/Important and every FIX-CODE item yourself at HEAD. Spot-check external claims that would change code (record URLs). Mark what you could not verify.
   - Order by bucket, then severity.
2. `## Fix-wave brief draft`: FIX-CODE + FIX-DOCS grouped into coherent work units (files touched, tests to add), ordered with data-loss paths first, executable by one implementer.
3. `## Lane statistics`: per lane: raw findings, duplicates, unique verified, unique Important+, dropped; plus a 3-line judgement of which lanes earned their cost.

Reply with ONLY: file path, counts per bucket, and USER-DECISION titles (one line each)."
