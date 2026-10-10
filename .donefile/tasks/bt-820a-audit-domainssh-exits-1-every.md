---
id: bt-820a
title: audit-domains.sh exits 1 every morning on two apex HSTS drifts nobody can fix — no project
  serves the apex, so the header is unconfigurable and no task owns it
status: open
priority: p2
tags:
  - security
  - http-headers
  - monitoring
created: 2026-10-10
filed:
  owner: omri@ubuntu-4gb-nbg1-1
  at: 2026-10-10T15:58:18Z
---

`scripts/audit-domains.sh` (cron `10 6`) exits **1 every morning** on two apex
findings, and no open task anywhere owns them. Measured 2026-10-10 18:5x IDT,
after the `preview.meni` pin landed (`3e83efe`) and with every other host green:

    DRIFT  omrihefez.com -> 404 Strict-Transport-Security missing includeSubDomains: max-age=63072000
    DRIFT  omrihefez.com -> 404 Strict-Transport-Security missing preload at the apex
           (bt-e47e: this is the one host where preload is load-bearing): max-age=63072000
    full audit exit=1          # scoped AUDIT_SUBS=preview.meni exit=0

## The findings are CORRECT. The problem is that nothing can act on them

    $ curl -sI https://omrihefez.com/
    HTTP/2 404
    strict-transport-security: max-age=63072000
    x-vercel-error: DEPLOYMENT_NOT_FOUND

There is **no Vercel project behind the apex** — DOMAIN.md §1 row 23 has it
`🟠 blank`, "404 `DEPLOYMENT_NOT_FOUND` — design in §6". That `max-age` is
Vercel's platform default for an unclaimed name, so there is no `vercel.json`,
`next.config` or header array anywhere in this estate that could add
`includeSubDomains` or `preload` to it. The header is not misconfigured; it is
unconfigurable. bt-e47e (done) built the stricter apex probe and was right to —
preload at the apex IS load-bearing, since it covers every subdomain — but it
surfaced a condition whose fix lives outside any repo the probe can see.

## Why this needs a row rather than a waiver

A monitor that exits 1 every single day on something nobody can fix is the exact
shape that gets `|| true`'d, waived, or quietly dropped from crontab, taking its
real findings with it. Today it is the ONLY thing standing between this audit
and a clean exit — every other host, including the newly registered
`preview.meni`, is green. The next person to see a red `10 6` mail has no task
to read and the fastest path to green is to disable the check.

Checked before filing: no open task on bass-tuner, meni-arch, meniapp, iac or
the meni board owns the apex. `iac-e617` (dropped) touched apex DNS records,
`df-6f99` (done) only relocated the apex design docs. §6's design decision is
already made and is NOT the blocker to re-litigate: light warm-paper editorial
v3, after the dark/OKLCH direction was rejected as "too AI-ish". It is simply
unbuilt.

## DONE WHEN — one of these, decided deliberately, not drifted into

1. **Preferred, if the apex is getting built anyway:** something serves
   `omrihefez.com` per §6, with HSTS carrying `includeSubDomains` and `preload`,
   and this audit goes to exit 0. That retires the finding by fixing it.
2. **Otherwise:** the probe distinguishes *apex unclaimed* from *apex
   misconfigured*. A 404 with `x-vercel-error: DEPLOYMENT_NOT_FOUND` is a
   known, registry-documented state (§1 row 23 `🟠 blank`), so report it as a
   named, dated exemption — the same idiom this file already uses for
   `VERCEL_ALIAS_SKIP_REASON` (`tuner`) and `VERCEL_RETIRED_SKIP_REASON`
   (`arch-preview`), both of which are reviewed exemptions rather than silence.
   **It must still be visible**, not suppressed: the exemption keyed and dated
   so it reads as "deliberately not asserted while the apex is unclaimed", and
   it must stop applying the moment the apex serves a real page.

Do NOT close this by deleting the apex probe or by loosening `check_hsts()` for
every host — bt-e47e added `check_apex_hsts()` specifically so the apex could be
stricter than subdomains, and `audit-domains.test.sh:684-697` asserts that
fail/pass pair. Option 2 narrows WHEN the assertion applies, never what it
asserts.

## Verify

Whichever option: the audit must be seen to go from exit 1 to exit 0 on this
cause, and `audit-domains.test.sh` must still pass all 38 assertions, including
bt-e47e's test 32 ("the apex probe is a real fail/pass pair, not one only ever
seen failing"). Under option 2, add a case proving the exemption does NOT apply
once the apex returns a 200.
