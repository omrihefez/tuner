// Minimal service worker for PWA installability + offline shell.
const CACHE = "bass-tuner-v1";
const ASSETS = ["/", "/index.html", "/style.css", "/tuner.js", "/manifest.json"];

self.addEventListener("install", (e) => {
  e.waitUntil(caches.open(CACHE).then((c) => c.addAll(ASSETS)));
  self.skipWaiting();
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
