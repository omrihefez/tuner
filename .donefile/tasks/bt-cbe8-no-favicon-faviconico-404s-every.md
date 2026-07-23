---
id: bt-cbe8
title: "No favicon: /favicon.ico 404s every load, no tab/home-screen icon"
status: done
priority: p3
tags:
  - ux
created: 2026-07-14
done:
  at: 2026-07-23T06:17:36Z
  by: capacity-engine/worker
evidence:
  - type: commit
    value: f5e5208
    verified: 2026-07-23T06:17:36Z
  - type: test
    cmd: npm test
    exit: 0
    at: 2026-07-23T06:17:36Z
    log: evidence/bt-cbe8-2026-07-23T06-17-36Z-test.txt
    sha256: 5b8137431dc10b52a63c3dc9401b65b4d5ea5b0710e51a0682a627536b079cca
    bytes: 16761
  - type: live
    cmd: curl -sf https://bass.omrihefez.com/ | grep -q 'rel="icon" href="/favicon.png"'
    exit: 0
    at: 2026-07-23T06:17:36Z
    log: evidence/bt-cbe8-2026-07-23T06-17-36Z-live.txt
    sha256: d4a21f472e8b4b9fa2a6119c5bb0b17fb2551665e9f0e7874804347bf73953ec
    bytes: 83
---

index.html/about.html/privacy.html have NO <link rel='icon'> (grep clean). favicon.png exists in the repo root but is unreferenced and is NOT in the SW ASSETS list (sw.js:5), so it is not even cached offline. Result: browsers request /favicon.ico -> 404 on every fresh load; no favicon in the tab. Fix: add <link rel='icon' href='/favicon.png'> (and an .ico or apple-touch-icon as desired) to all three pages and add favicon.png to sw.js ASSETS.

## Log
- 2026-07-23 claimed by capacity-engine
- 2026-07-23 done by capacity-engine/worker — commit f5e5208, test `npm test` exit 0 (log: evidence/bt-cbe8-2026-07-23T06-17-36Z-test.txt), live `curl -sf https://bass.omrihefez.com/ | grep -q 'rel="icon" href="/favicon.png"'` exit 0 (log: evidence/bt-cbe8-2026-07-23T06-17-36Z-live.txt)
