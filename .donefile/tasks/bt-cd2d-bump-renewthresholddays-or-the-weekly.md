---
id: bt-cd2d
title: Bump RENEW_THRESHOLD_DAYS or the weekly cron cadence if 30d margin ever feels tight vs
  Vercel's own 21d-ish auto-renew window
status: done
priority: p3
tags:
  - vercel
  - tls
  - ops
created: 2026-07-26
done:
  at: 2026-07-31T06:41:05Z
  by: capacity-engine/worker
evidence:
  - type: commit
    value: 11d4f8710de14ec94b8b11e9052623d2eb79b5a2
    verified: 2026-07-31T06:41:05Z
  - type: test
    cmd: bash -n scripts/renew-wildcard-cert.sh
    exit: 0
    at: 2026-07-31T06:41:05Z
    log: evidence/bt-cd2d-2026-07-31T06-41-05Z-test.txt
    sha256: f5f5f7b8ff68121da9de80dea49664d58f438bb3e8c32b9a3052391b699d9627
    bytes: 42
---

## Log
- 2026-07-30 claimed by capacity-engine
- 2026-07-30 released by capacity-engine
- 2026-07-31 claimed by capacity-engine
- 2026-07-31 done by capacity-engine/worker — commit 11d4f8710de1, test `bash -n scripts/renew-wildcard-cert.sh` exit 0 (log: evidence/bt-cd2d-2026-07-31T06-41-05Z-test.txt)
