// Service worker — offline shell + version-controlled cache.
const CACHE = "tuner-v1";
const ASSETS = ["/", "/index.html", "/style.css", "/tuner.js", "/manifest.json", "/icon-192.png"];

function isAppShell(request) {
  if (request.mode === "navigate") return true;
  return request.url.endsWith(".html") || request.url.endsWith(".js");
}

self.addEventListener("fetch", (e) => {});
