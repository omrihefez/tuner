---
id: bt-c33d
title: check-permissions-policy.sh reports brain.omrihefez.com as UNPINNED after sb-6f36 added the header
status: claimed
priority: p3
tags:
  - http-headers
created: 2026-10-11
filed:
  owner: meni-worker/brain-omrihefez-com-send-4713d1
  at: 2026-10-11T18:56:54Z
claim:
  owner: capacity-engine
  at: 2026-10-11T19:05:39Z
---

## Log
- 2026-10-11 sb-6f36 (second-brain) shipped brain.omrihefez.com sending Permissions-Policy: camera=(), microphone=(), geolocation=() -- the estate baseline, matching house/meni/planner/tik/oauth in this script's own EXPECTED_PP map. This script has no EXPECTED_PP[brain] entry, so it now reports UNPINNED instead of OK.

Repro: PP_HOSTS="brain" bash scripts/check-permissions-policy.sh -> exit 1, 'UNPINNED brain.omrihefez.com -> sends Permissions-Policy: camera=(), microphone=(), geolocation=() but nobody recorded an expected value for it in this script'.

Fix: add
  [brain]="camera=(), microphone=(), geolocation=()"  # estate baseline, grants nothing
to EXPECTED_PP in scripts/check-permissions-policy.sh.

DONE WHEN: PP_HOSTS="brain" bash scripts/check-permissions-policy.sh exits 0 and prints 'OK     brain.omrihefez.com -> ...'.
- 2026-10-11 claimed by capacity-engine
