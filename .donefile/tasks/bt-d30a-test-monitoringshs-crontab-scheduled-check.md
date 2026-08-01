---
id: bt-d30a
title: test-monitoring.sh's crontab-scheduled check is flaky under concurrent crontab writes —
  spurious FAIL despite the entry being present
status: claimed
priority: p3
tags:
  - ops
  - monitoring
  - flaky-test
created: 2026-07-31
claim:
  owner: capacity-engine
  at: 2026-08-01T10:30:42Z
---

While closing bt-b542, a manual re-run of scripts/test-monitoring.sh hit 'FAIL renew-wildcard-cert.sh missing from crontab' once, even though the line was actually present in `crontab -l` immediately before and after. Didn't recur on retry -- looks like a race against something else on the box rewriting the crontab (crontab -l reading mid-rewrite) rather than a real absence. This is donefile's --test command for the whole fallback-cert/domain-audit/cert-renewal/heartbeat monitor family, so a spurious FAIL here teaches people to re-run until green, which is exactly how a real missing-cron-entry failure would get waved through instead of investigated. Make the crontab-scheduled check retry/re-read once before failing, or otherwise make it robust to a mid-write read.

## Log
- 2026-08-01 claimed by capacity-engine
