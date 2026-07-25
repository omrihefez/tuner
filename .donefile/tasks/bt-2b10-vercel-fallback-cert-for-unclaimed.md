---
id: bt-2b10
title: Vercel fallback cert for unclaimed omrihefez.com subdomains has expired — TLS hard-fails
  instead of clean 404 (e.g. composer.omrihefez.com)
status: done
priority: p3
tags:
  - vercel
  - tls
created: 2026-07-24
done:
  at: 2026-07-25T05:47:14Z
  by: capacity-engine/worker
evidence:
  - type: commit
    value: 5a43c15
    verified: 2026-07-25T05:47:14Z
  - type: test
    cmd: bash scripts/check-fallback-cert.sh
    exit: 0
    at: 2026-07-25T05:47:14Z
    log: evidence/bt-2b10-2026-07-25T05-47-14Z-test.txt
    sha256: e2b992714676dcd0250862450effb41677ca6e11e6d66ed0001242dc1c6987fc
    bytes: 109
---

## Log
- 2026-07-25 claimed by capacity-engine
- 2026-07-25 done by capacity-engine/worker — commit 5a43c15, test `bash scripts/check-fallback-cert.sh` exit 0 (log: evidence/bt-2b10-2026-07-25T05-47-14Z-test.txt)
