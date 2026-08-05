---
id: bt-5fb7
title: check-sw-cache-bump.js only verifies the git diff at commit time — nothing checks that the
  deployed sw.js CACHE actually matches what shipped
status: open
priority: p2
tags:
  - deploy
  - pwa
created: 2026-08-05
---

scripts/check-sw-cache-bump.js fails CI when a cached asset changes without sw.js's CACHE version moving, but it only ever diffs two git refs — it has no way to know what Vercel is actually serving. A deploy that silently failed, or an edge/CDN layer serving a stale build, would leave production's sw.js lagging behind HEAD indefinitely with nothing to catch it (the exact done-is-not-deployed gap bt-a60b named for this board generally, applied to this specific case). DONE WHEN: a live probe script fetches the real deployed sw.js from bass.omrihefez.com, extracts its CACHE version, and compares it against a given git ref's source — passing when they match, failing (with a clear message) when they don't — and is wired as this task's own --live evidence.
