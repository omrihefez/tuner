---
id: bt-b97b
title: check-permissions-policy.sh was never added to install-monitoring-crons.sh CRON_LINES, so the
  header drift monitor bt-40c5 shipped has never run once
status: done
priority: p3
tags:
  - monitoring
  - security
created: 2026-09-29
filed:
  owner: meni-worker/board-refill-work-discov-c54ec0
  at: 2026-09-29T17:38:18Z
done:
  at: 2026-09-29T18:30:31Z
  by: capacity-engine/worker
evidence:
  - type: commit
    value: 9d9db52
    verified: 2026-09-29T18:30:31Z
  - type: test
    cmd: cd /home/omri/projects/bass-tuner && bash scripts/install-monitoring-crons.sh --print-line |
      grep -q "run-monitor.sh permissions-policy .*check-permissions-policy.sh"
    exit: 0
    at: 2026-09-29T18:30:30Z
    log: evidence/bt-b97b-2026-09-29T18-30-30Z-test.txt
    sha256: 320a77516175c5ae0e189cf8f0b703209de1f491bf1818a3b820e7cbb009015e
    bytes: 170
  - type: live
    cmd: crontab -l | grep -q "16 6 \* \* \* .*permissions-policy .*check-permissions-policy.sh"
    exit: 0
    at: 2026-09-29T18:30:30Z
    log: evidence/bt-b97b-2026-09-29T18-30-30Z-live.txt
    sha256: ca0f45fc4870af606ff1f39a8a55449fc3889b3a21ab17797df1364a9f3a8fee
    bytes: 91
  - type: note
    value: Wired check-permissions-policy.sh into install-monitoring-crons.sh CRON_LINES at 06:16,
      installed for real (crontab -l confirms it live). Added a completeness guard (UNREGISTERED,
      symmetric to the existing DROPPED guard) that refuses to install if any scripts/check-*.sh
      with its own .test.sh companion is missing from $CRON_LINES; verified it fails (exit 1,
      refuses install) with the line removed and passes with it present.
---

`scripts/check-permissions-policy.sh` was added by bt-40c5 (commit d302286, 2026-09-27)
as a recurring drift monitor: it probes `bass.omrihefez.com` live and asserts the exact
`Permissions-Policy` value, because `microphone=()` instead of `microphone=(self)` would
silently break the tuner and no config-file grep would notice.

IT HAS NEVER RUN. It is in neither the installed crontab nor
`scripts/install-monitoring-crons.sh`'s `$CRON_LINES` (:88-93), which enumerates the six
monitors by hand:

    fallback-cert, domain-audit, tunnel-liveness, model-ids, heartbeat, stale-deploy

Measured 2026-09-29: `grep -rln check-permissions-policy` across `/home/omri/projects`,
`~/meni/bin` and `~/meni/scripts` returns only its own `.test.sh`, an evidence file, and
prose mentions in `check-model-ids-resolve.sh` and `bt-5abe`'s task body. Nothing
executes it.

THE HEARTBEAT MONITOR CANNOT CATCH THIS, which is what makes it worth a task rather than
a one-line fix. `check-monitor-heartbeats.sh` alerts on a monitor's log going stale — but
a monitor that was never registered writes no log, so there is no heartbeat to go stale.
`install-monitoring-crons.sh:147-161` has a DROPPED guard that refuses to install if a
monitor present in the live block is missing from `$CRON_LINES`; there is no symmetric
check for a monitor that exists in `scripts/` and was never added. The asymmetry is the
defect: every mechanism here watches monitors it already knows about.

IT IS ALREADY BEING ASSUMED LIVE. `bt-5abe`'s body (2026-09-29, two days after bt-40c5)
lists `check-permissions-policy.sh` among "the fleet's cross-repo monitors [that] already
live" in `scripts/`, alongside audit-domains.sh and check-tunnel-liveness.sh — all of
which are scheduled. The assumption is propagating into other tasks' reasoning.

NO LIVE DRIFT TODAY, stated plainly so nobody prices this as an incident. Probed
2026-09-29 20:36 IDT: `curl -sI https://bass.omrihefez.com/` returns
`permissions-policy: camera=(), microphone=(self), geolocation=()` — exactly `EXPECTED`
at :18. The header is correct; what is missing is anything that would notice if it
stopped being.

DONE WHEN
1. `check-permissions-policy.sh` is in `install-monitoring-crons.sh`'s `$CRON_LINES` as a
   `run-monitor.sh permissions-policy ...` line, with a time chosen inside the same
   pre-day-start window the other TLS/header checks use and a comment saying why, per
   this installer's existing convention.
2. The installer is actually run so the line lands in the live crontab, and
   `crontab -l` is quoted as evidence — installing the source of truth is not the same
   as installing the cron.
3. A check exists that would have caught this: assert every `scripts/check-*.sh` that
   has a `.test.sh` companion and is not deliberately excluded is named in `$CRON_LINES`.
   Two known-correct exclusions to encode rather than trip over —
   `check-heartbeat-liveness.sh` must NOT be crontab-scheduled (it runs on the separate
   `bass-tuner-heartbeat-watchdog.timer`, and `test-monitoring.sh:632` already asserts
   its absence), and `check-links.js`/`check-sw-cache-bump.js` are CI-run
   (`.github/workflows/ci.yml:49,55`).
4. That check is seen to FAIL — remove the new `permissions-policy` line and confirm it
   goes red — before this closes. A guard only ever seen passing is indistinguishable
   from one that cannot fire.

VERIFY (from the main checkout, never a worktree)

    cd /home/omri/projects/bass-tuner && bash scripts/install-monitoring-crons.sh --print-line

Filed by the periodic discovery sweep, 2026-09-29.

## Log
- 2026-09-29 claimed by capacity-engine
- 2026-09-29 released by capacity-engine
- 2026-09-29 claimed by capacity-engine
- 2026-09-29 Main, 2026-09-29 ~21:28 IDT — non-invasive note, not touching your claim.

Measured just now: `grep -c check-permissions-policy scripts/install-monitoring-crons.sh` = 2,
but `crontab -l | grep -c check-permissions-policy` = 0. So the entry is in CRON_LINES and the
installer has NOT been re-run since. The monitor still has never fired.

Flagging because the closure trap here is precise: this task's title is "was never added to
CRON_LINES", so editing the installer satisfies the TITLE while leaving the DEFECT — a monitor
that has never run — fully intact. Evidence on this one should assert the live crontab, not the
script:

    crontab -l | grep -q check-permissions-policy

and ideally also that it has produced a log line / heartbeat at least once, since bt-5abe already
lists this among "the fleet's cross-repo monitors" and an unregistered monitor writes no log, so
check-monitor-heartbeats.sh cannot see its absence either (that is the original filing's point).

Same shape as [[feedback_shipped_is_not_deployed_verify_live]]: the artifact changed, the
installed state did not.
- 2026-09-29 done by capacity-engine/worker — commit 9d9db52, test `cd /home/omri/projects/bass-tuner && bash scripts/install-monitoring-crons.sh --print-line | grep -q "run-monitor.sh permissions-policy .*check-permissions-policy.sh"` exit 0 (log: evidence/bt-b97b-2026-09-29T18-30-30Z-test.txt), live `crontab -l | grep -q "16 6 \* \* \* .*permissions-policy .*check-permissions-policy.sh"` exit 0 (log: evidence/bt-b97b-2026-09-29T18-30-30Z-live.txt)
