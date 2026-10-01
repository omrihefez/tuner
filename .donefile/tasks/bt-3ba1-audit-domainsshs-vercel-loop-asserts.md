---
id: bt-3ba1
title: audit-domains.sh's Vercel loop asserts no headers at all on a 307/401 host and never checks
  HSTS on any Vercel host
status: done
priority: p2
tags:
  - monitoring
  - security
created: 2026-10-01
filed:
  owner: meni-worker/board-refill-work-discov-edb20d
  at: 2026-10-01T08:07:38Z
done:
  at: 2026-10-01T08:34:02Z
  by: capacity-engine/worker
  waived: "scripts/audit-domains.sh is a cron-invoked monitoring script (10 6 * * * via
    test-monitoring.sh's crontab), not Vercel-served app-surface content -- it is tagged 'security'
    only because the finding was a security-header gap, not because it ships anything through the
    bass-tuner Vercel deploy. Nothing to activate: cron reads the committed file fresh on its next
    scheduled run, already verified live against the real registry (exit 0) in this session."
evidence:
  - type: commit
    value: 79a00b3ebb347dc3b88c91bc8d03a902e4c67a57
    verified: 2026-10-01T08:34:02Z
  - type: test
    cmd: cd /home/omri/projects/bass-tuner && bash scripts/audit-domains.test.sh
    exit: 0
    at: 2026-10-01T08:33:51Z
    log: evidence/bt-3ba1-2026-10-01T08-33-51Z-test.txt
    sha256: 7e310bf0cedfff68b50ace6144476ab7105823582211e8b6c8b375eaa09bc024
    bytes: 7808
---

`scripts/audit-domains.sh` has two header-checking loops and they have drifted far apart. The
non-Vercel loop (`OTHER_LIVE`) got per-path coverage in bt-d173 and unconditional HSTS in bt-b75b.
The Vercel loop (`SUBS`, lines 284-307) got neither, and it is the loop that covers almost every
host in the registry.

Two concrete gaps in that loop, both read straight off the source:

1. **No HSTS anywhere on the Vercel side.** `check_hsts()` is called from exactly two places,
   `check_nonvercel_path()` and `check_hsts_at()` — both non-Vercel. The `SUBS` loop never calls
   it. bt-b75b's own comment at line 154 says HSTS "is asserted on every baselined call site
   unconditionally"; that is true of the call sites it added and false of this loop, so the
   comment reads as coverage that does not exist.

2. **A 307/401 Vercel host is asserted on at all.** Line 301-302: any `307`/`308`/`401` prints
   `OK ... (header baseline not applicable: no page served)` and checks nothing — not CSP, not
   `x-frame-options`, not nosniff, not `referrer-policy`, not `cache-control`, not HSTS. The
   exemption is defensible for framing headers on a redirect; it is the exact reasoning bt-d173
   already rejected for the non-Vercel side, where root-only probing is why hc-d30f survived. The
   Vercel side still has no `VERCEL_CHECK_PATHS` equivalent.

MEASURED LIVE 2026-10-01 ~11:02-11:03 IDT, `curl -I` on each registry host's `/`:

    meni           307 -> /login      (Vercel)   nothing asserted by this script
    arch-preview   307 -> /login      (Vercel)   nothing asserted
    trips          307 -> /login      (Vercel)   nothing asserted
    tik            307 -> /login      (Vercel)   nothing asserted
    planner        401                (Vercel)   nothing asserted
    bass           200   compose 200   kidai 200   meniapp 200  -> baseline runs, but no HSTS

So five live hosts — four of them auth surfaces — are scored by this audit without a single header
being read, and all nine Vercel hosts have zero HSTS coverage.

This is not hypothetical: `ar-3426` (meni.omrihefez.com and arch-preview send no
`Permissions-Policy`) had to be found by a human probing by hand, and this script could not have
caught it for either host because both answer 307 at `/`.

## Done when

- The `SUBS` loop calls `check_hsts` on every Vercel host unconditionally, same as the non-Vercel
  call sites, and bt-b75b's line-154 comment becomes true.
- A Vercel per-path map (same shape and spirit as `NONVERCEL_CHECK_PATHS`) covers at minimum the
  five hosts above at a path that actually serves a page — e.g. `/login` for meni / arch-preview /
  trips / tik — so the baseline is asserted somewhere for every live Vercel host, and a host the
  registry derives with no pinned path fails loudly rather than printing OK (the idiom
  `check-tunnel-liveness.sh` already uses for `UNPINNED`).
- A test in `scripts/audit-domains.test.sh` feeds a stubbed `CURL_CMD` a 307 response missing the
  baseline and asserts the script reports DRIFT. Run it against the parent commit and confirm it
  FAILS there — that is the evidence this task closes on, not a grep for the new code.

## Verify (from the main checkout, never a worktree)

    cd /home/omri/projects/bass-tuner && bash scripts/audit-domains.test.sh

Filed by the periodic discovery sweep, 2026-10-01.

## Log
- 2026-10-01 claimed by capacity-engine
- 2026-10-01 done by capacity-engine/worker — commit 79a00b3ebb34, test `cd /home/omri/projects/bass-tuner && bash scripts/audit-domains.test.sh` exit 0 (log: evidence/bt-3ba1-2026-10-01T08-33-51Z-test.txt) (evidence waived: scripts/audit-domains.sh is a cron-invoked monitoring script (10 6 * * * via test-monitoring.sh's crontab), not Vercel-served app-surface content -- it is tagged 'security' only because the finding was a security-header gap, not because it ships anything through the bass-tuner Vercel deploy. Nothing to activate: cron reads the committed file fresh on its next scheduled run, already verified live against the real registry (exit 0) in this session.)
