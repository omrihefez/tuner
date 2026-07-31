---
id: bt-6492
title: Nothing checks the heartbeat monitor's own liveness — check-monitor-heartbeats.sh watches the
  other three monitors but not itself, and it runs from the very cron block it watches
status: open
priority: p2
tags:
  - ops
  - monitoring
created: 2026-07-31
---

check-monitor-heartbeats.sh (bt-b542) declares MAX_AGE_HOURS for fallback-cert, domain-audit and cert-renewal — every monitor except itself. It is scheduled at 07:00 from the same managed crontab block it watches (scripts/install-monitoring-crons.sh, see bt-34af).

DO NOT fix this by adding a fourth [heartbeat]=N entry to MAX_AGE_HOURS. That is self-referential and changes nothing. A watcher inside the system it watches can only ever report 'I ran and things were fine'; it structurally cannot report 'I never ran'. If cron stops firing, if the crontab entry is removed or edited away, if run-monitor.sh loses its exec bit — the script simply does not execute, and its silence is indistinguishable from a clean pass. That is the exact failure mode bt-b542 was filed to close for the other three monitors, and that bt-34af closed one layer up at the installer.

The check must come from OUTSIDE bass-tuner's cron. Something already running on its own schedule should assert that a FRESH heartbeat artifact exists. The artifact and its parse convention already exist: run-monitor.sh appends a '=== heartbeat <ISO8601> ===' marker to $HOME/.cache/bass-tuner-heartbeat.log on every invocation, regardless of the wrapped script's exit code — the same convention check-monitor-heartbeats.sh itself reads for the monitors it covers. Candidates already outside this cron: the morning brief, or the capacity engine.

DONE WHEN: something NOT scheduled by scripts/install-monitoring-crons.sh alerts when the last run marker in ~/.cache/bass-tuner-heartbeat.log is older than roughly 30h (07:00 daily + slack). VERIFY by pointing it at a stale and then an absent log and observing the alert both times.

Raised to p2 by Main, 2026-07-31, reviewing bt-34af.
