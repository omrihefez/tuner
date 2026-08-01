---
id: bt-ab14
title: check-sw-cache-bump.js still hard-fails HTML and JS changes even though sw.js went
  network-first for exactly those
status: done
priority: p3
tags:
  - ci
  - tooling
created: 2026-07-30
done:
  at: 2026-08-01T09:03:08Z
  by: capacity-engine/worker
evidence:
  - type: commit
    value: 9f9e1aaaa8960f1eb89733cf1223bcd2ec066071
    verified: 2026-08-01T09:03:08Z
  - type: test
    cmd: npm test
    exit: 0
    at: 2026-08-01T09:03:07Z
    log: evidence/bt-ab14-2026-08-01T09-03-07Z-test.txt
    sha256: 93ae07071e3f51d333c3e0bc20ea6b28cd0ebe0c2783ae0a192f69573e478d4d
    bytes: 17034
---

sw.js lines 1-5 and isAppShell (lines 29-32) make navigations, .html and .js network-first, and the file's own header comment says this is 'so a deploy is live on the very next load instead of waiting on a manual CACHE bump'. But scripts/check-sw-cache-bump.js treats every entry of the ASSETS list as cache-versioned: it collects changed files that are in ASSETS (line 87) and exits 1 unless CACHE moved (lines 102-108). ASSETS includes /index.html, /about.html, /privacy.html and /tuner.js, all of which are network-first, so touching tuner.js fails the build until CACHE is bumped, and that bump changes nothing for those files. The guard is only still meaningful for the genuinely cache-first entries: style.css, manifest.json and the three png icons. DONE WHEN: the check computes its tracked set as ASSETS minus the network-first extensions that isAppShell matches (parse them from sw.js rather than hardcoding, so the two cannot drift), a JS-only change no longer fails without a CACHE bump, a style.css change still does, and both cases are covered by a test.

## Log
- 2026-08-01 claimed by capacity-engine
- 2026-08-01 done by capacity-engine/worker — commit 9f9e1aaaa896, test `npm test` exit 0 (log: evidence/bt-ab14-2026-08-01T09-03-07Z-test.txt)
