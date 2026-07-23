---
id: bt-8db5
title: Diagnostic log ships in production DOM and echoes full User-Agent
status: claimed
priority: p3
tags:
  - polish
created: 2026-07-14
claim:
  owner: capacity-engine
  at: 2026-07-23T05:57:23Z
---

tuner.js:529-541 renders a persistent <pre id='diag-log'> (index.html:72-75) that logs protocol/host and the full navigator.userAgent on every load, plus mic/SW events. It was added to debug a past mobile mic-prompt issue but now ships to all users as permanent DOM/log clutter (and echoes the UA back into the page). Fix: gate the diagnostic panel behind a ?debug flag or localStorage toggle, or remove it now that the mic flow is stable.

## Log
- 2026-07-23 claimed by capacity-engine
