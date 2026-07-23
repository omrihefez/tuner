// Service worker — offline shell + version-controlled cache.
// HTML/JS use network-first (see isAppShell below) so a deploy is live on the
// very next load instead of waiting on a manual CACHE bump; other static
// assets stay cache-first. The update-prompt in tuner.js still shows a
// "Reload" toast when the SW script itself changes.
const CACHE = "tuner-v10";
const ASSETS = ["/", "/index.html", "/style.css", "/tuner.js", "/manifest.json", "/about.html", "/privacy.html", "/icon-192.png", "/icon-512.png", "/favicon.png"];

self.addEventListener("install", (e) => {
  e.waitUntil(caches.open(CACHE).then((c) => c.addAll(ASSETS)));
  // Don't auto-skipWaiting — let the user trigger the reload via the toast.
});

// Allow page to force the new SW to take over when the user clicks the toast.
self.addEventListener("message", (e) => {
  if (e.data && e.data.type === "SKIP_WAITING") self.skipWaiting();
});

self.addEventListener("activate", (e) => {
  e.waitUntil(caches.keys().then(keys =>
    Promise.all(keys.filter(k => k !== CACHE).map(k => caches.delete(k)))
  ));
  self.clients.claim();
});

// Navigations and .js requests are the app shell — always try the network
// first so a fresh deploy shows up immediately, falling back to the cached
// copy only when offline.
function isAppShell(request) {
  if (request.mode === "navigate") return true;
  return request.url.endsWith(".html") || request.url.endsWith(".js");
}

self.addEventListener("fetch", (e) => {
  if (e.request.method !== "GET") return;
  if (new URL(e.request.url).origin !== location.origin) return;

  if (isAppShell(e.request)) {
    e.respondWith(
      fetch(e.request).then(resp => {
        if (resp.ok) {
          const respClone = resp.clone();
          caches.open(CACHE).then(c => c.put(e.request, respClone));
        }
        return resp;
      }).catch(() => caches.match(e.request).then(r => r || caches.match("/index.html")))
    );
    return;
  }

  e.respondWith(
    caches.match(e.request).then(r => r || fetch(e.request).then(resp => {
      if (resp.ok) {
        const respClone = resp.clone();
        caches.open(CACHE).then(c => c.put(e.request, respClone));
      }
      return resp;
    }))
  );
});
