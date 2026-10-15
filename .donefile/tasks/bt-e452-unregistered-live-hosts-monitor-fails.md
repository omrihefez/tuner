---
id: bt-e452
title: unregistered-live-hosts monitor fails daily — cron PATH can't find vercel binary
status: claimed
priority: p3
tags:
  - from-brief
created: 2026-10-15
filed:
  owner: morning-brief
  at: 2026-10-15T06:07:02Z
claim:
  owner: capacity-engine
  at: 2026-10-15T06:14:25Z
---

scripts/check-unregistered-live-hosts.sh (added 2026-10-14, bt-1af4) has exited non-zero (CANNOT RUN) on every 06:21 cron run since it shipped, both 2026-10-14 and 2026-10-15 — the second day was only suppressed from the inbox digest by the alert-latch deduping identical output, not because it passed. Root cause confirmed by hand: the script shells out to a bare `vercel`, but cron's PATH (/usr/local/sbin:...:/bin) doesn't include ~/.bun/bin or ~/.local/bin, where the binary actually lives — `vercel whoami` works fine once that's added to PATH manually. Fix the script to resolve vercel via an explicit path or export the needed PATH additions at the top of the script, so cron can run it standalone. Done when: the next 06:21 cron run exits 0 or 1 (never 2/CANNOT RUN) without any manual PATH help.

Filed by the morning brief's intake pass.

## Log
- 2026-10-15 claimed by capacity-engine
