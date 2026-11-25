---
id: bt-281c
title: "bass-tuner monitors failing after VPS self-host move: unregistered-live-hosts, csp-strength,
  permissions-policy, stale-deploy"
status: open
priority: p2
tags:
  - from-brief
created: 2026-11-25
filed:
  owner: morning-brief
  at: 2026-11-25T07:07:04Z
---

Inbox notes 2026-11-24/25 show four bass-tuner monitors failed (unregistered-live-hosts, csp-strength, permissions-policy, stale-deploy) after bass moved off paused Vercel to the VPS. Find root cause (likely missing headers/host registry on the self-hosted origin), fix, and done-when all four monitors pass against https://bass.omrihefez.com. Check board first for existing oncall tasks.

Filed by the morning brief's intake pass.
