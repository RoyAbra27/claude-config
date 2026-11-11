# claude-config

My Claude Code setup (`~/.claude`): global rules, custom skills and agents, and the hooks that enforce them. On Windows 11 a new machine is set up with one clone, one login and one script.

It's built for backend work (NestJS/TypeScript, Python, infra), but most of it isn't tied to a stack.

## The idea: rules that ratchet

Most Claude setups pile rules up in `CLAUDE.md` until the model starts ignoring them. This one gives every correction a path to a stronger layer:

```
in-chat correction  ->  CLAUDE.md rule (dated)  ->  hook that blocks it
```

- **Repeated mistakes harden.** On the 3rd correction for the same thing, it gets proposed as a hook in `hooks/guard.sh`. Hooks run before permission checks, so they hold in any mode.
- **Rules carry dates.** On review, rules that a hook now enforces get deleted, so `CLAUDE.md` stays short.
- **A router decides which skill fires.** `hooks/skill-router.md` maps situations to skills and agents. It's injected at every session start, so routing doesn't rely on the model remembering skill descriptions.
- **Subagent output is a hypothesis.** Agents return fixed-field findings (`{claim, file:line, evidence, confidence}`), and the main thread verifies the evidence before acting on it. A `builder` agent's work is accepted only after the main thread reruns the brief's `Done when:` check itself.
- **You talk to one coordinator.** When subagents do the work, the main session doesn't narrate them. It interrupts only for a decision only you can make, logs its own judgment calls, and ends with one report in attention order: decisions, then failures, then finished PRs. Plans meant for delegation answer every owner decision up front, so the run doesn't stall midway.
- **Sessions end with a reflection.** `/reflect` reviews the session's corrections and failed attempts and proposes the smallest fix at the right layer: a skill line, a memory entry, a CLAUDE.md rule or a hook. Nothing gets applied until you approve it.

## How a task flows

The router picks these automatically. You mostly answer questions and read one report at the end.

1. **Idea to spec:** `superpowers:brainstorming` asks the questions, and `consult` argues both sides of any expensive fork.
2. **Spec to plan:** the plan opens with the owner decisions you answer up front, and every task lists its files, its dependencies and a `Done when:` command.
3. **Plan review:** `plan-redteam` attacks the plan before anything runs, and `plan-redteam-gate.sh` won't let plan mode exit without that pass.
4. **Execution:** sequential tasks run under `superpowers:subagent-driven-development`, and waves of file-disjoint tasks run through `parallel-ticket-delivery`. The main session acts as the only coordinator and reruns every check itself.
5. **Before merge:** `branch-audit` for big or sensitive branches, `/code-review` for small diffs.
6. **Session end:** `/save-session` writes the state for next time and runs `/reflect`, which turns the session's mistakes into proposed rule or skill fixes.

## What's inside

```
CLAUDE.md          global instructions: debugging protocol, git, verification, subagent dispatch, rtk usage
settings.json      hooks, env, auto-mode allow/deny rules, plugins, status line
hooks/             guard, gates and session context (see below)
skills/            custom skills
agents/            custom subagents
commands/          slash commands: /save-session, /resume-session, /reflect
scripts/install-skills.sh  pick and install the third-party skills (all / none / 1,2,5)
scripts/docread.py document-to-Markdown reader; flags PDF pages with a broken text layer and renders them as image grids
dotfiles/          PowerShell profile + oh-my-posh theme
bootstrap.sh       new-machine setup
```

### Hooks

| Hook | When | What it does |
|---|---|---|
| [`guard.sh`](hooks/guard.sh) | before Edit, Write, Bash | Blocks `rm -rf` (except SDD scratch under `.superpowers/sdd/`), force-push, `reset --hard` and other work-destroying git commands, `DROP`/`TRUNCATE`, bot attribution trailers, secret-shaped strings in commits, edits to secrets files and lockfiles, and em-dashes. Blocks everything if `jq` is missing rather than failing open. Tests: `bash hooks/guard.test.sh` |
| [`plan-redteam-gate.sh`](hooks/plan-redteam-gate.sh) | before ExitPlanMode | Blocks executing a plan until it has had a red-team pass (or an explicit, reasoned opt-out) |
| [`session-context.sh`](hooks/session-context.sh) | session start, resume, compact | Injects working state from the repo itself (branch, uncommitted files, recent commits) plus the skill router, and flags a last session that ended without `/reflect` |
| [`lint-on-save.sh`](hooks/lint-on-save.sh) | after Edit, Write | Runs the project's own prettier and eslint on TS/JS files. Never blocks |

