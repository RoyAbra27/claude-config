---
name: frontend-flow
description: Runs UI work as a chain over the installed design tools instead of picking one - Impeccable for context, critique and finish checks, Hallmark for a full visual reinvention, android-skills plus device screenshots for Android. Use whenever the user wants to redesign, restyle or improve an existing landing page or website, design or review UX/UI for an Android app or screen, or build a new marketing page, even if they name only one tool or just say "make this look better". Not for backend work, charts (dataviz) or architecture diagrams (archify).
---

# Frontend flow

Impeccable and Hallmark each solve part of the job and would compete if both triggered on their own. This skill fixes the order: Impeccable owns context, critique and the final checks; Hallmark is called only for a full reinvention; Android work adds the platform skills and real-device evidence. Each tool keeps its own instructions; this file only decides who runs when and what passes between them.

Paths: Impeccable at `~/.claude/skills/impeccable/SKILL.md`, Hallmark at `~/.claude/skills/hallmark/SKILL.md`. Hallmark is set to user-invoke only, so the Skill tool will refuse it: read its SKILL.md and follow it directly.

## 1. Context first

Invoke `impeccable` and run its setup. If `PRODUCT.md` is missing, run `impeccable init`; if `DESIGN.md` is missing and the project already has UI, run `impeccable document` so the current system is captured from code, not guessed. Do this for every redesign, restyle or new page, even when the request feels scoped: the files are what the next session and Hallmark read, and a redesign without them gets redone from scratch next time. Only a single-component tweak may skip it; then offer it at the end.

## Scope is what the user sees

The target is the whole visible screen, not the file that was named: on Android that includes the activity's app bar, header icons and bottom navigation around a fragment; on the web, the header and footer around a page section. Critique all of it. If the user limits scope to one region, say which visible parts stay untouched and that they will set the ceiling of the result. A redesign inside an unchanged frame reads as "barely changed" however good the inner work is.

## 2. Critique the current state

Run `impeccable critique <target>` (and `audit <target>` for a11y, performance, responsive). Show the user the findings, then ask one question: **refine or reinvent?**

- **Refine** keeps the identity: logo, colors, typefaces, copy and the page structure. It fixes what the critique found (contrast, hierarchy, spacing, states, responsiveness) inside that identity. This is the default for an existing product with a working brand. A user who says "keep our logo and colors" has not invited a font or layout swap; propose those as options instead of applying them.
- **Reinvent** replaces the visual world (palette, type, layout) while keeping content and wiring: copy stays word for word, links, forms and field names stay intact. Choose it only when the critique says the look itself is the problem or the user asks for a new direction.

In both paths, copy edits (buzzword cleanup, rewritten headlines) are suggestions listed at the end, not changes, unless the user asked for new copy.

Default to designing on Impeccable's decision page: every reinvent, redesign or new screen goes through it, and a refine that has two or more real options (layout, hierarchy, a component's form) offers it too. Do not compress Impeccable's decision steps into a chat question when a human is present: run its visual decision page (`serve-question`) with sketches or comps so the user picks from pictures, and run its finish review before calling the work done. Those two steps are what lift the result above "fine but generic"; skipping them tends to produce a timid result.

## 3a. Refine path (Impeccable only)

Use the commands the critique points to (`layout`, `typeset`, `colorize`, `clarify`, `harden`, `adapt`, ...), one at a time, then `polish`.

## 3b. Reinvent path (Hallmark)

Read Hallmark's SKILL.md and run its `redesign <target>` flow. Hallmark treats a root `DESIGN.md` as a locked system and will stay inside it. If the user wants a new look, say so and ask before renaming `DESIGN.md` (e.g. to `DESIGN.previous.md`); if they want the brand kept, leave it, and Hallmark will restructure within it.

Do not run `scripts/install-hook.mjs`: it rewrites `settings.json`. Hallmark's image generation calls the Together API and only runs when `TOGETHER_API_KEY` is set; mention that before using it.

## 4. Finish checks (both paths)

Run `impeccable audit <target>` on the result and fix what it flags, then `polish`. On the mobile screenshot (390px), look specifically at the side gutters: text and cards should sit at least 16px from both edges, because full-bleed layouts that look intentional at 1440px often end up touching the screen edge on a phone. Capture each viewport from a fresh load at that size: set the viewport first, then navigate with a new query string (a hash-only change does not reload), scroll to the top, and take a viewport-sized screenshot (make the viewport tall for a whole tab) rather than a full-page one, which stacks sticky bars over the content (added 2026-11-10). Before saying done, show evidence: screenshots at mobile and desktop width plus the audit outcome, per superpowers:verification-before-completion.

## Android path

Hallmark is web-only, so on Android the reinvent answer from step 2 runs Impeccable's new-work flow instead: one screen inside the app's established world is "a whole surface inside an established world" (`concept-seed --scope surface --mode operate`), which re-plans the screen's structure and keeps the app's palette, icons and fonts. Replacing the whole app's visual world is a separate, app-wide decision.

Replace steps 3-4 with:

1. `impeccable critique` and `audit` on the screen, which load Impeccable's Android and native references (Material 3 structure, system Back, edge-to-edge).
2. Implement in the screen's existing UI system. An XML Views screen (a Fragment with `res/layout/*.xml`) is refined in XML; migrating it to Compose is a separate decision to offer, never a side effect of a UX pass. For Compose screens, or when the user chooses migration, use the matching skill from the `android-skills` plugin: `adaptive` (layouts across sizes), `migrate-xml-views-to-jetpack-compose`, `jetpack-compose-performance`, `navigation-3`, `testing-setup`. They appear in the skill list only where the plugin is enabled; if they are missing, tell the user to enable `android-skills@android-skills` for this project and continue with Impeccable's `android.md` guidance.
3. Verify on a device or emulator with the mobile MCP: build, launch, `mobile_list_elements_on_screen` for structure and a screenshot for the visual result, and compare against the critique findings.
4. Run the project's unit and UI tests (`./gradlew testDebugUnitTest`, plus instrumented tests if the screen has them) per testing-workflow.

## New page from nothing

Steps 1 and 4 still apply. For step 3 the user picks: `impeccable` new-work for a page that must sit inside an existing product family, `/hallmark <prompt>` for a standalone marketing page that needs its own look.

When the request names a form (dashboard, data room, deck, report), that form is pinned for both impeccable's mode and the structure round; a free roll turned a dashboard into a story page (added 2026-11-10).

Run `impeccable concept-seed` once with its output redirected to a file, then read the file: every run deals a new hand, so a second run to see truncated output silently changes the roll (added 2026-11-10).
