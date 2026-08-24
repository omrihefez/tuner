---
id: bt-4722
title: Test audit + hygiene pass (measure first, don't assume bloat) — fanned out from meniapp
  ma-65f4/ma-38dd
status: open
priority: p3
tags:
  - tests
created: 2026-08-24
---

Fan-out of the meniapp test audit+hygiene methodology (ma-65f4, meniapp, commit e5d2f114) to this repo.

WHAT TO DO — measure first, don't assume bloat:
1. Run this repo's actual test suite(s) and record real counts/timings (files, test counts, wall-clock) before forming any opinion about "too many tests" or duplication.
2. Look for genuine redundancy — tests asserting the identical invariant twice, not tests that merely look similar. meniapp's own pass found the "too many tests" instinct mostly wrong once measured: only real, small pockets of duplication turned up in app/, and hub's suite (80 files) needed no cuts at all. Expect the same here: report what you actually found, even if that's "less bloat than expected".
3. If suites aren't already split (unit vs. integration/e2e — anything hitting a real port, socket, subprocess, or external binary is integration; everything else is unit), split them and wire up a fast "changed" path if the tooling supports it.
4. Write a short docs/TESTING.md (or equivalent) with rules traced to what THIS pass actually measured in THIS repo — not generic advice. Model: meniapp's hub/docs/TESTING.md and app/docs/TESTING.md (both written 2026-08-24/2026-07-31) — real file names, before/after numbers, an explicit "what this audit deliberately did NOT do" section.
5. Do not lose coverage. A cut test needs a reason stronger than "looks similar".

PROVENANCE: this follow-up was discovered and auto-filed from ma-38dd (meniapp), which itself fans out ma-65f4. ma-65f4 was Omri's actual ask, scoped to meniapp (hub/app/plugin) — "Start with the hub and once it's grounded you can parallelize into the others." Extending it to this repo is a reasonable extrapolation, but it is NOT itself something Omri asked for by name, so it is filed self-generated (no from-omri tag). If Omri confirms he wants this done everywhere, this should be retagged from-omri that day.

DONE WHEN: either (a) the audit is done, suites are appropriately split, a testing-rules doc is written from real measurements, and nothing lost coverage — cite before/after numbers and the doc's path/commit; or (b) the audit was done and concluded no changes were warranted — say so explicitly with the measurements that led there. Either outcome is a valid close; "found less bloat than expected" is a legitimate result, not a failure to find work.
