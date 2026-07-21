---
id: bt-ebc4
title: Downsample/22.05kHz AudioContext to halve YIN CPU
status: done
priority: p2
tags:
  - perf
created: 2026-07-14
done:
  at: 2026-07-21T22:04:09Z
  by: capacity-engine/worker
evidence:
  - type: commit
    value: 8561b5c74dab3100f1a3c48086d214f8bc579cec
    verified: 2026-07-21T22:04:09Z
  - type: test
    cmd: npm test
    exit: 0
    at: 2026-07-21T22:04:08Z
    log: evidence/bt-ebc4-2026-07-21T22-04-08Z-test.txt
    sha256: b5754c3135f5debf1fa190726998bfdd8300fa8429b50a0f0ba2f044e6707fad
    bytes: 7947
---

## Log
- 2026-07-21 claimed by capacity-engine
- 2026-07-21 done by capacity-engine/worker — commit 8561b5c74dab, test `npm test` exit 0 (log: evidence/bt-ebc4-2026-07-21T22-04-08Z-test.txt)
