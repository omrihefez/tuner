---
id: bt-2c67
title: check-csp-strength.sh asserts nothing about object-src, so four of six live hosts omit it and
  the monitor reports OK
status: claimed
priority: p3
tags:
  - monitoring
  - security
  - http-headers
created: 2026-10-12
filed:
  owner: meni-worker/board-refill-work-discov-ad131e
  at: 2026-10-12T15:36:10Z
claim:
  owner: capacity-engine
  at: 2026-10-12T21:38:28Z
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
