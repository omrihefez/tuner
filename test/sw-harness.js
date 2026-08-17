// Test harness for the service worker (sw.js).
//
// sw.js runs in a service-worker global scope, not Node. To unit-test the
// ACTUAL shipped fetch strategy (no re-implementation, no copy) we evaluate
// the real sw.js source inside a `vm` sandbox that stubs just enough of the
// SW global scope (self/caches/fetch/location) to run its top-level
// addEventListener wiring, then hand the registered listeners back out so
// tests can invoke them directly with fake FetchEvents.

const fs = require("node:fs");
const path = require("node:path");
const vm = require("node:vm");

const SW_PATH = path.join(__dirname, "..", "sw.js");

// Loads sw.js fresh into an isolated sandbox. `fetchImpl(request)` and
// `cacheMatchImpl(request)` let each test control network/cache responses;
// every call to fetch() or cache.match()/put() is recorded for assertions.
function loadSW({ fetchImpl, cacheMatchImpl } = {}) {
  const listeners = {};
  const selfStub = {
    addEventListener(type, fn) {
      (listeners[type] = listeners[type] || []).push(fn);
    },
    skipWaiting() {},
    clients: { claim() {} },
  };

  const fetchCalls = [];
  const cacheMatchCalls = [];
  const cachePutCalls = [];

  const fakeCache = {
    match(req) {
      cacheMatchCalls.push(req.url || req);
      return Promise.resolve(cacheMatchImpl ? cacheMatchImpl(req.url || req) : undefined);
    },
    put(req, resp) {
      cachePutCalls.push(req.url || req);
      return Promise.resolve();
    },
    addAll() {
      return Promise.resolve();
    },
  };

  const cachesStub = {
    open() {
      return Promise.resolve(fakeCache);
    },
    match(req) {
      return fakeCache.match(req);
    },
    keys() {
      return Promise.resolve(["tuner-v9"]);
    },
    delete() {
      return Promise.resolve(true);
    },
  };

  const fetchStub = (req) => {
    fetchCalls.push(req.url || req);
    if (fetchImpl) return fetchImpl(req);
    return Promise.reject(new Error("no fetchImpl provided"));
  };

  const sandbox = {
    self: selfStub,
    caches: cachesStub,
    fetch: fetchStub,
    location: { origin: "https://test.local" },
    URL,
    console,
    Promise,
  };
  sandbox.globalThis = sandbox;
  vm.createContext(sandbox);

  const source = fs.readFileSync(SW_PATH, "utf8");
  vm.runInContext(source, sandbox, { filename: "sw.js" });

  return { listeners, fetchCalls, cacheMatchCalls, cachePutCalls };
}

// Fires the registered "fetch" listener with a fake FetchEvent and returns
// whatever it passed to respondWith() (the fetch handler always calls it
// synchronously for GET same-origin requests).
function dispatchFetch(listeners, request) {
  const handler = listeners.fetch && listeners.fetch[0];
  if (!handler) throw new Error("no fetch listener registered");
  let responded;
  let called = false;
  handler({
    request,
    respondWith(p) {
      called = true;
      responded = p;
    },
  });
  return { called, responsePromise: responded };
}

// Flushes pending microtasks (fire-and-forget cache.put() calls aren't
// awaited by the fetch handler itself) so assertions on cachePutCalls are
// stable instead of racy.
async function flushMicrotasks(times = 5) {
  for (let i = 0; i < times; i++) await Promise.resolve();
}

module.exports = { loadSW, dispatchFetch, flushMicrotasks };
