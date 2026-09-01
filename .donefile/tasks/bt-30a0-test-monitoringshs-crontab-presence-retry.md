---
id: bt-30a0
title: test-monitoring.sh's crontab-presence retry budget (bt-d30a fix) is still insufficient under
  heavier concurrent load
status: done
priority: p3
tags:
  - ops
  - flaky-test
created: 2026-08-29
done:
  at: 2026-09-01T12:19:01Z
  by: capacity-engine/worker
evidence:
  - type: commit
    value: 4594cd6
    verified: 2026-09-01T12:19:01Z
  - type: test
    cmd: bash scripts/test-monitoring.sh
    exit: 0
    at: 2026-09-01T12:18:47Z
    log: evidence/bt-30a0-2026-09-01T12-18-47Z-test.txt
    sha256: 7d14c849ac8e43cfc7bfc976572da7ec15fac334d9a8fd450e94e6260a5db9f5
    bytes: 3280
  - type: note
    value: "bt-d30a's 5x0.5s poll only narrowed the concurrent-rewrite race; test-monitoring.sh's step 5
      now takes the fleet's shared crontab-install.lock (ma-09c1, flock -s) before reading crontab
      -l, which every participating installer already serializes writes on -- closes the race for
      those writers instead of just shrinking the window. Kept a widened (8x1s) retry as fallback
      for the one non-participating writer found (iac/install-mail-digest-cron.sh, filed as
      iac-62b1). Verified: (1) full suite ran clean (0 FAIL) 3x back-to-back on this same loaded box
      (load avg ~5.3/4 cores) -- the exact repro shape bt-7964 measured failing 2/3 times pre-fix;
      (2) a standalone lock-blocking check proved the mechanism itself: a bare crontab -l does NOT
      wait for a concurrent flock -x holder (0.01s), the new read_crontab_locked DOES (2.7s,
      matching the writer's hold time) -- a check that fails if the fix regresses."
---

bt-d30a added a 5x0.5s retry to test-monitoring.sh's crontab-presence check for exactly this race. During bt-7964 (2026-08-29) it still produced spurious FAIL on 2 of 3 back-to-back full-suite runs (different monitor name each time -- fallback-cert, renew-wildcard-cert, audit-domains -- so not one flaky pattern), then passed clean on the 3rd/4th retry of the whole suite. The retry budget or its backoff may need to grow, or the check may need to diff against a known-good snapshot instead of polling. Not reopening bt-d30a since its original fix and evidence are still valid for the scenario it was closed against; this is reporting that the same class of contention still bites at today's box load.

## Log
- 2026-09-01 claimed by capacity-engine
- 2026-09-01 done by capacity-engine/worker — commit 4594cd6, test `bash scripts/test-monitoring.sh` exit 0 (log: evidence/bt-30a0-2026-09-01T12-18-47Z-test.txt)
