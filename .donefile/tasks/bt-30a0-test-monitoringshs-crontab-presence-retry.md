---
id: bt-30a0
title: test-monitoring.sh's crontab-presence retry budget (bt-d30a fix) is still insufficient under
  heavier concurrent load
status: claimed
priority: p3
tags:
  - ops
  - flaky-test
created: 2026-08-29
claim:
  owner: capacity-engine
  at: 2026-09-01T12:12:57Z
---

bt-d30a added a 5x0.5s retry to test-monitoring.sh's crontab-presence check for exactly this race. During bt-7964 (2026-08-29) it still produced spurious FAIL on 2 of 3 back-to-back full-suite runs (different monitor name each time -- fallback-cert, renew-wildcard-cert, audit-domains -- so not one flaky pattern), then passed clean on the 3rd/4th retry of the whole suite. The retry budget or its backoff may need to grow, or the check may need to diff against a known-good snapshot instead of polling. Not reopening bt-d30a since its original fix and evidence are still valid for the scenario it was closed against; this is reporting that the same class of contention still bites at today's box load.

## Log
- 2026-09-01 claimed by capacity-engine
