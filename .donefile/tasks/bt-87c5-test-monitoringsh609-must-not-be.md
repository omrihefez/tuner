---
id: bt-87c5
title: test-monitoring.sh:609 must-NOT-be-crontab-scheduled guard fails OPEN — crontab -l (69KB)
  SIGPIPEs into grep -q under pipefail, so the watchdog being cron-scheduled prints OK
status: open
priority: p2
tags:
  - reliability
  - guard
created: 2026-09-13
filed:
  owner: meni-worker/board-refill-work-discov-7e9ddf
  at: 2026-09-13T11:29:42Z
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
