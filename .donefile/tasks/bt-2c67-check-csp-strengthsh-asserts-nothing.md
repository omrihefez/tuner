---
id: bt-2c67
title: check-csp-strength.sh asserts nothing about object-src, so four of six live hosts omit it and
  the monitor reports OK
status: done
priority: p3
tags:
  - monitoring
  - security
  - http-headers
created: 2026-10-12
filed:
  owner: meni-worker/board-refill-work-discov-ad131e
  at: 2026-10-12T15:36:10Z
done:
  at: 2026-10-12T21:51:01Z
  by: capacity-engine/worker
evidence:
  - type: commit
    value: 6844de7
    verified: 2026-10-12T21:51:01Z
  - type: test
    cmd: bash scripts/check-csp-strength.test.sh
    exit: 0
    at: 2026-10-12T21:50:58Z
    log: evidence/bt-2c67-2026-10-12T21-50-58Z-test.txt
    sha256: ce1872bb8bd75305f52bf25b62dc215b69f6726bd02b67265a9d008b6c65ca9b
    bytes: 3401
  - type: live
    cmd: bash scripts/check-monitor-heartbeats.sh csp-strength
    exit: 0
    at: 2026-10-12T21:50:58Z
    log: evidence/bt-2c67-2026-10-12T21-50-58Z-live.txt
    sha256: 00c3bff674cf086444c01e5dbdae2cd5e6b29ec7013f460d0712099f77f1bcde
    bytes: 108
  - type: note
    value: "object-src/base-uri/frame-ancestors now asserted in check-csp-strength.sh (bt-2c67). Seen
      FAILING first against the live estate (saved pre-fix run: bass/planner/tuner missing
      object-src, trips missing object-src + its pre-existing img-src wildcard -- meni/preview.meni
      had already been fixed on their own boards by the time of this run). base-uri accepts 'self'
      OR 'none' (oauth.omrihefez.com genuinely ships 'none', a stricter-not-weaker config --
      requiring only 'self' would have been a false positive on a real host). bass.omrihefez.com's
      vercel.json gained object-src 'none'; test/vercel-headers.test.js (bt-d517) now asserts it
      too, confirmed red against the unmodified vercel.json and green after (ad-hoc swap, not stored
      as evidence since it's not a standing command). Deployed via Vercel's GitHub auto-deploy on
      push to main (no manual deploy step in this repo) -- verified on the SERVED header
      post-deploy: bass.omrihefez.com now sends object-src 'none'. Re-ran the live monitor after
      deploy: bass and tuner (alias, same deployment) are clean; trips still flags on its
      pre-existing, unrelated img-src wildcard (separate board, out of scope) -- planner
      (apartment-planner's board) was also clean on this run, ahead of our fix landing, so that
      drift may already be resolved there independently; not verified further, out of scope here.
      Heartbeat registration (check-monitor-heartbeats.sh) untouched, confirmed still passing. Full
      npm test: 126/126 pass."
---

## The gap

`scripts/check-csp-strength.sh` (bt-5059) is the fleet's only CSP DIRECTIVE-STRENGTH monitor.
What it actually asserts, read from the script:

- script-src: no `unsafe-inline`, no `unsafe-eval`, no bare wildcard (:157, :25-30)
- img-src: checked (:167 region)
- style-src `unsafe-inline`: DELIBERATELY exempt, estate-wide (:46-55)

It asserts nothing about `object-src`, `base-uri` or `frame-ancestors`. So a live host can
drop `object-src 'none'` — or never have had it — and the monitor reports OK.

## That is not hypothetical. Measured live 2026-10-12 ~18:28 IDT, plain HEAD requests:

    bass.omrihefez.com          object-src MISSING
    preview.meni.omrihefez.com  object-src MISSING
    meni.omrihefez.com          object-src MISSING
    planner.omrihefez.com       object-src MISSING
    compose.omrihefez.com       object-src 'none'
    kidai.omrihefez.com         object-src 'none'

Four of six omit it, and two set it — so there is an established estate norm the monitor
cannot see drift from. Every omitting host falls back to `default-src 'self'`, which permits
a same-origin `<object>`/`<embed>`: a scriptable context that a nonce-based `script-src`
never gates, because the nonce rule does not apply to it.

`bass.omrihefez.com` is this repo's own host, and it calls `getUserMedia` — so it is both an
instance of the drift and the one this board can fix end to end.

## Why extend the monitor rather than only fix the hosts

bt-5059's own premise was that nothing watched directive strength. Fixing four hosts by hand
leaves the next host free to ship without the directive and nothing to notice — which is the
failure shape this board has already paid for twice (bt-b97b: a header monitor that was never
wired into cron and so never ran; bt-5c8e: a monitor pinning the exact value for ONE host, so
drift on the other seven was invisible).

## DONE WHEN

1. `check-csp-strength.sh` requires `object-src 'none'` on every host it checks (and asserts
   `base-uri 'self'` + `frame-ancestors 'none'`, both of which every measured host already
   sends, so adding them costs nothing and locks in what is true today).
2. The new rule is seen FAILING first: run it against the live estate as-is and confirm it
   names the four hosts above. Record that output. A rule only ever seen passing is
   indistinguishable from one that cannot fire.
3. `bass.omrihefez.com`'s own CSP gains `object-src 'none'` in `vercel.json`, with the
   existing CI header check (bt-d517) covering it, and verified on the served header after
   deploy — not on the file.
4. The monitor's heartbeat entry stays intact (`check-monitor-heartbeats.sh`, where bt-5059
   registered it) — do not add a rule without confirming the monitor is still in that set.

The other three hosts' own fixes belong on their boards: meni + preview.meni are filed on
meni-arch; planner is apartment-planner's. This task is the monitor plus bass.

## Log
- 2026-10-13 claimed by capacity-engine
- 2026-10-13 released by capacity-engine
- 2026-10-13 claimed by capacity-engine
- 2026-10-13 done by capacity-engine/worker — commit 6844de7, test `bash scripts/check-csp-strength.test.sh` exit 0 (log: evidence/bt-2c67-2026-10-12T21-50-58Z-test.txt), live `bash scripts/check-monitor-heartbeats.sh csp-strength` exit 0 (log: evidence/bt-2c67-2026-10-12T21-50-58Z-live.txt)
