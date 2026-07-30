---
id: bt-ab14
title: check-sw-cache-bump.js still hard-fails HTML and JS changes even though sw.js went
  network-first for exactly those
status: open
priority: p3
tags:
  - ci
  - tooling
created: 2026-07-30
---

sw.js lines 1-5 and isAppShell (lines 29-32) make navigations, .html and .js network-first, and the file's own header comment says this is 'so a deploy is live on the very next load instead of waiting on a manual CACHE bump'. But scripts/check-sw-cache-bump.js treats every entry of the ASSETS list as cache-versioned: it collects changed files that are in ASSETS (line 87) and exits 1 unless CACHE moved (lines 102-108). ASSETS includes /index.html, /about.html, /privacy.html and /tuner.js, all of which are network-first, so touching tuner.js fails the build until CACHE is bumped, and that bump changes nothing for those files. The guard is only still meaningful for the genuinely cache-first entries: style.css, manifest.json and the three png icons. DONE WHEN: the check computes its tracked set as ASSETS minus the network-first extensions that isAppShell matches (parse them from sw.js rather than hardcoding, so the two cannot drift), a JS-only change no longer fails without a CACHE bump, a style.css change still does, and both cases are covered by a test.
