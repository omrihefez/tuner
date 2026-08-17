---
id: bt-7bc5
title: No CI — static site deploys with no lint/validate/link/regression guard
status: done
priority: p3
tags:
  - deploy
created: 2026-07-14
done:
  at: 2026-07-23T06:09:41Z
  by: capacity-engine/worker
evidence:
  - type: commit
    value: 85880ed
    verified: 2026-07-23T06:09:41Z
  - type: test
    cmd: npm test
    exit: 0
    at: 2026-07-23T06:09:40Z
    log: evidence/bt-7bc5-2026-07-23T06-09-40Z-test.txt
    sha256: 475e38b0b28dfa750ff02a3994c3cef476af782710ab7f56f12ef6d4d74669f9
    bytes: 16759
---

No .github/ directory, no GitHub Actions, no html-validate/link-check/lint. The app is hand-edited HTML/CSS/JS deployed to Vercel with nothing catching a broken tag, dead internal link (/about.html, /privacy.html), malformed manifest.json, or a stale SW CACHE bump before it reaches users. Fix: add a lightweight CI (html-validate + a JS syntax/lint step + a check that sw.js CACHE version changed when assets changed) on PR/push.

## Log
- 2026-07-23 claimed by capacity-engine
- 2026-07-23 released by capacity-engine
- 2026-07-23 claimed by capacity-engine
- 2026-07-23 done by capacity-engine/worker — commit 85880ed, test `npm test` exit 0 (log: evidence/bt-7bc5-2026-07-23T06-09-40Z-test.txt)
