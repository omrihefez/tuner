---
id: bt-4ee7
title: sw.js cache-first branch has no offline fallback, so an uncached same-origin asset rejects
  respondWith when the network is down
status: claimed
priority: p3
tags:
  - pwa
  - correctness
created: 2026-07-30
claim:
  owner: capacity-engine
  at: 2026-08-01T08:54:32Z
---

sw.js lines 51-59: the non-app-shell branch is caches.match(request).then(r to r or fetch(request)...) with NO .catch(). The app-shell branch immediately above (lines 38-48) DOES catch and falls back to the cached copy or /index.html. So the two branches are asymmetric: offline plus a same-origin asset that is not in the ASSETS install list produces a rejected respondWith and a hard network error for that subresource, instead of a graceful failure. Today ASSETS covers every shipped root file, so this is latent rather than user-visible, but it fires the first time any new image, font or asset ships without being added to ASSETS. DONE WHEN: the cache-first branch has a catch that mirrors the app-shell branch, and test/sw.test.js (via test/sw-harness.js) gains a case asserting an uncached same-origin asset with a failing network resolves rather than rejects.

## Log
- 2026-08-01 claimed by capacity-engine
