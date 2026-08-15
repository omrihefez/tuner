---
id: bt-3143
title: Service worker falls back to cache only when fetch REJECTS, so a 5xx or a bad-deploy 404 is
  served to the user instead of the working cached copy
status: claimed
priority: p2
tags:
  - bug
  - pwa
  - offline
created: 2026-08-15
claim:
  owner: capacity-engine
  at: 2026-08-15T15:00:12Z
---

sw.js's offline fallback is wired to fetch REJECTION only, so an HTTP error response is
served straight to the user even though a good cached copy exists.

THE CODE (sw.js:38-49, the app-shell / network-first branch):

    if (isAppShell(e.request)) {
      e.respondWith(
        fetch(e.request).then(resp => {
          if (resp.ok) {
            const respClone = resp.clone();
            caches.open(CACHE).then(c => c.put(e.request, respClone));
          }
          return resp;                                   // <-- non-ok returned as-is
        }).catch(() => caches.match(e.request).then(r => r || caches.match("/index.html")))
      );
      return;
    }

`fetch()` only rejects when the request never completes — no network, DNS failure, TLS
failure. A response that arrives with a failing status (500, 502, 503, or a 404 from a
broken deploy/alias) RESOLVES, so `.catch()` never runs, `resp.ok` is false so it is
correctly not cached, and then it is returned to the page anyway. The user gets the host
error page instead of the perfectly good `tuner.js` / `index.html` already in `CACHE`.
The identical hole is in the cache-first branch at sw.js:51-59 for a non-shell asset that
missed the cache.

For a PWA whose entire selling point is that it keeps working, any transient 5xx from the
host or a moment of deploy-alias drift produces "the tuner stopped working" on a device
that had everything it needed cached locally.

THIS IS UNTESTED, NOT INTENTIONAL. test/sw.test.js has two offline tests
("navigation request offline", "non-shell asset not in cache, offline") and BOTH simulate
failure the same single way:

    fetchImpl: () => Promise.reject(new Error("offline"))

Its helper only builds `okResponse(body)` with `ok: true` — there is no fixture for a
resolved-but-not-ok response anywhere in the file, so no test asserts what happens on a
500. The comment at sw.js:26-28 says "falling back to the cached copy only when offline",
which describes the reject path and does not appear to be a deliberate decision to pass
5xx through.

Filed as its own defect, not as a diagnosis of bt-b7e7 ("Tuner stopped working on his
device — server, deploy and code all verified healthy, cause is client-side", still open):
nothing here proves that is what he hit. But it is a live client-side path in which a
briefly-unhealthy server yields a broken app on a device with a working cache, while the
server later verifies healthy — which is that report's exact shape, and it is worth
closing regardless of whether it turns out to be the cause.

DONE WHEN: both fetch branches in sw.js fall back to the cached copy when the response
resolves with `ok === false` (not just when the fetch rejects), and still return the real
response when there is nothing cached to fall back to — a 404 for a genuinely missing page
must not be masked by the offline shell in a way that hides a real routing bug; and
test/sw.test.js gains a resolved-non-ok fixture covering both branches.

VERIFY: `cd /home/omri/projects/bass-tuner && node --test test/sw.test.js` green, with new
cases asserting the 500 path serves the cached body.

## Log
- 2026-08-15 claimed by capacity-engine
