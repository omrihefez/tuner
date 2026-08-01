---
id: bt-9f09
title: Clean up abandoned worktree /tmp/bt-a942-wt2 (branch bt-a942-heartbeat) — stale uncommitted
  attempt at the heartbeat check, never merged
status: done
priority: p3
tags:
  - ops
  - cleanup
created: 2026-07-31
done:
  at: 2026-08-01T10:08:27Z
  by: capacity-engine/worker
evidence:
  - type: test
    cmd: test ! -d /tmp/bt-a942-wt2 && ! git -C /home/omri/projects/bass-tuner rev-parse --verify
      --quiet bt-a942-heartbeat
    exit: 0
    at: 2026-08-01T10:08:27Z
    log: evidence/bt-9f09-2026-08-01T10-08-27Z-test.txt
    sha256: cf1df8919e9f8343c5d6683f0afff551f653d1483f507f17e59acddc6b22864e
    bytes: 118
  - type: note
    value: "Diffed the abandoned worktree's uncommitted work (stamp-file heartbeat check +
      install-monitoring-crons/run-monitor edits) against origin/main: fully superseded by the
      log-timestamp-based check-monitor-heartbeats.sh + meni-notify approach that landed via
      bt-b542/bt-34af/bt-6492. Nothing to salvage. Removed /tmp/bt-a942-wt2 worktree and deleted the
      fully-merged local branch bt-a942-heartbeat."
---

Found while working bt-b542: /tmp/bt-a942-wt2 is a worktree on branch bt-a942-heartbeat, checked out from an old commit far behind main, with uncommitted local edits to scripts/install-monitoring-crons.sh, scripts/run-monitor.sh, scripts/test-monitoring.sh, and an untracked scripts/check-monitor-heartbeats.sh. Per Main's bt-34af investigation, this is almost certainly where the orphaned 'heartbeat' cron line originally came from (someone ran install-monitoring-crons.sh from this worktree, the cron persisted pointing at a repo path, the script itself never landed on main, and bt-a942 got closed anyway). Remove the worktree/branch once nothing else needs to reference it for that archaeology, or salvage/diff anything still useful first.

## Log
- 2026-08-01 claimed by capacity-engine
- 2026-08-01 done by capacity-engine/worker — test `test ! -d /tmp/bt-a942-wt2 && ! git -C /home/omri/projects/bass-tuner rev-parse --verify --quiet bt-a942-heartbeat` exit 0 (log: evidence/bt-9f09-2026-08-01T10-08-27Z-test.txt)
