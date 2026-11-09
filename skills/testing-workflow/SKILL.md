---
name: testing-workflow
description: The user's testing requirements and workflow - TDD, bug-repro-test-first, parameterized tests, and reusing project fixtures. Use whenever writing or modifying tests, adding a feature or service, or fixing a bug (any behavior change). Triggers - writing tests, spec files, TDD, bug fix, "add a test", jest, pytest, red-green-refactor. Complements superpowers:test-driven-development with these project-specific rules.
---

# Testing Workflow

- **Every code change needs tests** - new services/features get a spec file written first (TDD red-green-refactor). No new behavior gets merged without a corresponding test.
- **Bug fixes**: add a test that reproduces the bug BEFORE fixing it, then verify the fix makes it pass.
- **Modified behavior**: update existing tests in the same change. If a method changes what it returns or throws, the tests MUST be updated alongside it.
- Read the source file fully before writing tests.
- Use existing test utilities/fixtures from the project (e.g. `test-utils.ts`) - never recreate mocks locally.
- Use parameterized tests (`it.each` / `parametrize`) over copy-paste test blocks.
- Expected values come from an independent source (a literal, a spec, a hand-worked example), never recomputed the way the code computes them; a test that mirrors the implementation passes when both are wrong.
- Build in vertical slices: one test plus the code that passes it end to end, then the next. Do not write all tests for a layer before any implementation.
- Run the relevant test file after writing - verify it passes locally before claiming done.
