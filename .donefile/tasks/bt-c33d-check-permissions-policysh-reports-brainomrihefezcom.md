---
id: bt-c33d
title: check-permissions-policy.sh reports brain.omrihefez.com as UNPINNED after sb-6f36 added the header
status: done
priority: p3
tags:
  - http-headers
created: 2026-10-11
filed:
  owner: meni-worker/brain-omrihefez-com-send-4713d1
  at: 2026-10-11T18:56:54Z
done:
  at: 2026-10-11T19:08:59Z
  by: capacity-engine/worker
evidence:
  - type: commit
    value: 5757a93
    verified: 2026-10-11T19:08:59Z
  - type: test
    cmd: PP_HOSTS="brain" bash scripts/check-permissions-policy.sh | grep -c
      '^OK     brain.omrihefez.com' >/dev/null
    exit: 0
    at: 2026-10-11T19:08:59Z
    log: evidence/bt-c33d-2026-10-11T19-08-59Z-test.txt
    sha256: e21c715fce2c29831bcaa79bc65a2f3c00477c0a99ace9e319f37bb7ecddbc8c
    bytes: 112
---

## Log
- 2026-10-11 sb-6f36 (second-brain) shipped brain.omrihefez.com sending Permissions-Policy: camera=(), microphone=(), geolocation=() -- the estate baseline, matching house/meni/planner/tik/oauth in this script's own EXPECTED_PP map. This script has no EXPECTED_PP[brain] entry, so it now reports UNPINNED instead of OK.

Repro: PP_HOSTS="brain" bash scripts/check-permissions-policy.sh -> exit 1, 'UNPINNED brain.omrihefez.com -> sends Permissions-Policy: camera=(), microphone=(), geolocation=() but nobody recorded an expected value for it in this script'.

Fix: add
  [brain]="camera=(), microphone=(), geolocation=()"  # estate baseline, grants nothing
to EXPECTED_PP in scripts/check-permissions-policy.sh.

DONE WHEN: PP_HOSTS="brain" bash scripts/check-permissions-policy.sh exits 0 and prints 'OK     brain.omrihefez.com -> ...'.
- 2026-10-11 claimed by capacity-engine
- 2026-10-11 done by capacity-engine/worker — commit 5757a93, test `PP_HOSTS="brain" bash scripts/check-permissions-policy.sh | grep -c '^OK     brain.omrihefez.com' >/dev/null` exit 0 (log: evidence/bt-c33d-2026-10-11T19-08-59Z-test.txt)
