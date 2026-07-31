---
id: bt-9f09
title: Clean up abandoned worktree /tmp/bt-a942-wt2 (branch bt-a942-heartbeat) — stale uncommitted
  attempt at the heartbeat check, never merged
status: open
priority: p3
tags:
  - ops
  - cleanup
created: 2026-07-31
---

Found while working bt-b542: /tmp/bt-a942-wt2 is a worktree on branch bt-a942-heartbeat, checked out from an old commit far behind main, with uncommitted local edits to scripts/install-monitoring-crons.sh, scripts/run-monitor.sh, scripts/test-monitoring.sh, and an untracked scripts/check-monitor-heartbeats.sh. Per Main's bt-34af investigation, this is almost certainly where the orphaned 'heartbeat' cron line originally came from (someone ran install-monitoring-crons.sh from this worktree, the cron persisted pointing at a repo path, the script itself never landed on main, and bt-a942 got closed anyway). Remove the worktree/branch once nothing else needs to reference it for that archaeology, or salvage/diff anything still useful first.
