# How to write tests in bass-tuner

Written 2026-08-31 (bt-4722) from a full measured audit of this repo's suite —
fanned out from meniapp's test audit (ma-65f4/ma-38dd, model: `hub/docs/TESTING.md`).
Every number below was actually run, not estimated.

## What was measured

| | before this pass | after |
|---|---|---|
| `test/*.test.js` files | 11 files, 111 `node --test` cases | unchanged |
| `test/*.test.js` wall clock | 4.3s (combined, `node --test` runs files concurrently) | unchanged |
| `scripts/*.test.sh` files run by `npm test` | 2 (`audit-domains.test.sh`, `run-monitor-latch.test.sh`) | 3 |
| tests that existed but **never ran** in CI or pre-push | 1 file, 10 checks (`scripts/lib/alert-latch.test.sh`) | 0 |
| exact duplicate test titles | 0 of 79 static `test("...")` titles | — |

**The one real bug this pass found:** `scripts/lib/alert-latch.test.sh` is a real,
hermetic, 10-check regression test for `alert-latch.sh` (the delivery/latch
contract seven live monitor guards depend on). It passes cleanly when run by
hand (`bash scripts/lib/alert-latch.test.sh` → `PASS — 10/10 checks`). But
`package.json`'s `test` script looped over `scripts/*.test.sh` only —
a glob that does not descend into `scripts/lib/`, so this file has been invisible
to `npm test`, the GitHub Actions `static-checks` job, and the pre-push gate
since it was written. Verified by running the old `npm test` unmodified and
confirming its output never mentioned `alert-latch.test.sh` while `bash
scripts/lib/alert-latch.test.sh` on its own reported 10/10 passing — a real
gap, not a flaky test. Fixed by adding `scripts/lib/*.test.sh` to the loop.

**Everything else measured as expected, not as "bloat":** no exact duplicate
test titles, and the two files covering related ground —
`test/pitch-math.test.js` (pure math: `midiToFreq`/`freqToMidi`/`cents`/
`closestString`/`freqRange`) and `test/mains-hum.test.js` (YIN pitch detection
under synthesized 50/60Hz hum and noise) — test different invariants, not the
same one twice. No cuts were made.

## Suites

| command | what it runs | tests | wall clock |
|---|---|---|---|
| `npm run test:unit` | everything with no real external dependency | 105 JS + 3 hermetic shell | ~5s |
| `npm run test:integration` | the one test that spawns real git+node subprocesses | 6 | ~2s |
| `npm test` | both (identical set to before this pass, plus the previously-unwired file) | 111 JS + 3 shell | ~unchanged |

A test counts as **integration** only if it depends on something real outside
this process that an in-process test can't fake: an unstubbed external binary,
a real network call, or real scheduler/crontab state. By that measure there is
exactly **one** integration test file in this repo:
`test/check-sw-cache-bump.test.js`. It creates real temporary git repositories
on disk and shells out to the real `git` binary and a real `node
scripts/check-sw-cache-bump.js` subprocess, because the thing it verifies —
whether the sw.js cache-version bump actually diffs against the right base ref
— is a property of real git plumbing that an in-process mock would just
re-assert rather than test. There's no `main(argv)`-style refactor available
here (unlike hub's `cli.test.ts` fix) because the behavior under test *is* git
diff semantics, not argument parsing.

**The three `scripts/*.test.sh` files count as unit, not integration**, even
though a shell script can only be exercised by running it: `audit-domains.test.sh`,
`run-monitor-latch.test.sh`, and `scripts/lib/alert-latch.test.sh` all say so in
their own header comments and all stub out every real dependency (fake
`CURL_CMD`, fake notifier, no real crontab, no real network). Running bash to
test a bash script is the process boundary, not an escape from it — the
distinction that matters is real-vs-stubbed external state, not "spawns a
process" by itself.

**Deliberately excluded from both, and from `npm test` entirely:**
`scripts/test-monitoring.sh`. It is a genuine live/integration self-test — it
forces real monitor scripts to fail and checks they actually alert to
`~/inbox`, and it has a documented concurrent-rewrite race against the real
crontab (bt-d30a) that a deterministic suite must not inherit. It isn't named
`*.test.sh` on purpose, so no glob here ever picks it up automatically; it's
run by hand as donefile evidence for the tasks that touch the monitoring
scripts (see its own header comment for provenance).

## What this audit deliberately did NOT do

The instinct going in, per the fan-out brief, was to expect "less bloat than
expected" the same way meniapp's hub pass did. Measured, that held: 111 JS
tests across 11 files in 4.3s is not a suite that needs trimming, and zero of
79 test titles were literal duplicates. So this pass did **not** delete any
test, did **not** merge any files, and did **not** restructure the JS test
layout (e.g. into `test/unit/` + `test/integration/` directories) — the
directory move would have touched three `.donefile/` evidence/task references
to `check-sw-cache-bump.test.js`'s path for no behavioral gain, since a single
`npm run test:integration` script name change already gives the fast/split
path item 3 asked for.

The only change with teeth is the `scripts/lib/*.test.sh` glob fix — a real,
previously-silent coverage gap, not a stylistic split. If this suite feels
slow again, measure per-file first:

```bash
for f in test/*.test.js; do echo "== $f =="; node --test "$f" 2>&1 | grep duration_ms; done
```

`test/mains-hum.test.js` (CPU-bound YIN pitch detection across many synthesized
signals) and `test/check-sw-cache-bump.test.js` (real git subprocesses) were
the two outliers found this way — both legitimately slow for what they prove,
neither worth cutting.
