---
id: bt-5fb7
title: check-sw-cache-bump.js only verifies the git diff at commit time — nothing checks that the
  deployed sw.js CACHE actually matches what shipped
status: done
priority: p2
tags:
  - deploy
  - pwa
created: 2026-08-05
done:
  at: 2026-08-05T06:21:13Z
  by: capacity-engine/worker
evidence:
  - type: commit
    value: 7970cfd206bd666f5081176d21ee5de27e863360
    verified: 2026-08-05T06:21:13Z
  - type: live
    cmd: bash /home/omri/projects/bass-tuner/deploy/activation-probes/probe-bt-5fb7.sh HEAD
    exit: 0
    at: 2026-08-05T06:21:13Z
    expect: PASS
    log: evidence/bt-5fb7-2026-08-05T06-21-13Z-live.txt
    sha256: 24c22de51c8d2ee9c1ff88e8c9b8aa40bcd78303e98c86c5cb52501cf5ae2711
    bytes: 156
---

scripts/check-sw-cache-bump.js fails CI when a cached asset changes without sw.js's CACHE version moving, but it only ever diffs two git refs — it has no way to know what Vercel is actually serving. A deploy that silently failed, or an edge/CDN layer serving a stale build, would leave production's sw.js lagging behind HEAD indefinitely with nothing to catch it (the exact done-is-not-deployed gap bt-a60b named for this board generally, applied to this specific case). DONE WHEN: a live probe script fetches the real deployed sw.js from bass.omrihefez.com, extracts its CACHE version, and compares it against a given git ref's source — passing when they match, failing (with a clear message) when they don't — and is wired as this task's own --live evidence.

## Log
- 2026-08-05 claimed by capacity-engine/worker
- 2026-08-05 done by capacity-engine/worker — commit 7970cfd206bd, live `bash /home/omri/projects/bass-tuner/deploy/activation-probes/probe-bt-5fb7.sh HEAD` exit 0 (--live-expect "PASS") (log: evidence/bt-5fb7-2026-08-05T06-21-13Z-live.txt)
