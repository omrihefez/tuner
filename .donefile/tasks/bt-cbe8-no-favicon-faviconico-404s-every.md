---
id: bt-cbe8
title: "No favicon: /favicon.ico 404s every load, no tab/home-screen icon"
status: claimed
priority: p3
tags:
  - ux
created: 2026-07-14
claim:
  owner: capacity-engine
  at: 2026-07-23T06:13:43Z
---

index.html/about.html/privacy.html have NO <link rel='icon'> (grep clean). favicon.png exists in the repo root but is unreferenced and is NOT in the SW ASSETS list (sw.js:5), so it is not even cached offline. Result: browsers request /favicon.ico -> 404 on every fresh load; no favicon in the tab. Fix: add <link rel='icon' href='/favicon.png'> (and an .ico or apple-touch-icon as desired) to all three pages and add favicon.png to sw.js ASSETS.

## Log
- 2026-07-23 claimed by capacity-engine
