---
id: bt-4e2a
title: Wire probe-bt-5fb7.sh into a periodic cron/monitor so a stale-deploy regression is caught
  automatically, not only when a task happens to close
status: done
priority: p3
tags:
  - ops
  - monitoring
created: 2026-08-05
done:
  at: 2026-08-14T15:04:21Z
  by: capacity-engine/worker
evidence:
  - type: commit
    value: c8ed0ee
    verified: 2026-08-14T15:04:21Z
  - type: test
    cmd: cd /home/omri/projects/bass-tuner && bash scripts/test-monitoring.sh
    exit: 0
    at: 2026-08-14T15:04:20Z
    log: evidence/bt-4e2a-2026-08-14T15-04-20Z-test.txt
    sha256: 805d7e7ee553ab5d5e1faef15ea0ba5bdb1e9f23cfb0cc16b5baf22c8c108c84
    bytes: 2565
---

<!-- capacity-engine: provenance, not part of the finding -->
Auto-filed by the capacity engine from a worker's FOLLOW-UP line — the title is that worker's own verbatim wording, so scope it before claiming.

Discovered while working bt-a60b, session `bass-tuner-board-has-no--4db70b`, dispatched on bass-tuner.
That task's report closed DONE (commit 7970cfd206bd666f5081176d21ee5de27e863360).

DONE WHEN: the finding above is either fixed and verified, or shown not to be real — say which in the closing evidence.

## Log
- 2026-08-14 claimed by capacity-engine
- 2026-08-14 done by capacity-engine/worker — commit c8ed0ee, test `cd /home/omri/projects/bass-tuner && bash scripts/test-monitoring.sh` exit 0 (log: evidence/bt-4e2a-2026-08-14T15-04-20Z-test.txt)
