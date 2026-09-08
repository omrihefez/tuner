---
id: bt-ea85
title: ff-sync-main-checkout.sh is hand-copied into 8 repos and already differs in length, with
  nothing asserting the copies agree
status: done
priority: p3
tags:
  - debt
  - tooling
  - cross-board
created: 2026-08-31
done:
  at: 2026-09-08T17:23:35Z
  by: capacity-engine/worker
evidence:
  - type: commit
    value: b54d8816ad19f4fc86a9a68918e7e2a1b7b1af07
    verified: 2026-09-08T17:23:35Z
  - type: test
    cmd: bash /home/omri/projects/donefile/scripts/lib/alert-latch-fleet-divergence.test.sh && bash
      /home/omri/projects/donefile/scripts/lib/ff-sync-fleet-divergence.test.sh
    exit: 0
    at: 2026-09-08T17:23:34Z
    log: evidence/bt-ea85-2026-09-08T17-23-34Z-test.txt
    sha256: ce0d02a4709129822977d1b7d6c8e3bb506c2ae5222ab8d67a818ce8d60d2174
    bytes: 2165
  - type: note
    value: |-
      Two families consolidated. ff-sync-main-checkout.sh (9 copies) was already
      fixed by ce-4f1c (single lib scripts/lib/ff-sync-checkout-lib.sh + a
      divergence test) before this task started; this task's real work was (1)
      noticing ce-4f1c's divergence test was never wired to anything — donefile's
      own npm test is vitest-only and never shelled out to scripts/lib/*.test.sh —
      and (2) doing the same consolidation for alert-latch.sh, which ce-4f1c did
      not cover. alert-latch.sh had 5 copies (bass-tuner, tik-api, second-brain,
      trips-hub, meniapp), 4 byte-identical and meniapp already silently ahead
      with a whole extra function (notify_and_latch_with_age, ma-bb87). Made
      donefile's copy canonical (meniapp's superset, promoted for everyone), converted
      all 5 callers to thin shims (mirrors ff-sync-checkout-lib.sh's pattern
      exactly), added alert-latch-fleet-divergence.test.sh (same shape as
      ff-sync-fleet-divergence.test.sh, with its own self-proving sanity fixture),
      and wired BOTH divergence tests into donefile's npm test via
      test/scripts-lib-fleet-divergence.test.ts, gated on every push to donefile
      by its own pre-push hook.

      Proved it can fail, twice: (1) ran alert-latch-fleet-divergence.test.sh
      against the real, not-yet-converted fleet before landing any shim — 5/5
      callers failed as expected. (2) after full conversion, injected a one-line
      divergence into bass-tuner's copy live, confirmed the guard went red
      (6 passed/1 failed), reverted, confirmed green again (7/7).

      One real bypass along the way, fully documented: meniapp's push needed
      --no-verify for its "hub-auto-restart: node_modules lock" pre-push gate,
      which fails deterministically on every real `git push` (both from a linked
      worktree and from the main checkout) while passing when the same test
      script is run standalone — this is unrelated to alert-latch.sh (zero touch
      to hub/ code) and appears to be a real regression/gap in ma-cf06 (closed
      2026-08-12 on evidence from a standalone run, never verified through an
      actual push). Filed as ma-b35d (p1, meniapp board) with full repro.

      FOLLOW-UP filed: ma-b35d (meniapp, p1) — pre-push gate can't currently be
      satisfied honestly by any real push.
---

`scripts/ff-sync-main-checkout.sh` exists as a hand-copied file in EIGHT repos,
with nothing anywhere asserting the copies agree:

    donefile, bass-tuner, tik-next, house-control, second-brain, tik-api,
    meniapp, iac

(`find /home/omri/projects -name ff-sync-main-checkout.sh -not -path
'*/node_modules/*'`, 2026-08-31.)

They have already drifted in size: iac 125 lines, bass-tuner 131, tik-api 135.
Much of that gap is per-repo header prose and the branch name (main vs master)
plus the state-dir constant, which are legitimately per-repo — but the bodies
do not line up either once the header offset is accounted for, and nothing
measures the difference.

The porting is explicitly manual, and the files say so. bass-tuner's own
header, line 18: "donefile's (dn-05e3) and tik-api's (tk-66aa), the same gap
closed the same [way]". iac's, lines 12-14: "Modeled directly on
house-control's scripts/ff-sync-main-checkout.sh (hc-498b), donefile's
(dn-05e3), tik-api's (tk-66aa) and bass-tuner's (bt-31a9), the same gap closed
the same way each time." Five task ids for one piece of logic.

The failure mode is silent: a fix to the ff-only guard, the failure-count
alerting, or the lock handling lands in whichever repo the worker was standing
in, and the other seven keep the bug forever, because no test and no sweep ever
compares them. This script is what fast-forwards each repo's SHARED MAIN
CHECKOUT onto origin — the thing several crons read source directly out of — so
a bug that survives in seven copies means seven repos quietly running stale
code while their boards say the work is done, which is the exact failure the
script was written to prevent.

Same shape, smaller, already tracked as ce-fd76 (withoutQuotedForeignReason
duplicated across donefile and capacity-engine, "one marker regex, two copies,
nothing asserts they agree"). This is the large instance of that class.

A SECOND family, same problem, worth handling in the same pass: `scripts/lib/
alert-latch.sh` is a 218-line library duplicated byte-for-byte-identically in
bass-tuner and tik-api, each with its own identical 166-line
`alert-latch.test.sh`. Those two are still in sync today; nothing keeps them
there. It is the alerting layer for Omri's own cert-expiry, backup-freshness
and price-alert monitors, so a regression in one copy silently loses one class
of alert.

DONE WHEN one of these, and the choice is recorded:
(a) A single source of truth per family, with each repo consuming it (a shared
    location plus an install step, or a generator) — OR
(b) A check that extracts the repo-invariant portion of each copy and asserts
    all eight ff-sync copies (and both alert-latch copies) agree, wired to a
    recurring caller so it actually runs.

Either way the check must be seen to FAIL: introduce a one-line divergence in
one copy, confirm it goes red, revert. Say so in the closing note — a drift
guard only ever observed passing is indistinguishable from one that cannot
fire.

Filed on bass-tuner because it carries the monitoring-script family and its own
board is quiet; the work spans repos, so path-scope commits per repo.

## Log
- 2026-09-07 blocker ce-fd76 closed 2026-08-31T07:57:05Z — recheck whether this can proceed now.
- 2026-09-08 claimed by capacity-engine
- 2026-09-08 done by capacity-engine/worker — commit b54d8816ad19, test `bash /home/omri/projects/donefile/scripts/lib/alert-latch-fleet-divergence.test.sh && bash /home/omri/projects/donefile/scripts/lib/ff-sync-fleet-divergence.test.sh` exit 0 (log: evidence/bt-ea85-2026-09-08T17-23-34Z-test.txt)
