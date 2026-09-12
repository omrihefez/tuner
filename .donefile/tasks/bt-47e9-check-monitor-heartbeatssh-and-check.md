---
id: bt-47e9
title: check-monitor-heartbeats.sh and check-heartbeat-liveness.sh both alert unconditionally with
  no marker/dedup — same class as th-b15d
status: done
priority: p3
tags:
  - ops
  - notifications
created: 2026-09-09
filed:
  owner: meni-worker/six-open-trips-hub-tasks-f87c7d
  at: 2026-09-09T06:56:27Z
done:
  at: 2026-09-12T14:50:54Z
  by: capacity-engine/worker
evidence:
  - type: commit
    value: 470f3458c8f7ce199b0b07fe927b4e2aae4e5efb
    verified: 2026-09-12T14:50:54Z
  - type: test
    cmd: bash /home/omri/projects/bass-tuner/scripts/check-heartbeat-alert-dedup.test.sh
    exit: 0
    at: 2026-09-12T14:50:50Z
    log: evidence/bt-47e9-2026-09-12T14-50-50Z-test.txt
    sha256: e3220a9b501fedf5eabae81eb183bca0dab3b5d51edb195a691b10341f83383e
    bytes: 1088
---

Re-filed from trips-hub th-183b (dropped there — deliverable is this repo, not trips-hub).

check-monitor-heartbeats.sh (daily) and check-heartbeat-liveness.sh (6h timer) both call
alert()/notify unconditionally, with no marker/dedup — same class of bug as th-b15d
(heal-dev-alias.sh, fixed 2026-08-14 commit 58dbaf14: "alert on change, not on every cron tick").

Verified 2026-09-09: both scripts exist at scripts/check-monitor-heartbeats.sh and
scripts/check-heartbeat-liveness.sh in this repo. th-b15d's fix pattern was scoped to
heal-dev-alias.sh only — these two were not touched by that commit.

Original finding from trips-hub th-7c5a (session audit-every-other-cron-d-db0323, closed DONE
commit b90cadd), auto-filed on trips-hub because the engine could not route it. Held gated on
th-b61d (a shared-runner directive) until 2026-08-14, since unblocked.

DONE WHEN: both scripts only alert on the first failure of a run (or on state change), not on
every tick, matching the heal-dev-alias.sh pattern from th-b15d.

## Log
- 2026-09-12 claimed by capacity-engine
- 2026-09-12 done by capacity-engine/worker — commit 470f3458c8f7, test `bash /home/omri/projects/bass-tuner/scripts/check-heartbeat-alert-dedup.test.sh` exit 0 (log: evidence/bt-47e9-2026-09-12T14-50-50Z-test.txt)
