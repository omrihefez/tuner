---
id: bt-7bc5
title: No CI — static site deploys with no lint/validate/link/regression guard
status: open
priority: p3
tags:
  - deploy
created: 2026-07-14
---

No .github/ directory, no GitHub Actions, no html-validate/link-check/lint. The app is hand-edited HTML/CSS/JS deployed to Vercel with nothing catching a broken tag, dead internal link (/about.html, /privacy.html), malformed manifest.json, or a stale SW CACHE bump before it reaches users. Fix: add a lightweight CI (html-validate + a JS syntax/lint step + a check that sw.js CACHE version changed when assets changed) on PR/push.
