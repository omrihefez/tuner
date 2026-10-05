---
id: bt-405f
title: install-monitoring-crons.sh's UNREGISTERED guard trips on check-cors-corp-consistency.sh (has
  its own .test.sh, never added to $CRON_LINES)
status: done
priority: p3
tags:
  - monitoring
  - reliability
created: 2026-10-05
filed:
  owner: meni-worker/check-monitor-heartbeats-36415e
  at: 2026-10-05T11:14:59Z
done:
  at: 2026-10-05T12:25:08Z
  by: capacity-engine/worker
evidence:
  - type: commit
    value: cf4ef1af340ae23fe2317f9d9e2ee85663bba1b1
    verified: 2026-10-05T12:25:08Z
  - type: test
    cmd: cd /home/omri/projects/bass-tuner && ./scripts/install-monitoring-crons.sh --dry-run
    exit: 0
    at: 2026-10-05T12:25:07Z
    log: evidence/bt-405f-2026-10-05T12-25-07Z-test.txt
    sha256: c8d60bcccc3a9b3455f08abef2d2a558058d833fbcff35084d3274f0d6bdf054
    bytes: 128662
  - type: live
    cmd: crontab -l | grep -q '18 6 \* \* \* .*cors-corp-consistency .*check-cors-corp-consistency.sh'
    exit: 0
    at: 2026-10-05T12:25:07Z
    log: evidence/bt-405f-2026-10-05T12-25-07Z-live.txt
    sha256: 6152a602f7405e5a83cd245d72cf47f31ca523ade62d8b1bcb0488d5f296db68
    bytes: 97
---

Found while closing bt-2604 (unrelated): `scripts/install-monitoring-crons.sh --dry-run` refuses to install (exit 1) because `scripts/check-cors-corp-consistency.sh` has its own regression test (`check-cors-corp-consistency.test.sh`) but is absent from $CRON_LINES -- the exact bt-b97b class of bug that bit permissions-policy (bt-40c5) before bt-2604 fixed the heartbeat-watcher side of it. Reproduces identically on unmodified origin/main (confirmed before touching anything for bt-2604), so it's pre-existing and not introduced by that work. Either add check-cors-corp-consistency.sh to install-monitoring-crons.sh's $CRON_LINES on a real cadence, or add it to $UNREGISTERED_EXCLUDE if it's deliberately not meant to be cron-scheduled.

## Log
- 2026-10-05 claimed by capacity-engine
- 2026-10-05 done by capacity-engine/worker — commit cf4ef1af340a, test `cd /home/omri/projects/bass-tuner && ./scripts/install-monitoring-crons.sh --dry-run` exit 0 (log: evidence/bt-405f-2026-10-05T12-25-07Z-test.txt), live `crontab -l | grep -q '18 6 \* \* \* .*cors-corp-consistency .*check-cors-corp-consistency.sh'` exit 0 (log: evidence/bt-405f-2026-10-05T12-25-07Z-live.txt)
