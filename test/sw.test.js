// Tests for the service worker's caching strategy (sw.js).
//
// bt-314a: HTML/JS must be network-first so a deploy is visible on the very
// next load, instead of silently serving whatever was cached at install time
// until someone remembers to bump CACHE. Other static assets stay cache-first.
// Run with:  npm test   (== node --test test/)

const { test } = require("node:test");
const assert = require("node:assert/strict");
const { loadSW, dispatchFetch, flushMicrotasks } = require("./sw-harness.js");

function okResponse(body) {
  return { ok: true, clone() { return this; }, body };
}

// A response that RESOLVED (no network/DNS/TLS failure) but with a failing
// HTTP status — a 500/502/503 from the host, or a 404 from a broken deploy
// alias. Must not be confused with fetchImpl rejecting.
function notOkResponse(body, status = 500) {
  return { ok: false, status, clone() { return this; }, body };
}

// -----------------------------------------------------------------------------
// App shell (navigation / .html / .js) — network-first
// -----------------------------------------------------------------------------

test("navigation request: network is tried before cache, and wins when online", async () => {
  const { listeners, fetchCalls, cacheMatchCalls, cachePutCalls } = loadSW({
    fetchImpl: () => Promise.resolve(okResponse("fresh-index")),
    cacheMatchImpl: () => okResponse("stale-index"),
  });

  const { called, responsePromise } = dispatchFetch(listeners, {
    method: "GET",
    url: "https://test.local/",
    mode: "navigate",
  });
  assert.equal(called, true);

  const resp = await responsePromise;
  assert.equal(resp.body, "fresh-index", "must serve the network response, not the cache, when online");
  assert.deepEqual(fetchCalls, ["https://test.local/"]);
  assert.deepEqual(cacheMatchCalls, [], "cache must not even be consulted when the network succeeds");

  await flushMicrotasks();
  assert.deepEqual(cachePutCalls, ["https://test.local/"], "the fresh response should be cached for offline fallback");
});

test(".js request: network-first, same as navigation", async () => {
  const { listeners, fetchCalls, cacheMatchCalls } = loadSW({
    fetchImpl: () => Promise.resolve(okResponse("fresh-tuner-js")),
    cacheMatchImpl: () => okResponse("stale-tuner-js"),
  });

  const { responsePromise } = dispatchFetch(listeners, {
    method: "GET",
    url: "https://test.local/tuner.js",
    mode: "same-origin",
  });

  const resp = await responsePromise;
  assert.equal(resp.body, "fresh-tuner-js");
  assert.deepEqual(fetchCalls, ["https://test.local/tuner.js"]);
  assert.deepEqual(cacheMatchCalls, []);
});

test(".html request (non-navigation, e.g. prefetch): also network-first", async () => {
  const { listeners, fetchCalls } = loadSW({
    fetchImpl: () => Promise.resolve(okResponse("fresh-about")),
  });

  const { responsePromise } = dispatchFetch(listeners, {
    method: "GET",
    url: "https://test.local/about.html",
    mode: "same-origin",
  });

  const resp = await responsePromise;
  assert.equal(resp.body, "fresh-about");
  assert.deepEqual(fetchCalls, ["https://test.local/about.html"]);
});

test("navigation request offline: falls back to the cached page", async () => {
  const { listeners, fetchCalls } = loadSW({
    fetchImpl: () => Promise.reject(new Error("offline")),
    cacheMatchImpl: (url) => (url.endsWith("/index.html") || url === "https://test.local/" ? okResponse("cached-index") : undefined),
  });

  const { responsePromise } = dispatchFetch(listeners, {
    method: "GET",
    url: "https://test.local/",
    mode: "navigate",
  });

  const resp = await responsePromise;
  assert.equal(resp.body, "cached-index", "must fall back to the offline shell when the network fails");
  assert.deepEqual(fetchCalls, ["https://test.local/"]);
});

// -----------------------------------------------------------------------------
// Resolved-but-not-ok responses (bt-3143) — a 5xx or a bad-deploy 404 that
// RESOLVES must not be handed straight to the page just because it isn't a
// fetch() rejection; it should fall back to a cached copy the same way an
// actual offline rejection does, but only when there IS a cached copy.
// -----------------------------------------------------------------------------

test("navigation request: resolved 500 falls back to the cached page instead of being served", async () => {
  const { listeners, fetchCalls } = loadSW({
    fetchImpl: () => Promise.resolve(notOkResponse("host-error-page", 500)),
    cacheMatchImpl: (url) => (url === "https://test.local/" ? okResponse("cached-index") : undefined),
  });

  const { responsePromise } = dispatchFetch(listeners, {
    method: "GET",
    url: "https://test.local/",
    mode: "navigate",
  });

  const resp = await responsePromise;
  assert.equal(resp.body, "cached-index", "a resolved 500 must not be served when a good cached copy exists");
  assert.deepEqual(fetchCalls, ["https://test.local/"]);
});

test("navigation request: resolved 500 with nothing cached still returns the real error, not the offline shell", async () => {
  const { listeners } = loadSW({
    fetchImpl: () => Promise.resolve(notOkResponse("host-error-page", 500)),
    cacheMatchImpl: () => undefined,
  });

  const { responsePromise } = dispatchFetch(listeners, {
    method: "GET",
    url: "https://test.local/",
    mode: "navigate",
  });

  const resp = await responsePromise;
  assert.equal(resp.body, "host-error-page", "with nothing cached there is nothing to fall back to — the real response must pass through");
});

