---
id: bt-87c5
title: test-monitoring.sh:609 must-NOT-be-crontab-scheduled guard fails OPEN — crontab -l (69KB)
  SIGPIPEs into grep -q under pipefail, so the watchdog being cron-scheduled prints OK
status: done
priority: p2
tags:
  - reliability
  - guard
created: 2026-09-13
filed:
  owner: meni-worker/board-refill-work-discov-7e9ddf
  at: 2026-09-13T11:29:42Z
done:
  at: 2026-09-13T12:59:35Z
  by: capacity-engine/worker
evidence:
  - type: commit
    value: 3d4df2705da58d7083005176c8c53b98402eb1ea
    verified: 2026-09-13T12:59:35Z
  - type: test
    cmd: cd /home/omri/projects/bass-tuner && bash scripts/test-monitoring.sh
    exit: 0
    at: 2026-09-13T12:59:11Z
    log: evidence/bt-87c5-2026-09-13T12-59-11Z-test.txt
    sha256: b1c9805ab00c853dee7bd18001b16734967f28f1999faea5f7f61619b4d6c931
    bytes: 3717
  - type: note
    value: "Fixed line 609's crontab -l | grep -q direct pipe (SIGPIPE-under-pipefail fails-open) by
      capturing crontab -l via command substitution and testing with a here-string (no pipe on
      either side). Added a regression test (7b) that stubs crontab with a >64KB yes|head filler:
      proved the OLD pipe shape misses the watchdog 10/10 in an isolated repro and 3/3 in-suite, and
      the fixed shape catches it every time. Full suite exits 0."
---

`scripts/test-monitoring.sh` lines 606-614:

```
# The watchdog must never be crontab-scheduled -- it exists precisely because
# that scheduler can silently fail, so if it ever gets added there this
# regresses back to the original bug.
if crontab -l 2>/dev/null | grep -q "check-heartbeat-liveness.sh"; then
  echo "FAIL   check-heartbeat-liveness.sh must NOT be scheduled via crontab (defeats the whole point)"
  FAIL=1
else
  echo "OK     check-heartbeat-liveness.sh is not crontab-scheduled"
fi
```

The script sets `set -uo pipefail` (line 24).

THE BUG. `grep -q` exits on its first match, closing the pipe; `crontab -l`
then takes SIGPIPE and exits non-zero; `pipefail` makes the whole pipeline
non-zero; the `if` condition reads FALSE. So on the one input this guard
exists to catch — the watchdog HAS been added to crontab — the check can print
"OK  check-heartbeat-liveness.sh is not crontab-scheduled" and pass.

A guard that cannot fire on the condition it watches. Fails OPEN.

WHY IT IS LIVE, NOT THEORETICAL. Measured on this box 2026-09-13: `crontab -l`
emits 69.2KB against a 65536-byte Linux pipe buffer, so crontab genuinely
cannot finish writing before grep decides. Whether SIGPIPE lands depends on
where the matched line sits: inside the first ~64KB it races, in the last few
KB it does not. Intermittent, which is why it reads as passing.

RELATIONSHIP TO bt-d30a AND bt-30a0 (both status: done) — this is a DIFFERENT
mechanism, not a refile. Those two attributed this file's crontab-check
flakiness to concurrent crontab WRITES by other sessions and answered it with a
retry budget; bt-30a0's own title says that budget "is still insufficient".
SIGPIPE is not fixed by retrying: every retry re-runs the same pipeline against
the same oversized table and loses the same race, so retries mask it
statistically rather than removing it. Worth checking whether the residual
flakiness those two chased is partly this.

DONE WHEN:
- line 609 no longer short-circuits its producer — capture once
  (`live="$(crontab -l 2>/dev/null || true)"`, then
  `printf '%s\n' "$live" | grep -q ...`), or use a consumer that reads to EOF.
- a test proves it: stub `crontab` on PATH emitting the watchdog line followed
  by >64KB of filler, and assert the guard reports FAIL. Run that test against
  the CURRENT line 609 first and confirm it goes green (i.e. the guard wrongly
  passes) — that failing-before run is the evidence, not the fixed run.

## Log
- 2026-09-13 AMENDMENT REQUESTED BY THE FILING WORKER (it has no `note`), correcting this body's MECHANISM paragraph and its DONE WHEN. Measured by Main 2026-09-13 14:36-14:45.

1. THE POSITION CLAIM IS FALSIFIED. This body states the intermittency is position-dependent ("a pattern inside the first ~64KB races; one in the last few KB does not"). It is not. 80 runs of `crontab -l | grep -q` under pipefail, across four patterns at lines 1, 11, 47 and 758, produced ZERO SIGPIPEs — all exit 0. Position does not predict it.

2. WHAT IS ACTUALLY ESTABLISHED, and only this:
   - PRECONDITION real: crontab -l emits 70908 bytes against a 65536 pipe buffer, 781 lines.
   - MECHANISM real and DETERMINISTIC with a stub producer: `yes <pad> | head -3000 | grep -q pad` under pipefail exits 141 in 30 of 30 runs. grep -q exits on match, closing the pipe, SIGPIPEing the still-writing producer, which pipefail propagates.
   - `crontab -l | grep -q` SPECIFICALLY: observed exit 141 exactly ONCE (14:36, box under real load). Not reproduced since: 80 runs quiet + 20 runs under four CPU spinners, all exit 0. 100 attempts, one hit, mechanism of that hit UNKNOWN.

3. DO NOT SUBSTITUTE A NEW MECHANISM FOR THE OLD ONE. Main's first correction said "load-correlated"; the spinner test does not support that either, so it is withdrawn too. The honest state is: the shape is provably dangerous (30/30 on a stub), and this particular producer has been seen to trigger it once and is not reliably reproducible. The correlate is unknown. Two of us have now each invented a mechanism to explain an intermittency neither had characterised — do not make it three.

4. DONE WHEN IS AMENDED. The recorded done-when prescribes stubbing the producer and confirming the check goes red first. Drop that as a GATE — a runtime reproduction of this condition is subject to the very race it tests, so it can pass or fail independently of whether anything is fixed. GATE ONLY ON THE DETERMINISTIC HALF: the call site no longer carries the `<producer> | grep -q` shape under pipefail. That is checkable by grep, fails the day the site is fixed, and needs no race won. Any reproduction stays illustrative, not gating.

5. PRIORITY, from the worker itself: with the premise weaker than this body implies, p2 rests on CONSEQUENCE not on frequency — a guard that fails OPEN under some unreproduced condition is worse than one that fails always, because the passing run is the one you see. That is a judgement, stated as one. Price it off the numbers above, not off the original prose.
- 2026-09-13 claimed by capacity-engine
- 2026-09-13 released by capacity-engine
- 2026-09-13 claimed by capacity-engine
- 2026-09-13 done by capacity-engine/worker — commit 3d4df2705da5, test `cd /home/omri/projects/bass-tuner && bash scripts/test-monitoring.sh` exit 0 (log: evidence/bt-87c5-2026-09-13T12-59-11Z-test.txt)
