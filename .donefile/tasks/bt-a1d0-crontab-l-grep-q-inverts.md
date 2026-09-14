---
id: bt-a1d0
title: crontab -l | grep -q inverts under pipefail in test-monitoring.sh
status: done
priority: p3
tags:
  - reliability
  - probes
created: 2026-09-13
filed:
  owner: meni-worker/five-grep-q-pipelines-in-9c3b02
  at: 2026-09-13T12:40:25Z
done:
  at: 2026-09-14T09:11:00Z
  by: capacity-engine/worker
evidence:
  - type: commit
    value: 3d4df2705da58d7083005176c8c53b98402eb1ea
    verified: 2026-09-14T09:11:00Z
  - type: test
    cmd: 'out="$(cd /home/omri/projects/bass-tuner && bash scripts/test-monitoring.sh 2>&1 || true)";
      grep -q "bt-87c5: fixed guard (capture + here-string) caught the watchdog" <<<"$out"'
    exit: 0
    at: 2026-09-14T09:10:22Z
    log: evidence/bt-a1d0-2026-09-14T09-10-22Z-test.txt
    sha256: 2e562457ed911f15f27f5189086a6affe68d12f4182bf060059f2bddf9c9c7cf
    bytes: 180
  - type: note
    value: 'not real / already fixed: task filed 2026-09-13T12:40:25Z by fleet-wide scan; commit 3d4df27
      (same-day, 15:41 IDT) already fixed this exact bug under bt-87c5 -- crontab -l | grep -q
      replaced with capture-then-here-string (crontab_live=$(crontab -l 2>/dev/null || true); grep
      -q ... <<<"$crontab_live"), same shape as ma-518c. Regression test proves old pipe shape fails
      (SIGPIPE false-negative) and new guard catches it 3/3. No remaining crontab -l | grep -q
      pattern in repo (install-ff-sync-cron.sh:46 uses grep -A1, not -q, out of scope).'
---

scripts/test-monitoring.sh has `crontab -l 2>/dev/null | grep -q "check-heartbeat-liveness.sh"`. Under set -o pipefail, if crontab -l ever exceeds the 65536-byte pipe buffer, grep -q's early exit SIGPIPEs crontab -l and pipefail promotes that non-zero exit, inverting a found entry into a reported-missing one. Same bug class as meniapp ma-518c (fixed there by capturing into a variable first: out="$(crontab -l 2>/dev/null || true)"; grep -q ... <<<"$out"). Found by meniapp's extended scripts/check-crontab-lock-idiom-drift.sh fleet-wide scan, 2026-09-13.

## Log
- 2026-09-13 blocker ma-518c closed 2026-09-13T13:35:22Z — recheck whether this can proceed now.
- 2026-09-14 claimed by capacity-engine
- 2026-09-14 released by capacity-engine
- 2026-09-14 claimed by capacity-engine
- 2026-09-14 done by capacity-engine/worker — commit 3d4df2705da5, test `out="$(cd /home/omri/projects/bass-tuner && bash scripts/test-monitoring.sh 2>&1 || true)"; grep -q "bt-87c5: fixed guard (capture + here-string) caught the watchdog" <<<"$out"` exit 0 (log: evidence/bt-a1d0-2026-09-14T09-10-22Z-test.txt)
