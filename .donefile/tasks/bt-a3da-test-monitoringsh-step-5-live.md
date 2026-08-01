---
id: bt-a3da
title: test-monitoring.sh step 5 (live crontab scan) is intermittently flaky on the shared box
status: open
priority: p3
tags:
  - ops
  - tests
created: 2026-08-01
---

Reported by the bt-3f5a worker: a different monitor line is missing on each run, the crontab hash is unchanged before and after, and it reproduces against the untouched pre-existing main checkout — so it is not caused by any installer change. Likely a race between the test reading the live crontab and the fleet's other crontab writers on a shared box.

A flaky test in the monitoring suite is worse than an absent one: it trains whoever runs it to re-run until green, which is exactly how a real regression gets waved through. Either make step 5 read a snapshot rather than the live crontab, or drop it from the suite and cover the behaviour hermetically.