### Commands

| Command | What it does |
|---|---|
| [`/save-session`](commands/save-session.md) | Writes the goal, what's done and verified, what failed, what couldn't run, and what's next to `~/.claude/sessions/`. Updated at each milestone, and runs `/reflect` on the final save |
| [`/resume-session`](commands/resume-session.md) | Reads a saved session file, summarizes it, and confirms the plan before continuing |
| [`/reflect`](commands/reflect.md) | Lists what went wrong this session, with evidence, and proposes the smallest fix at the right layer. Applies only what you approve |

### Skills

| Skill | Use it when |
|---|---|
| [`plan-redteam`](skills/plan-redteam/SKILL.md) | A spec or plan is done. A fresh agent attacks it with evidence, you defend or concede, and you get an agreed change list |
| [`consult`](skills/consult/SKILL.md) | Choosing between options on something expensive or hard to reverse. Two blind agents each argue one side |
| [`branch-audit`](skills/branch-audit/SKILL.md) | A big branch is about to ship. Parallel reviewer lanes (API surface, data path, conformance, deploy, client contract, privacy, omissions) feed one consolidated, verified list. Lane yield is tracked over time so weak lanes get cut |
| [`buy-vs-build`](skills/buy-vs-build/SKILL.md) | You're about to hand-roll a queue, retry, cache, parser, auth or rate limiter. It checks installed deps first, then searches the web |
| [`testing-workflow`](skills/testing-workflow/SKILL.md) | Any behavior change: spec first, a failing repro test before a bug fix |
| [`doc-sync`](skills/doc-sync/SKILL.md) | Behavior changes that have docs, diagrams or env vars attached |
| [`code-comment-policy`](skills/code-comment-policy/SKILL.md) | Writing or reviewing comments. The default is none, and existing ones are treated as load-bearing |
| [`prompt-shake`](skills/prompt-shake/SKILL.md) | After editing a prompt file (CLAUDE.md, a skill, an agent). Tightens it so rules don't only grow |
| [`frontend-flow`](skills/frontend-flow/SKILL.md) | UI work. Chains Impeccable, Hallmark and the Android skills instead of picking one |
| [`parallel-ticket-delivery`](skills/parallel-ticket-delivery/SKILL.md) | Several independent tickets, each shipped as its own PR by a parallel worktree agent. It proves file-disjointness first, writes one shared brief, reruns every agent's check, and reports to you only when a decision is needed |

### Agents

| Agent | Role |
|---|---|
| [`builder`](agents/builder.md) | Implements one scoped change from a brief, runs its check, and reports in a fixed format (status, files, command, exit code, output) |
| [`explore-cheap`](agents/explore-cheap.md) | Low-cost read-only codebase search that returns `file:line` answers, not file dumps |
| [`library-scout`](agents/library-scout.md) | The outward research lane for `buy-vs-build`: verified candidates, never a verdict |
| [`consult-side`](agents/consult-side.md) | Argues one side of a `consult` from a frozen brief |
| [`plan-redteam-lead`](agents/plan-redteam-lead.md) | The skeptical team lead for `plan-redteam` |
| [`nestjs-expert`](agents/nestjs-expert.md) | NestJS modules, DI, guards, interceptors, microservices |
| [`product-dreamer`](agents/product-dreamer.md) | Product-vision research: ranked feature ideas, each with cited evidence, user moment, trust risk, cost and effort, plus patterns to steal and anti-patterns |
| [`hebrew-copywriter`](agents/hebrew-copywriter.md) | Native Israeli Hebrew for any medium (UI, video, decks, marketing, email, social, docs): rewrites translated-sounding drafts, keeps terms consistent, handles gendered address and mixed-direction text |

