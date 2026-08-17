---
id: bt-6307
title: "Dedup dispatcher: bt-b898 and bt-86e6 were the same work dispatched twice"
status: done
priority: p3
tags:
  - tooling
  - donefile
created: 2026-07-14
done:
  at: 2026-07-23T05:51:41Z
  by: capacity-engine/worker
evidence:
  - type: commit
    value: d928867
    repo: /home/omri/projects/capacity-engine
    verified: 2026-07-23T05:50:47Z
  - type: test
    cmd: node test.mjs
    exit: 1
    at: 2026-07-23T05:50:47Z
    log: evidence/bt-6307-2026-07-23T05-50-47Z-test.txt
    sha256: 714dc22ede2626e38f09841c8f1de7d29c5db45e2e7e2fb763786c0da72acbda
    bytes: 761
  - type: commit
    value: d928867
    repo: /home/omri/projects/capacity-engine
    verified: 2026-07-23T05:51:41Z
  - type: test
    cmd: cd /home/omri/projects/capacity-engine && node test.mjs
    exit: 0
    at: 2026-07-23T05:51:41Z
    log: evidence/bt-6307-2026-07-23T05-51-41Z-test.txt
    sha256: 39b9f2e9a129b109135885ed35b375e484b160de56a7205bccd53fb0ffdbffbe
    bytes: 79
---

## Log
- 2026-07-23 claimed by capacity-engine
- 2026-07-23 done by capacity-engine/worker — commit d928867 (/home/omri/projects/capacity-engine)
- 2026-07-23 reopened (was done)
- 2026-07-23 claimed by capacity-engine/worker
- 2026-07-23 done by capacity-engine/worker — commit d928867 (/home/omri/projects/capacity-engine), test `cd /home/omri/projects/capacity-engine && node test.mjs` exit 0 (log: evidence/bt-6307-2026-07-23T05-51-41Z-test.txt)
