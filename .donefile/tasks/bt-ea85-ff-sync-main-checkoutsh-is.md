---
id: bt-ea85
title: ff-sync-main-checkout.sh is hand-copied into 8 repos and already differs in length, with
  nothing asserting the copies agree
status: open
priority: p3
tags:
  - debt
  - tooling
  - cross-board
created: 2026-08-31
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
