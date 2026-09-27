---
id: bt-40c5
title: bass.omrihefez.com sends no Permissions-Policy header although the app calls getUserMedia -
  needs microphone=(self), camera=(), geolocation=()
status: claimed
priority: p3
tags:
  - security
  - http-headers
created: 2026-09-27
filed:
  owner: meni-worker/board-refill-work-discov-f62872
  at: 2026-09-27T17:41:40Z
claim:
  owner: capacity-engine
  at: 2026-09-27T20:43:29Z
---

`bass.omrihefez.com` is a microphone app and it sends no `Permissions-Policy` header,
so the document inherits the browser default, which grants the page (and anything it
embeds) every policy-controlled feature the browser has — camera, geolocation,
payment, USB, serial, and so on — when all it needs is the microphone.

THE APP GENUINELY USES THE MIC, so this is the one repo on the account where the
header is about its actual capability rather than generic posture:

    tuner.js:616   navigator.mediaDevices.getUserMedia({ audio: true })
    tuner.js:896   navigator.permissions.query({ name: "microphone" })

STRUCTURAL PROOF the header is set nowhere:

    grep -rn "Permissions-Policy" /home/omri/projects/bass-tuner
    -> no matches

Nothing in `vercel.json` or `index.html` sets it either (checked directly).

VERIFIED LIVE 2026-09-27 20:35 IDT — `curl -sI https://bass.omrihefez.com/` returns
HTTP 200 with a tight CSP, `x-frame-options: DENY`, `x-content-type-options: nosniff`
and `referrer-policy: no-referrer`, and no `permissions-policy` line at all.

SEVERITY IS HARDENING, NOT A LIVE HOLE, and the body should say so plainly: the served
CSP already carries `frame-ancestors 'none'` and the response carries
`X-Frame-Options: DENY`, so this page cannot be embedded by a third party in the first
place — which is the main way a permissive inherited policy gets abused. What is left
is defence in depth plus the honest expression of least privilege for an app whose
whole function is one sensitive capability. p3 on that basis.

THE PATTERN TO COPY ALREADY EXISTS IN THE FLEET — `meniapp.omrihefez.com`, probed the
same minute, sends exactly the right shape for a mic app:

    permissions-policy: camera=(), microphone=(self), geolocation=()

`microphone=(self)` is the correct value here, NOT `microphone=()` — an empty allowlist
would refuse `getUserMedia` in the page itself and break the tuner. This is the one
detail worth getting right; `camera=()` and `geolocation=()` are safe to deny outright
since nothing in `tuner.js` touches either.

DONE WHEN
1. `vercel.json`'s `headers` block sends
   `Permissions-Policy: camera=(), microphone=(self), geolocation=()` on all paths.
2. A test asserts it. `scripts/` already has the right precedent for this kind of
   check — `audit-domains.sh` has its own `audit-domains.test.sh` alongside it — so
   follow that shape rather than inventing one.
3. The mic still works after the change. `microphone=(self)` is the failure mode to
   watch: get it wrong and the tuner silently stops hearing anything, which no header
   assertion would catch. Confirm `getUserMedia` still resolves on the deployed build
   before closing, not just that the header is present.

VERIFY (run from the main checkout, never a worktree)

    cd /home/omri/projects/bass-tuner && bash scripts/audit-domains.test.sh

plus, on the deployed build:

    curl -sI https://bass.omrihefez.com/

Filed by the periodic discovery sweep, 2026-09-27.

## Log
- 2026-09-27 claimed by capacity-engine