## Install

On Windows 11 with Git Bash. Install Claude Code but don't start it yet (the first start creates `~/.claude`, and the clone needs that folder not to exist). Then:

```bash
git clone https://github.com/RoyAbra27/claude-config ~/.claude
claude   # log in once, then quit
bash ~/.claude/bootstrap.sh
```

The script installs CLI tools (winget, uv), PowerShell modules, the dotfiles and user-scope MCP servers (Playwright, mobile). Zed is installed as `$EDITOR`; swap it in `settings.json` if you use something else. It then shows a numbered menu of the third-party skills listed below and asks which to install: `all`, `none` or a list like `1,2,5`. To skip the prompt, pass `--skills all|none|1,2,5`. To add skills later, run `bash ~/.claude/scripts/install-skills.sh` (add `--dry-run` to preview). It's safe to rerun: installed items are skipped, overwritten dotfiles get a `.bak-<timestamp>` copy, and anything that fails is listed at the end. Plugins in `settings.json` download on the first `claude` start.

Already have a `~/.claude`? Don't clone over it. Copy the pieces you want instead: `hooks/guard.sh` and its `settings.json` entry work on their own.

On macOS or Linux, skip `bootstrap.sh` and the dotfiles. The hooks are plain bash plus `jq`.

### Make it yours

- `guard.sh` enforces my preferences too: it blocks em-dashes in written files and `Co-Authored-By` trailers in commits. Delete those two checks if you don't share them.
- `plan-redteam-gate.sh` blocks leaving plan mode until the plan has a red-team pass (or a `red-team: skip - <reason>` line). Remove its two entries in `settings.json` if that's too strict for you.
- The router (`hooks/skill-router.md`) names third-party skills. Rows for skills you didn't install simply don't apply.
- `CLAUDE.md` assumes some CLIs: `jq` (required by the hooks), `uv`, `markitdown` and [`rtk`](https://github.com/rtk-ai/rtk) for compact command output (bootstrap installs all of these; `settings.json` sets `RTK_SUPPRESS_HOOK_WARNING=1` because rtk is used manually, without its hook).
- `CLAUDE.md` has an Environment section with Windows-specific rules (PowerShell profile path, Git Bash quirks). Rewrite it for your machine first.
- `settings.json` sets `"defaultMode": "auto"` and my auto-mode allow and deny rules. Review them before you use the setup.
- `bootstrap.sh --capture` copies your live PowerShell profile and oh-my-posh config back into `dotfiles/`.

## Credits

These third-party skills are not included in this repo. `scripts/install-skills.sh` (which `bootstrap.sh` runs) installs the ones you pick from upstream:

| Skill | Upstream | License |
|---|---|---|
| archify | [tt-a1i/archify](https://github.com/tt-a1i/archify) | Apache-2.0 |
| impeccable (+ its agents) | [pbakaus/impeccable](https://github.com/pbakaus/impeccable) | Apache-2.0 |
| hallmark | [Nutlope/hallmark](https://github.com/Nutlope/hallmark) | MIT |
| security-audit | [cloudflare/security-audit-skill](https://github.com/cloudflare/security-audit-skill) | MIT |
| codebase-design, improve-codebase-architecture, to-tickets, wizard | [mattpocock/skills](https://github.com/mattpocock/skills) | MIT |
| android-material3-design-system, android-viewsystem-foundations | [krutikJain/android-agent-skills](https://github.com/krutikJain/android-agent-skills) | MIT |
| developing-with-streamlit | [streamlit/agent-skills](https://github.com/streamlit/agent-skills) (archived, now ships with Streamlit) | Apache-2.0 |

Plugins: [superpowers](https://github.com/obra/superpowers), [ponytail](https://github.com/DietrichGebert/ponytail), [claude-hud](https://github.com/jarrodwatts/claude-hud), [hyperframes](https://github.com/heygen-com/hyperframes) and the official Claude plugins. The git guardrails in `guard.sh` and some of the testing ideas are adapted from mattpocock/skills.

## License

MIT for everything in this repo. Third-party skills keep their own licenses.
