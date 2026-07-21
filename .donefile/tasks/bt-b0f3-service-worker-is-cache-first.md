---
id: bt-b0f3
title: Service worker is cache-first for HTML/JS — stale app ships unless CACHE is manually bumped
status: claimed
priority: p2
tags:
  - deploy
created: 2026-07-14
claim:
  owner: capacity-engine/worker
  at: 2026-07-21T21:30:19Z
---

sw.js:24-35 fetch handler is cache-first (caches.match(req).then(r => r || fetch)). index.html and tuner.js are in ASSETS (sw.js:5) so returning users are served the cached copy forever. The update toast (tuner.js:638-646) only fires on 'updatefound', which requires sw.js BYTES to change. So any deploy that updates tuner.js/index.html but forgets to bump CACHE (currently tuner-v8, sw.js:4) is invisible to every returning user. Why wrong: silent stale-app on deploy, easy to forget. Fix: use network-first (or stale-while-revalidate) for navigations + the JS, keep cache-first only for immutable icons; or automate the CACHE bump in the deploy step.

## Log
- 2026-07-21 claimed by capacity-engine/worker
