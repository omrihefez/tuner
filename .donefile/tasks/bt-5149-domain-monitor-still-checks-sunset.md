---
id: bt-5149
title: Domain monitor still checks sunset albumclub.omrihefez.com, alarms daily
status: open
priority: p3
tags:
  - from-brief
created: 2026-08-09
---

scripts/audit-domains.sh's SUBS array still includes `albumclub`, so the daily cron (logged to /home/omri/.cache/bass-tuner-domain-audit.log) has produced a `CHECK albumclub.omrihefez.com -> 404` line every day since 2026-08-07. This is a false positive, not a live incident: /home/omri/projects/album-club/README.md (commit 5a777b2/ee2f2ab, 2026-08-07) confirms Album Club was deliberately sunset — Vercel project, DNS records, and the Neon prod DB were all intentionally deleted, code kept archived only. /home/omri/meni/DOMAIN.md (Meni-repo, main-only) still lists albumclub as '🟢 live public -> album-club' on line 24, same stale-registry pattern already fixed once for `tuner` (bt-78e6/bt-66d4) and flagged for meniapp (ma-f497). Done when: audit-domains.sh either drops `albumclub` from SUBS or treats 404 there as expected (same pattern as the already-sunset `apartments` row), DOMAIN.md's albumclub row is updated to reflect the sunset (same shape as the `apartments` row at line 25), and the next cron run produces zero CHECK lines for albumclub.

Filed by the morning brief's intake pass.