test("navigation request: resolved 404 for a genuinely missing page is NOT masked by the /index.html shell", async () => {
  const { listeners } = loadSW({
    fetchImpl: () => Promise.resolve(notOkResponse("real-404-page", 404)),
    // /index.html IS cached, but the requested page itself is not — a real
    // routing 404 must still surface, not be hidden behind the app shell.
    cacheMatchImpl: (url) => (url.endsWith("/index.html") ? okResponse("cached-index") : undefined),
  });

  const { responsePromise } = dispatchFetch(listeners, {
    method: "GET",
    url: "https://test.local/no-such-route",
    mode: "navigate",
  });

  const resp = await responsePromise;
  assert.equal(resp.body, "real-404-page", "a genuinely missing route must not be masked by the cached offline shell");
});

test("non-shell asset: resolved 500 on a re-fetch falls back to a copy that appeared in cache in the meantime", async () => {
  let matchCalls = 0;
  const { listeners, fetchCalls } = loadSW({
    fetchImpl: () => Promise.resolve(notOkResponse("host-error-page", 500)),
    cacheMatchImpl: (url) => {
      matchCalls += 1;
      // First check (before the fetch) misses, which is what triggers the
      // fetch at all; the second check (after the resolved-not-ok response)
      // finds a copy — e.g. populated by a concurrent request in between.
      return matchCalls > 1 ? okResponse("cached-style") : undefined;
    },
  });

  const { responsePromise } = dispatchFetch(listeners, {
    method: "GET",
    url: "https://test.local/style.css",
    mode: "same-origin",
  });

  const resp = await responsePromise;
  assert.equal(resp.body, "cached-style", "a resolved 500 must not be served once a cached copy is available");
  assert.deepEqual(fetchCalls, ["https://test.local/style.css"]);
});

test("non-shell asset: resolved 500 with nothing ever cached still returns the real error", async () => {
  const { listeners } = loadSW({
    fetchImpl: () => Promise.resolve(notOkResponse("host-error-page", 500)),
    cacheMatchImpl: () => undefined,
  });

  const { responsePromise } = dispatchFetch(listeners, {
    method: "GET",
    url: "https://test.local/new-icon.png",
    mode: "same-origin",
  });

  const resp = await responsePromise;
  assert.equal(resp.body, "host-error-page", "with nothing cached there is nothing to fall back to — the real response must pass through");
});

// -----------------------------------------------------------------------------
// Everything else (css/images/manifest) — still cache-first
// -----------------------------------------------------------------------------

test("non-shell asset (css): cache hit short-circuits, network is never touched", async () => {
  const { listeners, fetchCalls, cacheMatchCalls } = loadSW({
    cacheMatchImpl: () => okResponse("cached-style"),
  });

  const { responsePromise } = dispatchFetch(listeners, {
    method: "GET",
    url: "https://test.local/style.css",
    mode: "same-origin",
  });

  const resp = await responsePromise;
  assert.equal(resp.body, "cached-style");
  assert.deepEqual(cacheMatchCalls, ["https://test.local/style.css"]);
  assert.deepEqual(fetchCalls, [], "network must not be hit when the cache already has the asset");
});

test("non-shell asset (css): cache miss falls back to network and populates the cache", async () => {
  const { listeners, fetchCalls, cachePutCalls } = loadSW({
    fetchImpl: () => Promise.resolve(okResponse("network-style")),
    cacheMatchImpl: () => undefined,
  });

  const { responsePromise } = dispatchFetch(listeners, {
    method: "GET",
    url: "https://test.local/style.css",
    mode: "same-origin",
  });

  const resp = await responsePromise;
  assert.equal(resp.body, "network-style");
  assert.deepEqual(fetchCalls, ["https://test.local/style.css"]);

  await flushMicrotasks();
  assert.deepEqual(cachePutCalls, ["https://test.local/style.css"]);
});

test("non-shell asset not in cache, offline: resolves via the offline shell fallback instead of rejecting", async () => {
  const { listeners } = loadSW({
    fetchImpl: () => Promise.reject(new Error("offline")),
    cacheMatchImpl: (url) => (url.endsWith("/index.html") ? okResponse("cached-index") : undefined),
  });

  const { called, responsePromise } = dispatchFetch(listeners, {
    method: "GET",
    url: "https://test.local/new-icon.png",
    mode: "same-origin",
  });
  assert.equal(called, true);

  await assert.doesNotReject(responsePromise, "an uncached asset with a failing network must resolve, not reject respondWith");
  const resp = await responsePromise;
  assert.equal(resp.body, "cached-index", "falls back to the offline shell, mirroring the app-shell branch");
});

// -----------------------------------------------------------------------------
// Requests the fetch handler must ignore entirely
// -----------------------------------------------------------------------------

test("non-GET requests are ignored (no respondWith call)", () => {
  const { listeners } = loadSW({});
  const { called } = dispatchFetch(listeners, {
    method: "POST",
    url: "https://test.local/tuner.js",
    mode: "same-origin",
  });
  assert.equal(called, false);
});

test("cross-origin requests are ignored (no respondWith call)", () => {
  const { listeners, fetchCalls, cacheMatchCalls } = loadSW({});
  const { called } = dispatchFetch(listeners, {
    method: "GET",
    url: "https://cdn.example.com/lib.js",
    mode: "same-origin",
  });
  assert.equal(called, false);
  assert.deepEqual(fetchCalls, []);
  assert.deepEqual(cacheMatchCalls, []);
});
