# Global Claude Code Instructions

## File Reading (token efficiency)
- For binary/rich docs (PDF, docx, pptx, xlsx, images, audio, HTML, EPub), convert with the globally-installed `markitdown` CLI before reading, to save tokens: `markitdown file.pdf -o out.md`, then read `out.md`. Skip it for plain text/code - read those directly.
- **PDFs (added 2026-11-09):** use `uv run --script ~/.claude/scripts/docread.py file.pdf --out <scratch dir>` instead of bare markitdown; read the image grids it lists. Add `--tables` (Docling, slow) when exact tables matter.

## Debugging (CRITICAL)
- **Scale by risk (revised 2026-11-11):** a local bug on the first attempt gets repro, fix, rerun the repro. The full protocol (approval before editing, hypothesis ledger) starts after one failed fix attempt, or up front for production or data-loss bugs
- Full protocol: propose the diagnosis + fix plan for my approval BEFORE editing code
- **Repro gate (added 2026-11-09):** before hypothesizing, name one command (test, script, curl) you have already run that reproduces my exact symptom and can go green once fixed. No such command yet = building it is the first task
- **Hypothesis ledger (added 2026-09-01, ranked 2026-11-09):** write 3-5 ranked hypotheses, each with the prediction that would falsify it, and show them to me before testing. Keep them as a `tested_hypotheses` list (hypothesis, evidence, verdict) in the session file (`~/.claude/sessions/`), updated after each attempt; check it before proposing the next attempt and never re-test a ruled-out hypothesis
- **Bound the loop:** after 2 failed attempts at the same symptom, stop. Report the diagnosis and what you ruled out. A third variation is not a fix
- **Temporary probes (added 2026-09-02):** tag every temporary log/probe with `DEBUG_MODE:` in its comment so cleanup is one grep; none may reach a commit. Undo a temporary edit by restoring a backup copy or reversing that exact edit, never `git checkout -- <file>` on a file with uncommitted work (added 2026-11-10)

## Environment (CRITICAL - prevents wrong assumptions)
- PowerShell profile is the path `$PROFILE` reports (~/Documents/PowerShell/Microsoft.PowerShell_profile.ps1), not the stale OneDrive copy; oh-my-posh config is ~/.oh-my-posh/clean-detailed.omp.json
- When running PowerShell commands from bash, use absolute Windows paths (C:\Users\USER\...) not $HOME
- Any `!` command suggested to the user uses absolute paths: the session cwd moves between repos and worktrees (added 2026-11-11)
- **Git Bash path rewriting (added 2026-10-29):** an argument starting with `/` that is not a file path (URL path, health-check path, route) gets rewritten to `C:/Program Files/Git/...`; prefix that command with `MSYS_NO_PATHCONV=1`. Never set it globally: it breaks `/c/...` paths passed to Windows programs
- Run repo shell scripts with the Bash tool, never `bash` inside PowerShell: there it resolves to the WSL launcher (added 2026-10-29)
- Before re-running a stopped test or smoke suite, kill leftover `node`/`python` children (`taskkill //F //T //PID <pid>`); results from a run that overlapped stale processes are invalid (added 2026-10-29)
- Git Bash heredocs break on Hebrew text ("unexpected EOF") and mangle backslash escapes (a regex `\b` or `\1` becomes a control character): write any script with Hebrew, regex or backslashes to a file with the Write tool and run the file (added 2026-11-10)

## Git Workflow
- Use conventional commits (feat:, fix:, refactor:, docs:, test:, chore:)
- Commit in well-scoped logical commits at milestones (commit progress first if context is getting large), and run `git status` so nothing is left uncommitted when the session ends
- Never add `Co-Authored-By` trailers to commits: this overrides the harness default, and guard.sh blocks them

## Communication Style
- Number multi-step tasks so they're easy to follow
- End responses with one concrete next step (when there is one; skip if the task is fully done)
- No em-dashes in any file you write or edit (guard.sh blocks them); use a hyphen. Chat is exempt
- **Always push back when you believe I'm not 100% right, timed by cost (split 2026-10-29).** An explicit, cheap, reversible request: do it, then state the concern in one line. Anything expensive or irreversible, or codifying my preference into rules/config/files: state your position and the evidence (2-4 lines) BEFORE acting; let me decide with the tradeoff visible. If I overrule after hearing the tradeoff, proceed without re-arguing

## Coding Conventions
- **Ask or proceed (revised 2026-11-11):** ask only when the interpretation changes what gets built. Otherwise pick one, name the choice in one line, and continue; never pick silently. On long runs, keep going while a step doesn't need me and put status notes next to the next action. This rule wins over plugin defaults that say "always ask first" or "never stall"
- Prefer current docs and versions; check release dates instead of trusting memory

## Build for the User, Not the Demo
- Before building any user-facing feature/tool, state the user's loop in 1-3 lines: who, when, what they decide with it. Design backwards from that.
- Every derived number, score, or chart must have a one-line "this tells the user X, so they do Y". Can't write it? Cut it.
- State the realistic scale (N x frequency) and what breaks first, even if you don't build for it. For a new call to an outside service on a page load, name its latency and check whether the server already holds the data, before it goes into a brief (added 2026-11-10)
- No two views/endpoints showing overlapping data; merge or delete.

## Verification
- For multi-step tasks, state a brief plan with verifiable success criteria for each step before starting
- Never pipe a test command (`| tail`, `| head`, `| grep`) in a chain that commits: run it alone and check its exit code (added 2026-10-29)
- **Blocked steps (added 2026-10-29):** do every step the guard hook or auto mode allows first, then give the blocked ones (push, deletes, DROP, bucket locks, hook edits) as one numbered `!` block at the end, with preconditions. Never chain a blockable command onto other work

## Ratchet (added 2026-09-01)
- Every repeated correction becomes permanent infrastructure, fixed at the strongest layer available: in-chat correction < CLAUDE.md rule < hook/linter that blocks it (~/.claude/hooks/guard.sh). If I correct the same mistake a 3rd time, propose the hook conversion - the 4th time should never happen
- New rules added to this file get a date (YYYY-MM-DD). On review, delete rules a hook now enforces and reconcile contradictions (added 2026-09-02)

## Routing (added 2026-09-02)
- Which skill or agent fires for which situation lives in `~/.claude/hooks/skill-router.md`, injected at every session start by `session-context.sh`. When adding or renaming a skill or agent, update that table in the same change.

## What NOT to Do
- Don't create README or documentation files unless asked
- Never bare `pip install`: in a uv project (`pyproject.toml` + `uv.lock`) use `uv add`; `uv pip install` only where there is no lockfile (added 2026-10-26)

## Session Management
- Use /save-session at milestones and before ending to preserve progress for next time (live-state rule: update the session file merge-style at each milestone, not only at the end)

## RTK - prefix high-output commands only
`rtk <cmd>` filters noisy CLI output; unknown commands pass through unchanged. Use it ONLY where output is genuinely large:
- `rtk tsc ...` / `rtk lint ...` - errors grouped by file
- `rtk npx jest ...` / `rtk npm run <script>` / `rtk test <cmd>` - failures only
- `rtk prisma ...` - strips ASCII art
- `rtk git diff|show|log` and `rtk gh pr view|diff|checks`, `rtk gh run view|list` - compact diffs/PR views
- `rtk docker logs <c>` / `rtk log <file>` - deduplicated logs
- `rtk err <cmd>` - errors only from any command

Skip it for `git status/add/commit/push/pull` (savings are noise), never use `rtk grep/read/ls/find` (Grep/Read/Glob are already compact), and never run `rtk init -g` (its hook rewrites every Bash command).
