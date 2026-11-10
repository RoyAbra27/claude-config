# Lane history

One block per audit. Cut or merge a lane with no unique Important+ across three audits.

Entries use project codenames and finding classes only: never product names, branch names, SHAs, ticket IDs or bug specifics.

Codenames: **Project A** = API + worker backend with a data-ingestion pipeline; **Project A client** = its Android app; **Project B** = TS/Hono web app with Docker.

## 2026-10-27 Project A, feature branch (41 commits; 11 lanes, pre-skill layout)

123 raw findings -> 60 merged, 13 Important, 0 Critical.

| Lane (old) | Raw | Duplicates | Unique verified | Unique Important+ | Maps to |
|---|---|---|---|---|---|
| security | 10 | 7 | 1 | 0 | api-surface |
| api | 11 | 6 | 5 | 0 | api-surface |
| pipeline | 9 | 7 | 2 | 0 | data-path |
| db | 12 | 7 | 5 | 0 | data-path |
| arch | 11 | 8 | 3 | 0 | conformance |
| docs | 17 | 9 | 8 | 0 | conformance + client-contract |
| ponytail | 14 | 4 | 10 | 0 | section in code lanes |
| deploy | 10 | 3 | 7 | 2 | deploy |
| mobile | 13 | 1 | 12 | 2 | client-contract |
| privacy | 9 | 3 | 6 | 1 | privacy |
| omissions | 7 | 1 | 6 | 1 | omissions |

Most duplicated: a hardening decision not yet implemented (3+ lanes), a missing storage bucket silently reading as empty (5 lanes), a credential-revocation gap (6 lanes). All three were already known open items, hence the known-open list in the brief.

## 2026-10-28 Project A, whole repo (post-merge, 8 lanes, skill layout + data-path split into uploads/core)

57 raw findings -> 50 merged, 6 Important + 3 Important decisions, 0 Critical.

| Lane | Raw | Duplicates | Unique verified | Unique Important+ |
|---|---|---|---|---|
| api-surface | 4 | 0 | 3 | 0 |
| data-path-uploads | 7 | 2 | 4 | 1 |
| data-path-core | 6 | 0 | 6 | 0 |
| conformance | 11 | 3 | 8 | 0 |
| deploy | 4 | 3 | 0 | 0 |
| client-contract | 10 | 1 | 9 | 3 |
| privacy | 6 | 1 | 5 | 1 |
| omissions | 9 | 1 | 7 | 1 |

Notes: known-open list worked (no lane re-reported a known item as new). A lock-vs-temp-file-write race was found by 3 lanes (top dup). api-surface and deploy 0 unique Important+ on a second pass over an already-audited surface: first strike for each. data-path-core (never-audited code) found only Minors.

## 2026-10-29 Project A, 10 commits (parser and ingestion changes; already red-teamed and code-reviewed)
| Lane | Raw | Duplicates | Unique verified | Unique Important+ |
|---|---|---|---|---|
| data-path | 5 | 1 | 4 | 0 |
| conformance | 5 | 1 | 4 | 0 |
| privacy | 8 (4 + 4 test gaps) | 0 | 8 | 0 |
| omissions | 10 | 0 | 10 | 0 |

Notes: 0 Important+ in every lane; the branch had already had a red team and a code review. Omissions found the only data-loss path (a revoked third-party account read as "no data" instead of an error) and both user decisions. Conformance: low yield on a small, plan-driven branch (a checklist pass by the controller would do). Strikes on zero unique Important+: data-path 1, conformance 1, privacy 1, omissions 1 (count toward the three-audit cut rule). Lesson: on a branch already red-teamed and code-reviewed, 2 lanes (omissions + privacy) may be enough.

## 2026-11-02 Project A, 21 commits (parser v2, views, docs, client guide section; already red-teamed and code-reviewed; user chose all 7 lanes)
| Lane | Raw | Duplicates | Unique verified | Unique Important+ |
|---|---|---|---|---|
| data-path | 5 | 1 | 4 | 0 |
| conformance | 7 | 2 | 6 | 0 |
| client-contract | 9 | 3 | 9 | 2 |
| privacy | 1 | 0 | 1 | 0 |
| api-surface | 4 | 2 | 2 | 0 |
| deploy | 7 | 2 | 6 | 1 (shared) |
| omissions | 6 | 1 | 6 | 1 (shared) |

Notes: client-contract earned most (traced the client code path for a quarantine bug and found a client-side upload queue wipe). A missing old-version signal was found by both omissions and deploy. data-path rated the quarantine bug Minor; the client-contract lane's code trace made it Important. Strikes on zero unique Important+: data-path 2, conformance 2, privacy 2, api-surface 2 (api-surface: range did not touch the API). Lesson: when the range reads another team's code, client-contract is the top lane; on an already-reviewed range, api-surface and privacy mostly return negative evidence.

## 2026-11-03 Project B, phase branch (real store carts, Docker; 6 lanes + controller items)
| Lane | Raw | Duplicates | Unique verified | Unique Important+ | Dropped |
|---|---|---|---|---|---|
| data-path | 6 | 1 | 5 | 2 (incl. the only Critical) | 0 |
| omissions | 12 | 2 | 10 | 3 | 1 |
| conformance | 11 | 2 | 9 | 2 (+1 shared) | 1 |
| api-surface | 6 | 1 | 5 | 1 | 1 |
| deploy | 8 | 5 | 3 | 0 (1 shared with conformance) | 2 |
| privacy | 6 | 3 | 4 | 0 | 2 |
Note: privacy (0 unique Important+, headline fix ineffective) and deploy (mostly duplicated conformance) were the low-yield lanes this run; consider folding privacy into deploy for single-household apps.

## 2026-11-05 Project A client, auto-upload PR (Android client, 18 commits, +4.5k)
Lanes: data-path, conformance, deploy, client-contract, privacy, omissions (api-surface skipped: client only). 36 raw -> 28 merged (13 FIX-CODE, 3 USER-DECISION, 5 FIX-DOCS, 7 DEFER, 0 DROP). Only Important: omissions (a "delete all" action that missed not-yet-processed local data).
| Lane | Raw | Dup | Unique verified | Unique Important+ |
|---|---|---|---|---|
| data-path | 6 | 3 | 3 | 0 |
| conformance | 7 | 3 | 4 | 0 |
| deploy | 6 | 2 | 4 | 0 |
| client-contract | 4 | 2 | 2 | 0 |
| privacy | 4 | 1 | 3 | 0 |
| omissions | 9 | 4 | 5 | 1 |
Notes: branch already had a final review + fix wave, so code lanes found Minors only. Privacy and omissions cited package.diff line numbers instead of worktree lines; tell lanes to cite worktree lines.

## 2026-11-10 Project B web UI, summary verdict branch (web UI + bot text + deploy docs, 33 commits)
Lanes (lean, user choice): conformance, data-path (adapted to the trust path from stored data to every displayed number), omissions. 27 raw -> 21 unique (8 FIX-CODE, 4 USER-DECISION, 10 FIX-DOCS, 3 DEFER, 2 DROP).
| Lane | Raw | Dup | Unique verified | Unique Important+ |
|---|---|---|---|---|
| conformance | 9 | 3 | 6 | 0 |
| data-path | 9 | 3 | 6 | 2 |
| omissions | 9 | 0 | 9 | 0 |
Notes: a read-only probe script in the data-path lane found two invented-number paths the per-task reviews missed; for display-of-numbers branches, tell data-path to probe every figure shown. Omissions caught a deploy runbook that fails when followed literally.
