---
id: bt-a1d0
title: crontab -l | grep -q inverts under pipefail in test-monitoring.sh
status: open
priority: p3
tags:
  - reliability
  - probes
created: 2026-09-13
filed:
  owner: meni-worker/five-grep-q-pipelines-in-9c3b02
  at: 2026-09-13T12:40:25Z
---

scripts/test-monitoring.sh has `crontab -l 2>/dev/null | grep -q "check-heartbeat-liveness.sh"`. Under set -o pipefail, if crontab -l ever exceeds the 65536-byte pipe buffer, grep -q's early exit SIGPIPEs crontab -l and pipefail promotes that non-zero exit, inverting a found entry into a reported-missing one. Same bug class as meniapp ma-518c (fixed there by capturing into a variable first: out="$(crontab -l 2>/dev/null || true)"; grep -q ... <<<"$out"). Found by meniapp's extended scripts/check-crontab-lock-idiom-drift.sh fleet-wide scan, 2026-09-13.

## Log
- 2026-09-13 blocker ma-518c closed 2026-09-13T13:35:22Z — recheck whether this can proceed now.
