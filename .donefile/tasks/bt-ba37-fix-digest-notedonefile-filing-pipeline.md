---
id: bt-ba37
title: 'Fix digest-note→donefile filing pipeline dropping note body, using the "filed as" annotation
  as the title instead (repro: bt-f81f / dn-4ab9)'
status: done
priority: p2
tags:
  - donefile
  - capacity-engine
created: 2026-07-25
done:
  at: 2026-07-25T03:34:36Z
  by: capacity-engine/worker
evidence:
  - type: commit
    value: afcf8e4
    repo: capacity-engine
    verified: 2026-07-25T03:34:36Z
  - type: test
    cmd: cd /home/omri/projects/capacity-engine && node test.mjs
    exit: 0
    at: 2026-07-25T03:34:35Z
    log: evidence/bt-ba37-2026-07-25T03-34-35Z-test.txt
    sha256: 39b9f2e9a129b109135885ed35b375e484b160de56a7205bccd53fb0ffdbffbe
    bytes: 79
---

## Log
- 2026-07-25 claimed by capacity-engine
- 2026-07-25 done by capacity-engine/worker — commit afcf8e4 (capacity-engine), test `cd /home/omri/projects/capacity-engine && node test.mjs` exit 0 (log: evidence/bt-ba37-2026-07-25T03-34-35Z-test.txt)
