---
id: bt-b97b
title: check-permissions-policy.sh was never added to install-monitoring-crons.sh CRON_LINES, so the
  header drift monitor bt-40c5 shipped has never run once
status: open
priority: p3
tags:
  - monitoring
  - security
created: 2026-09-29
filed:
  owner: meni-worker/board-refill-work-discov-c54ec0
  at: 2026-09-29T17:38:18Z
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
