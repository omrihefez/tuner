---
id: bt-8db5
title: Diagnostic log ships in production DOM and echoes full User-Agent
status: done
priority: p3
tags:
  - polish
created: 2026-07-14
done:
  at: 2026-07-23T06:00:25Z
  by: capacity-engine/worker
evidence:
  - type: commit
    value: 7a768aa
    verified: 2026-07-23T06:00:25Z
  - type: test
    cmd: npm test
    exit: 0
    at: 2026-07-23T06:00:24Z
    log: evidence/bt-8db5-2026-07-23T06-00-24Z-test.txt
    sha256: a10e17e5df2fe704fe29b514cb9e8fa97e2b6c45f421ed56878b8a24e0b430ef
    bytes: 16763
---

tuner.js:529-541 renders a persistent <pre id='diag-log'> (index.html:72-75) that logs protocol/host and the full navigator.userAgent on every load, plus mic/SW events. It was added to debug a past mobile mic-prompt issue but now ships to all users as permanent DOM/log clutter (and echoes the UA back into the page). Fix: gate the diagnostic panel behind a ?debug flag or localStorage toggle, or remove it now that the mic flow is stable.

## Log
- 2026-07-23 claimed by capacity-engine
- 2026-07-23 done by capacity-engine/worker — commit 7a768aa, test `npm test` exit 0 (log: evidence/bt-8db5-2026-07-23T06-00-24Z-test.txt)
