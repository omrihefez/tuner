---
id: bt-d517
title: CI never verifies vercel.json security headers, so an edit can silently drop CSP or
  frame-ancestors with no test failing
status: claimed
priority: p3
tags:
  - security
created: 2026-08-04
claim:
  owner: capacity-engine
  at: 2026-08-04T07:53:46Z
---

bass-tuner's entire security posture is seven headers declared in vercel.json - HSTS, X-Content-Type-Options nosniff, X-Frame-Options DENY, Referrer-Policy no-referrer, a strict CSP with frame-ancestors none and form-action self, COOP same-origin and CORP same-origin - plus the no-store Cache-Control on sw.js that makes every deploy reachable. Nothing tests any of it. .github/workflows/ci.yml runs node --check on every JS file, html-validate, check-links.js, check-sw-cache-bump.js and the unit suite, and none of those parse vercel.json. The repo already proved it takes this class of config seriously: check-sw-cache-bump.js exists precisely because a silent config-vs-asset drift once shipped, and it deliberately reads sw.js's own ASSETS and isAppShell rather than hardcoding a list so the check and the code cannot drift apart. The header block deserves the same treatment and does not have it - a careless edit to vercel.json that drops frame-ancestors or weakens script-src passes CI green. A test is cheap: parse vercel.json, assert the catch-all source is present, and assert each required header key is present with the expected directive substrings. It runs offline with no network and fits the existing node --test suite. DONE WHEN: a test under test/ asserts vercel.json's catch-all header block still contains all seven headers and that the CSP still carries default-src self and frame-ancestors none, it runs as part of npm test, and it fails when a header is removed.

## Log
- 2026-08-04 claimed by capacity-engine
