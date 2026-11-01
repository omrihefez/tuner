---
id: bt-06c9
title: "csp-strength alert latch never fires: per-request CSP nonce in output changes the
  fingerprint daily (18 identical alerts 10-12..10-29)"
status: done
priority: p2
tags:
  - monitoring
created: 2026-11-01
filed:
  owner: meni-worker/board-refill-work-discov-fc4603
  at: 2026-11-01T06:57:43Z
done:
  at: 2026-11-01T07:12:31Z
  by: capacity-engine/worker
evidence:
  - type: commit
    value: ce0bb918d1bf026c033567ade0757dd5e471a079
    verified: 2026-11-01T07:12:31Z
  - type: test
    cmd: cd /home/omri/projects/bass-tuner && git fetch -q origin && git show
      origin/main:scripts/run-monitor-latch.test.sh > /dev/null && bash
      scripts/run-monitor-latch.test.sh
    exit: 0
    at: 2026-11-01T07:12:30Z
    log: evidence/bt-06c9-2026-11-01T07-12-30Z-test.txt
    sha256: d3695d4fe8ad7375d1be4adfc289a5bc1a957af643661c3905388e58d3cfa35c
    bytes: 670
  - type: note
    value: test step 5 fails on parent 2289e1b, passes with fix
---

Found by the 2026-11-01 discovery sweep.

## What is wrong

`scripts/run-monitor.sh` latches an inbox alert on `sha256(out)` of the monitor's full output (bt-7964), so a persistent failure should alert ONCE. `scripts/check-csp-strength.sh` prints the raw CSP header for every DRIFT host, and trips.omrihefez.com's CSP carries a per-request `'nonce-...'` value. So the fingerprint changes on every run, the latch never matches, and a single unchanged finding re-alerts every day.

## Measured

- `~/inbox/bass-tuner-csp-strength-2026-10-12.md` through `-2026-10-29.md`: 18 consecutive daily alert files for the same one DRIFT line (trips.omrihefez.com `img-src ... https:` wildcard).
- The nonce differs in every file: 10-15 `nonce-TUICyzdl...`, 10-16 `nonce-MF3bTOeu...`, 10-28 `nonce-z4fUvi0q...`, 10-29 `nonce-t+XCioad...`.
- `grep -c "already alerted" ~/.cache/bass-tuner-csp-strength.log` = 0.
- The check went green 2026-10-30 (exit 0), so nothing is alerting right now. The bug fires again the next time any nonce-bearing host drifts. That is exactly the bt-5149 daily re-alarm the latch was built to stop.

Any other run-monitor.sh check that echoes a live response header (request ids, dates, nonces) has the same exposure. Worth a look at check-permissions-policy.sh and check-cors-corp-consistency.sh too.

## Fix shape

Either have check-csp-strength.sh redact `'nonce-[^']*'` to `'nonce-…'` before it prints, or have run-monitor.sh fingerprint a normalised form of the output. The first is narrower.

## DONE WHEN

A test feeds run-monitor.sh a stub monitor that fails twice with output differing only in a CSP nonce, and asserts that exactly one inbox alert gets written. That test must fail on current HEAD.

## Log
- 2026-11-01 claimed by capacity-engine
- 2026-11-01 done by capacity-engine/worker — commit ce0bb918d1bf, test `cd /home/omri/projects/bass-tuner && git fetch -q origin && git show origin/main:scripts/run-monitor-latch.test.sh > /dev/null && bash scripts/run-monitor-latch.test.sh` exit 0 (log: evidence/bt-06c9-2026-11-01T07-12-30Z-test.txt)
