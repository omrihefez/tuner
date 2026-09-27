---
id: bt-d173
title: Assert live security headers per (host, path) in audit-domains.sh — the 401/307 exemption is
  right for framing headers and wrong for Cache-Control, which is why hc-d30f survived it
status: open
priority: p3
tags:
  - security
  - monitoring
  - cross-board
created: 2026-09-27
filed:
  owner: omri@ubuntu-4gb-nbg1-1
  at: 2026-09-27T18:00:13Z
---

## What to build

Extend `bass-tuner/scripts/audit-domains.sh` (bt-a2c2 already fetches the full
response header block for every host) so live security headers are asserted rather
than re-measured by hand each sweep. Two design points, both learned the hard way
today; either one omitted makes the probe blind to the defect that prompted it.

### 1. Assert per (host, PATH), not per host

hc-d30f (house-control, p2): the four security headers AND `Cache-Control: no-store`
are set at the END of the auth middleware, after `call_next`, so every early return
skips them — the `/api/*` 401, the `/login` redirect, guest refusals, CSRF refusals.
Measured live both directions: `curl -sI https://house.omrihefez.com/` returns 307
carrying NONE of them, while `/login` (405, reaches `call_next`) carries all four.

A root-only probe is structurally blind to this, because `/` IS the redirect that
skips the headers. The probe needs a small per-host path list including at least one
authed path and one refusal path.

### 2. The existing 401/307 exemption is right for FRAMING headers and wrong for CACHE headers

This is the subtle half and the reason to read audit-domains.sh's header comment
before touching it. Its stated policy (lines ~44-52):

    A 401 (`planner`) is exempt: an auth challenge has no page body for a header
    like X-Frame-Options to protect ... so a 401 with no security headers is the
    norm, not drift. A 307/308 redirect is exempt for the same reason one hop
    earlier ... it is the eventual 200's headers that matter.

That reasoning is sound for `x-frame-options` / CSP / `x-content-type-options` — there
is genuinely nothing to frame or sniff on an auth challenge, and REQUIRED_HEADERS
contains exactly those three.

It does NOT hold for `Cache-Control: no-store`, and hc-d30f's sharper half is exactly
that: a cacheable 401/403 refusal BODY. A cached refusal can be replayed to a
different viewer or persist after the auth decision changes — the absence matters
*more* on a refusal than on a 200, which is the inverse of the framing case.

So do not extend REQUIRED_HEADERS and inherit the exemption. Two classes:
  FRAMING/SNIFFING headers — asserted on 200s only, exemption stays as documented
  CACHE headers (no-store) — asserted on 401/403/refusal paths, where it matters most
Lumping both under "security headers" is what makes the single exemption look correct,
and is why hc-d30f survived a script that already had every byte it needed to catch it.

## Why it is worth building rather than sweeping by hand

Today's sweep re-measured df-024f's seven-host Permissions-Policy gap that had been on
the board since 2026-09-25, and filed three per-repo children for it. One probe would
have made that a standing assertion instead of a rediscovery. It would also cover the
harvested follow-up "meniapp hub sets X-Content-Type-Options on only 3 of its api.ts
responses, not globally — /health and most JSON endpoints send none".

## Done when

The probe fails against house-control's current `/` (307, no headers) and passes once
hc-d30f is fixed; it does NOT report a sibling 401 as missing x-frame-options (the
documented exemption, kept); it DOES report a 401 missing `no-store`; and it covers
compose/bass/meni/planner's Permissions-Policy gap so df-024f becomes assertable.
Test both sides — a header probe that flags every refusal rebuilds the noise problem
bt-a2c2 was careful to avoid.

## Log
- 2026-09-27 2026-09-27 21:06 — CORRECTION TO THIS TASK'S OWN PREMISE, from the sweeping worker, verified by me at the source. There are THREE layers, not two, and the one I filed this on is NOT why hc-d30f survived.

I wrote that the 401/307 exemption was the reason. It is not. `missing_security_headers` is called at exactly ONE site — scripts/audit-domains.sh:115, inside the SUBS (Vercel) loop. The non-Vercel loop is lines 101-103 and its entire body is a single echo:

    for h in "${OTHER_LIVE[@]}"; do
      echo "SKIP   $h.omrihefez.com -> live in the registry but not Vercel-hosted; Deployment-Protection drift does not apply"
    done

So the baseline's scope is Vercel-hosted hosts. Every self-hosted surface on this box is not exempted — it is never reached. house-control among them, which means hc-d30f had no coverage from ANY direction: its own 45 test files assert no header, and the one cross-repo script that could have was out of scope for it.

WHY THAT HID, and it is the same shape as the exemption: the SKIP line states a reason that is TRUE for Deployment-Protection and silent about headers. A reader sees a host skipped for a stated reason and gets no cue that a second check also did not run. A justification correct for one class, load-bearing for two.

THE THREE LAYERS, each needing its own fix:
  1. root-only probing -> assert per (host, PATH). `/` is house-control's 307 that skips the headers.
  2. the 401/307 exemption is right for framing/sniffing headers, wrong for Cache-Control:
     no-store on a refusal body. (Still true, still worth splitting — just not hc-d30f's cause.)
  3. the baseline never runs on non-Vercel hosts AT ALL. The OTHER_LIVE loop must actually call
     the check, and its SKIP text must name only what it really skips. Neither 1 nor 2 touches this.

DESIGN CONSTRAINTS FOR LAYER 3, from the registry rows, so a naive extension does not fire on correct behaviour:
    brain        second-brain   answers a bare '404 page not found' to every unauthenticated request BY
                                DESIGN (auth_wall, deliberately indistinguishable from an unused subdomain)
    oauth        apartment      INTENTIONALLY public, no auth wall
Both are correct and would look like drift. The two that genuinely want the baseline are `house` and `meniapp-api`; `tik-api`/`tik-api-vps` are financial backends and want it too but were not assessed here.

FOLDED IN rather than filed separately: the meniapp hub sets x-content-type-options on only 3 of api.ts's responses, so /health and most JSON endpoints send none. That is an INSTANCE of layer 3 — meniapp-api being unchecked is precisely why nobody noticed — so it belongs in this done-when as the first host layer 3 catches, not as an independent p3. (It was raised as a FOLLOW-UP line twice and harvested neither time.)

DONE WHEN, superseding the version above: the check runs on non-Vercel hosts; it fails on house-control's current `/` (307, no headers) and on meniapp-api's /health (no nosniff); it does NOT flag brain's by-design 404 or oauth's intentional openness; a sibling 401 missing x-frame-options is still not reported; a 401 missing no-store IS; and the SKIP text for any host still skipped names every check being skipped, not one of them.
