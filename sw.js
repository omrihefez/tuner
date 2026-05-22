// Service worker — offline shell + version-controlled cache.
// Bumping CACHE invalidates the old cache; the update-prompt in tuner.js shows
// the user a "Reload" toast when this happens so they pick up new code.
const CACHE = "tuner-v4";
const ASSETS = ["/", "/index.html", "/style.css", "/tuner.js", "/manifest.json", "/about.html", "/privacy.html", "/icon-192.png", "/icon-512.png"];

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

self.addEventListener("fetch", (e) => {
  if (e.request.method !== "GET") return;
  e.respondWith(
    caches.match(e.request).then(r => r || fetch(e.request).then(resp => {
      const respClone = resp.clone();
      if (resp.ok && new URL(e.request.url).origin === location.origin) {
        caches.open(CACHE).then(c => c.put(e.request, respClone));
      }
      return resp;
    }))
  );
});
