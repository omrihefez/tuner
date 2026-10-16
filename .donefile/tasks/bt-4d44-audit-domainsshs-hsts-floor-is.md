---
id: bt-4d44
title: audit-domains.sh's HSTS floor is exactly the drifted value, so it passes bass and tuner
  emitting max-age=31536000 with no preload while the estate standard is 63072000+preload
status: open
priority: p2
tags:
  - security
  - observability
created: 2026-10-16
filed:
  owner: meni-worker/board-refill-work-discov-1256ef
  at: 2026-10-16T04:23:45Z
---

scripts/audit-domains.sh is the only thing on this box that checks HSTS at all, and its
floor is set to exactly the value the drifted hosts emit, so it passes them.

    scripts/audit-domains.sh:375    local hsts_max_age_floor=31536000

MEASURED LIVE 2026-10-16 ~07:17 IDT, curl -sI against each host:

    bass.omrihefez.com           max-age=31536000; includeSubDomains
    tuner.omrihefez.com          max-age=31536000; includeSubDomains
    meni.omrihefez.com           max-age=31536000; includeSubDomains
    preview.meni.omrihefez.com   max-age=31536000; includeSubDomains

    compose.omrihefez.com        max-age=63072000; includeSubDomains; preload
    planner.omrihefez.com        max-age=63072000; includeSubDomains; preload
    kidai.omrihefez.com          max-age=63072000; includeSubDomains; preload
    meniapp-api.omrihefez.com    max-age=63072000; includeSubDomains; preload

Four live hosts on the weaker header, four on the stronger one. The 63072000+preload value
is the estate's stated standard -- tik-api's tk-2d30 names it in as many words, calling
"max-age=63072000; includeSubDomains; preload" what the tik surfaces "correctly send".

THIS REPO OWNS BOTH HALVES OF THE PROBLEM. Its own two hosts are laggards, from

    vercel.json:20    "value": "max-age=31536000; includeSubDomains"

and its audit script is the check that should have caught it. The floor is a >= test
against the laggards' own number, so the gap cannot ever be reported: a host emitting
exactly the floor passes, and nothing anywhere asserts the `preload` directive. Confirmed
by grep -- the only files on this box mentioning strict-transport-security outside task
bodies are scripts/audit-domains.sh and its test; meniapp/scripts and ~/meni/bin have
nothing.

The other two laggards (meni, preview.meni) are meni-arch's, filed separately on that
board -- this task is this repo's two hosts plus the detection gap.

Scope note for whoever takes it: raising the floor is NOT the same change as asserting
`preload`, and the second is the one that matters here, since all eight hosts already clear
the 31536000 floor. Treat the apex separately -- omrihefez.com itself answers 404 with
`max-age=63072000` and no includeSubDomains (measured same session), which is Vercel's
platform default on a project-less name and is already tracked on tk-2d30.

DONE WHEN: audit-domains.sh reports DRIFT for a host whose HSTS lacks `preload` or whose
max-age is below the estate standard, and bass/tuner emit the standard header. Verify by
feeding the checker a synthetic response carrying exactly
`max-age=31536000; includeSubDomains` and requiring a non-zero exit -- that case passes
silently today, so demonstrate it red before the fix.
