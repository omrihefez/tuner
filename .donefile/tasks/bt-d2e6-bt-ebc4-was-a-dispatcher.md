---
id: bt-d2e6
title: bt-ebc4 was a dispatcher duplicate of bt-a66f (same fix, same commit) — same class of issue
  as bt-6307 (bt-b898/bt-86e6 dup); worth tightening dedup so perf tasks with overlapping
  descriptions don't get claimed twice
status: done
priority: p3
tags:
  - tooling
  - donefile
created: 2026-07-21
done:
  at: 2026-07-23T19:47:01Z
  by: capacity-engine/worker
evidence:
  - type: commit
    value: 4b15111
    repo: /home/omri/projects/capacity-engine
    verified: 2026-07-23T19:47:01Z
  - type: test
    cmd: cd /home/omri/projects/capacity-engine && node test.mjs
    exit: 0
    at: 2026-07-23T19:47:01Z
    log: evidence/bt-d2e6-2026-07-23T19-47-01Z-test.txt
    sha256: 39b9f2e9a129b109135885ed35b375e484b160de56a7205bccd53fb0ffdbffbe
    bytes: 79
---

## Log
- 2026-07-23 claimed by capacity-engine
- 2026-07-23 released by capacity-engine
- 2026-07-23 claimed by capacity-engine
- 2026-07-23 released by capacity-engine
- 2026-07-23 claimed by capacity-engine
- 2026-07-23 done by capacity-engine/worker — commit 4b15111 (/home/omri/projects/capacity-engine), test `cd /home/omri/projects/capacity-engine && node test.mjs` exit 0 (log: evidence/bt-d2e6-2026-07-23T19-47-01Z-test.txt)
