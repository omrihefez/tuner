---
id: bt-7727
title: alert-latch shim and its test shim resolve donefile by absolute path with no CI fallback —
  the only consumer of five without one, and npm test runs it on ubuntu-latest
status: open
priority: p2
tags:
  - reliability
  - ci
  - cross-board
created: 2026-10-14
filed:
  owner: meni-worker/board-refill-work-discov-fed83a
  at: 2026-10-14T03:56:37Z
---

This repo's `scripts/lib/alert-latch.sh` shim resolves donefile's canonical by
ABSOLUTE path and has no fallback if that path is absent. Measured
2026-10-14, the whole resolution (lines 17-23):

    _ALERT_LATCH_SELF="${BASH_SOURCE[0]}"
    ALERT_LATCH_LIB="${ALERT_LATCH_LIB:-/home/omri/projects/donefile/scripts/lib/alert-latch.sh}"
    if [ "$(readlink -f "$ALERT_LATCH_LIB" 2>/dev/null || echo "$ALERT_LATCH_LIB")" \
       = "$(readlink -f "$_ALERT_LATCH_SELF" 2>/dev/null || echo "$_ALERT_LATCH_SELF")" ]; then
      ALERT_LATCH_LIB="/home/omri/projects/donefile/scripts/lib/alert-latch.sh"
    fi
    source "$ALERT_LATCH_LIB"

There is no `[ -f ... ] ||` line and this repo has no
`scripts/lib/alert-latch.vendored.sh` at all. `/home/omri/projects` does not
exist on a hosted GitHub runner, so there the `source` fails and
`notify_and_latch` / `notify_now` / `notify_and_latch_with_age` are undefined.

THIS REPO IS THE ONLY CONSUMER WITHOUT THE FALLBACK. All four others carry the
identical guard line, confirmed by grep:

    meniapp/scripts/lib/alert-latch.sh:46        [ -f "$_ALERT_LATCH_DEFAULT" ] || _ALERT_LATCH_DEFAULT="$(dirname "${BASH_SOURCE[0]}")/alert-latch.vendored.sh"
    meni-arch/scripts/lib/alert-latch.sh:41      (same)
    trips-hub/scripts/lib/alert-latch.sh:28      (same)
    house-control/scripts/lib/alert-latch.sh:27  (same)

and each of those four ships the `alert-latch.vendored.sh` it falls back to.
This repo's own OTHER two cross-repo shims have it too — `crontab-install-lock.sh`
and `stale-checkout-guard.sh` both sit in the same directory, both carry a
vendored pin, and both resolve it the documented way. So alert-latch is the
single odd one out, in a directory where the convention is otherwise unbroken.

THE TEST SHIM IS WORSE: `scripts/lib/alert-latch.test.sh` is four lines and
ends `exec bash "$ALERT_LATCH_TEST"` where that variable defaults to
`/home/omri/projects/donefile/scripts/lib/alert-latch.test.sh`, with no
existence check and no skip. `exec bash <missing-file>` exits 127.

THAT PATH IS REACHED BY CI, not only by a local run:

  - `package.json`'s `test` script ends
    `for f in scripts/*.test.sh scripts/lib/*.test.sh; do echo "-- $f --"; bash "$f" || exit 1; done`
    — the `scripts/lib/*.test.sh` glob was added deliberately under bt-4722,
    whose own comment says alert-latch.test.sh "lives under scripts/lib/ and
    the old glob never matched it, so it silently never ran here or in CI".
  - `.github/workflows/ci.yml`'s only test step is `run: npm test`, on
    `runs-on: ubuntu-latest` — a HOSTED runner, not the self-hosted one
    ma-efb1 introduced for meniapp/capacity-engine.

So `npm test` on CI should be hitting a 127 and failing the job on every code
push. UNVERIFIED, and stated as such deliberately: a discovery worker's
allowlist has no `gh`, so I could not read a single workflow run and I am NOT
asserting CI is currently red. What is verified is only what is above — the
shim contents, the package.json glob, and the workflow's runner and step.
Whoever picks this up should read the actual run history FIRST, because the
answer changes the task: a red job for weeks is a different finding from a job
that happens never to have been triggered.

Worth knowing either way: bt-4722 closed on `npm test` exit 0, which was run
on Omri's own box where `/home/omri/projects/donefile/...` exists. That is the
standing trap, not a criticism of that task — a local green here cannot say
anything about the one environment this code path exists for.

NOTHING WOULD HAVE CAUGHT THIS. meniapp has two complementary guards and a
missing pin falls between them. `check-vendored-pin-drift.sh` (ma-2aba)
discovers pins with `find "$PROJECTS_DIR" -name '*.vendored.sh'` and compares
each one it FINDS against its canonical — a consumer with no pin is not found,
so it is not an offender. `check-vendored-guard-drift.sh` (ma-c616) checks the
opposite shape, that a private copy has NOT reappeared where a shared
implementation should be used. Neither asks the question "does every shim that
resolves a canonical by absolute path have a fallback for when it is absent?"

DONE WHEN, in this order:

1. The actual CI run history for this repo is read and recorded on this task —
   failing, or never triggered. One sentence, with a run URL.
2. Both shims resolve safely when the canonical path is absent:
   `scripts/lib/alert-latch.sh` gains the same `[ -f ... ] ||` fallback its
   four siblings have, plus a `scripts/lib/alert-latch.vendored.sh` pin taken
   from the canonical WITH a vendoring header (see any existing one for the
   format — note that the bare `cp` those headers document drops the header
   itself, so splice rather than copy); and
   `scripts/lib/alert-latch.test.sh` either falls back the same way or SKIPS
   cleanly with exit 0 and a printed reason when the shared suite is absent,
   rather than exiting 127.
3. Proven the way this repo already proves its other guards — a hermetic test
   under `scripts/` that runs both shims with the canonical path made to look
   absent and asserts the chosen behaviour. It must fail against the current
   files; say so in the evidence.

CAUTION ON THE NEW PIN: as of 2026-10-14 the four existing alert-latch pins
are all a generation behind the canonical and `check-vendored-pin-drift.sh`
has been red on them for 79 hours (tracked as donefile dn-766f). Take this
repo's new pin from donefile's CANONICAL file, not by copying a sibling's
stale pin, or this adds a fifth offender to that guard.

Filed read-only by a discovery sweep; no file in this repo was changed.


cross-board: names a file under 'meniapp' at /home/omri/projects/meniapp — consider filing there instead (see dn-334c).
