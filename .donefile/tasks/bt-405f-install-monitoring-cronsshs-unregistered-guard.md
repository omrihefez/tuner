---
id: bt-405f
title: install-monitoring-crons.sh's UNREGISTERED guard trips on check-cors-corp-consistency.sh (has
  its own .test.sh, never added to $CRON_LINES)
status: claimed
priority: p3
tags:
  - monitoring
  - reliability
created: 2026-10-05
filed:
  owner: meni-worker/check-monitor-heartbeats-36415e
  at: 2026-10-05T11:14:59Z
claim:
  owner: capacity-engine
  at: 2026-10-05T12:12:50Z
---

Found while closing bt-2604 (unrelated): `scripts/install-monitoring-crons.sh --dry-run` refuses to install (exit 1) because `scripts/check-cors-corp-consistency.sh` has its own regression test (`check-cors-corp-consistency.test.sh`) but is absent from $CRON_LINES -- the exact bt-b97b class of bug that bit permissions-policy (bt-40c5) before bt-2604 fixed the heartbeat-watcher side of it. Reproduces identically on unmodified origin/main (confirmed before touching anything for bt-2604), so it's pre-existing and not introduced by that work. Either add check-cors-corp-consistency.sh to install-monitoring-crons.sh's $CRON_LINES on a real cadence, or add it to $UNREGISTERED_EXCLUDE if it's deliberately not meant to be cron-scheduled.

## Log
- 2026-10-05 claimed by capacity-engine
