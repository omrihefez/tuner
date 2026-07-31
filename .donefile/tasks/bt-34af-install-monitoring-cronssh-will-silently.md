---
id: bt-34af
title: install-monitoring-crons.sh will silently DELETE the heartbeat cron bt-b542 depends on — its
  managed block omits the entry it now wipes
status: open
priority: p1
tags:
  - ops
  - monitoring
created: 2026-07-31
---

bt-b542 wrote scripts/check-monitor-heartbeats.sh and it is scheduled in the live crontab at line 37. But that line sits INSIDE the block install-monitoring-crons.sh manages:

    34: # BEGIN bass-tuner-monitoring (scripts/install-monitoring-crons.sh)
    35: 5 6 * * *  run-monitor.sh fallback-cert  ...
    36: 10 6 * * * run-monitor.sh domain-audit   ...
    37: 0 7 * * *  run-monitor.sh heartbeat      .../check-monitor-heartbeats.sh
    38: # END bass-tuner-monitoring (scripts/install-monitoring-crons.sh)

install-monitoring-crons.sh:37 deletes everything between those markers and rewrites the block from its own $CRON_LINES — and `grep -n heartbeat scripts/install-monitoring-crons.sh` returns NOTHING. So the next run of the installer removes the heartbeat schedule and nothing reports it.

That is the same defect bt-b542 was filed to fix, reintroduced one layer up: the monitor would stop running, and the only thing that would have noticed is the monitor itself.

It also explains how the original dead cron came to exist. `git log -S check-monitor-heartbeats -- scripts/install-monitoring-crons.sh` is empty, so that crontab line was never installed from the tracked installer. The bt-b542 worker found an abandoned worktree at /tmp/bt-a942-wt2 (branch bt-a942-heartbeat) holding uncommitted edits to install-monitoring-crons.sh AND an untracked check-monitor-heartbeats.sh. Someone ran the installer from that worktree: the cron persisted pointing at a repo path, the script never landed on main, and bt-a942 was closed anyway. Live cron, missing script, green task.

FIX: add the heartbeat entry to $CRON_LINES in install-monitoring-crons.sh so the tracked installer is the single source of truth for the whole block.

VERIFY, and this is the whole point — run the installer and confirm the heartbeat line SURVIVES:

    crontab -l | grep -c 'run-monitor.sh heartbeat'   # 1 before
    bash scripts/install-monitoring-crons.sh
    crontab -l | grep -c 'run-monitor.sh heartbeat'   # must still be 1

Do that against the CURRENT installer first and watch the count go to 0 — that is the negative control, and without seeing it you have not proven the bug exists. Restore the cron afterwards either way.

WHILE YOU ARE HERE: the same class of question applies to line 38's `grep -vF` cleanup of legacy fallback-cert/domain-audit lines. Check whether any other monitor is scheduled outside the tracked installer and would be wiped the same way.

Related: bt-b542 (the script), and the abandoned worktree cleanup follow-up. Found by Main verifying bt-b542, 2026-07-31.
