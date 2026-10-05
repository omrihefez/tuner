---
id: bt-2604
title: check-monitor-heartbeats.sh watches 6 of the 7 installed monitors — permissions-policy has no
  heartbeat entry
status: open
priority: p2
tags:
  - monitoring
  - reliability
created: 2026-10-05
filed:
  owner: meni-worker/board-refill-work-discov-fc64ea
  at: 2026-10-05T10:47:12Z
---

`scripts/check-monitor-heartbeats.sh` is the watcher-of-watchers: its `MAX_AGE_HOURS`
map (lines 53-66) names each installed monitor and how stale its log may get before
an alert fires. The map is hand-maintained and currently holds SIX entries:
`fallback-cert`, `domain-audit`, `tunnel-liveness`, `cert-renewal`, `stale-deploy`,
`model-ids`.

`scripts/install-monitoring-crons.sh` installs SEVEN monitors. The seventh —
`permissions-policy` (bt-40c5, wired by bt-b97b) — is missing from the map.

MEASURED 2026-10-05, all three independently:
- installer: `install-monitoring-crons.sh:100` -> `16 6 * * * $RUNNER permissions-policy $PERMISSIONS_POLICY`,
  and its own completion banner at :251 lists "06:16 permissions-policy" as installed.
- live crontab: `crontab -l` carries that exact line inside the
  `# BEGIN bass-tuner-monitoring` block.
- the monitor really runs: `/home/omri/.cache/bass-tuner-permissions-policy.log`
  has a `=== permissions-policy <ts> ===` marker + `exit 0` for every day
  2026-09-30 through 2026-10-05, newest stamped `2026-10-05T06:16:01+03:00`.

So the monitor is healthy today and nothing watches whether it stays that way. If the
cron line were dropped, the script started failing before it could write its marker, or
`run-monitor.sh` stopped stamping, `check-monitor-heartbeats.sh` would keep reporting
`OK` across its six and never mention the seventh. That is precisely the failure this
watcher exists to catch, and `permissions-policy` has already had one
shipped-but-unscheduled incident — `install-monitoring-crons.sh:187` records
"check-permissions-policy.sh (bt-40c5) shipped and sat unscheduled for two ...".

NOT A ONE-OFF, WHICH IS THE ACTUAL POINT: every other entry in this map was added by
hand AFTER its monitor already existed — `tunnel-liveness` (bt-8818), `model-ids`
(bt-5abe), `stale-deploy` (bt-4e2a), each carrying its own task id in a trailing
comment. A hand-copied list beside a generated one drifts every time, and this is the
fourth instance. The map's own comment already points at the single source of truth
("sized to that monitor's own installed cron cadence (see install-monitoring-crons.sh
/ install-cert-renewal-cron.sh)") without deriving from it.

Note `heartbeat` itself is deliberately absent and must stay absent — bt-6492 rejected
a self-referential entry, and `check-heartbeat-liveness.sh` on
`bass-tuner-heartbeat-watchdog.timer` covers that case on a separate scheduler. Do not
"fix" this by adding `heartbeat`.

DONE WHEN, in preference order:
(a) `check-monitor-heartbeats.sh` derives its monitor set from the installers'
    `--print-line` output (the same source `check-crontab-drift.sh` already reconciles
    against) rather than restating it, with `heartbeat` explicitly excluded and a
    per-monitor max-age still overridable; OR
(b) at minimum, `permissions-policy` is added to `MAX_AGE_HOURS` with max age 30
    (daily 06:16, same cadence/slack as its 06:10-06:14 neighbours) AND a test asserts
    the map covers every monitor the installer installs, so the next addition cannot
    drift again.

EVIDENCE MUST BE ABLE TO FAIL: the closing check has to be one that is RED today.
A test that enumerates the installer's monitor names and asserts each appears in
`MAX_AGE_HOURS` fails right now on `permissions-policy` — run it against the parent
commit, watch it fail, and say so in the note. Do not close on a grep for the string
`permissions-policy` in `check-monitor-heartbeats.sh`: that passes the moment the line
is typed and would pass equally if the max-age were nonsense or the derivation were
still hand-maintained.
