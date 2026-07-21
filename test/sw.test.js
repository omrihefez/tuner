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
