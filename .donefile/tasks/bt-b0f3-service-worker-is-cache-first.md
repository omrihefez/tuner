---
id: bt-b0f3
title: Service worker is cache-first for HTML/JS — stale app ships unless CACHE is manually bumped
status: done
priority: p2
tags:
  - deploy
created: 2026-07-14
done:
  at: 2026-07-21T21:30:34Z
  by: capacity-engine/worker
evidence:
  - type: commit
    value: abc4695
    verified: 2026-07-21T21:30:34Z
  - type: test
    cmd: npm test
    exit: 0
    at: 2026-07-21T21:30:33Z
    log: evidence/bt-b0f3-2026-07-21T21-30-33Z-test.txt
    sha256: 963bd0cfd6e06bac0c1643c2c415a4c4b90495e768e4e886efd9fb7df2242893
    bytes: 6694
  - type: note
    value: "Duplicate of bt-314a's fix: sw.js fetch handler is now network-first for
      navigations/.js/.html (tuner-v8->v9); covered by test/sw.test.js"
---

sw.js:24-35 fetch handler is cache-first (caches.match(req).then(r => r || fetch)). index.html and tuner.js are in ASSETS (sw.js:5) so returning users are served the cached copy forever. The update toast (tuner.js:638-646) only fires on 'updatefound', which requires sw.js BYTES to change. So any deploy that updates tuner.js/index.html but forgets to bump CACHE (currently tuner-v8, sw.js:4) is invisible to every returning user. Why wrong: silent stale-app on deploy, easy to forget. Fix: use network-first (or stale-while-revalidate) for navigations + the JS, keep cache-first only for immutable icons; or automate the CACHE bump in the deploy step.

## Log
- 2026-07-21 claimed by capacity-engine/worker
- 2026-07-21 done by capacity-engine/worker — commit abc4695, test `npm test` exit 0 (log: evidence/bt-b0f3-2026-07-21T21-30-33Z-test.txt)
