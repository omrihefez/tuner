---
id: bt-b75b
title: audit-domains.sh never asserts Strict-Transport-Security on any non-Vercel host — three live
  tunnel hosts are missing it today
status: claimed
priority: p2
tags:
  - security
  - monitoring
created: 2026-09-30
filed:
  owner: meni-worker/board-refill-work-discov-6571ae
  at: 2026-09-30T19:45:35Z
claim:
  owner: capacity-engine
  at: 2026-09-30T20:45:43Z
---

`scripts/audit-domains.sh` asserts `Strict-Transport-Security` on Vercel hosts only. Every Cloudflare-Tunnel host in `~/meni/DOMAIN.md` §1 gets a liveness check and a partial header check, and HSTS is in neither branch.

THE GAP, from the script's own source:

- `SUBS` is derived Vercel-only: line 203, `mapfile -t SUBS < <(derive_registry_hosts "$DOMAIN_MD" vercel | sort -u)`.
- `check_nonvercel_path()` says so in its own header comment (line 134): "Never touches missing_security_headers()/REQUIRED_HEADERS — those stay scoped to the SUBS loop so its existing behaviour and tests are untouched."
- What the non-Vercel branch actually checks: for a 401/403/307/308 it asserts `Cache-Control: no-store` (line 144); for a 200 it asserts `x-content-type-options` always and CSP/`x-frame-options`/`referrer-policy` only when content-type is `text/html` (lines 157-170). `Strict-Transport-Security` appears in neither list.

bt-a2c2 (done) is what added header checking here, and it scoped it to the SUBS loop deliberately — so this was never a regression, it is coverage that was never built. The comment is honest about it; nothing downstream re-checks whether the exemption still costs nothing.

IT COSTS SOMETHING NOW. Measured live 2026-09-30 22:42 IDT with `curl -sI`, all six non-Vercel hosts in DOMAIN.md §1:

    tik-api.omrihefez.com        404   NO Strict-Transport-Security
    tik-api-vps.omrihefez.com    404   NO Strict-Transport-Security
    brain.omrihefez.com          404   NO Strict-Transport-Security
    house.omrihefez.com          307   max-age=31536000; includeSubDomains
    meniapp-api.omrihefez.com/health  200  max-age=63072000; includeSubDomains; preload
    oauth.omrihefez.com/health   501 (HEAD unimplemented, documented in DOMAIN.md)

Three of six send it and three do not. That unevenness across hosts on one registrable domain is exactly the drift this monitor exists to catch, and it cannot see it. Note the Vercel side is uniformly covered — all eight Vercel hosts probed the same minute carry HSTS — so the blind spot and the failures line up precisely.

`house` and `meniapp-api` prove this is not a tunnel limitation: same Cloudflare Tunnel, same box, header present. It is per-app, which is why a monitor is the right place to hold the line.

DONE WHEN
1. `check_nonvercel_path()` asserts `Strict-Transport-Security` on every non-Vercel host, on ANY status code it baselines — not gated on 200 and not gated on an HTML content-type. HSTS is a transport-level header; it is as applicable to a JSON 404 as to an HTML 200, which is the reason the existing content-type gate (correct for CSP/XFO/Referrer-Policy) must not be reused for it.
2. Decide and record what happens to the `NONVERCEL_HEADER_SKIP_REASON` entries (`brain`, `oauth`). Both skip reasons are about auth-wall/body semantics, neither is a reason to skip HSTS — so either narrow those skips to the body-shaped headers or state why HSTS is exempt there too.
3. A test asserts the new check BY BEHAVIOUR and is seen to fail first: feed the script a stubbed `CURL_CMD` response with no HSTS header and confirm it reports DRIFT and sets FAIL=1, then add the header to the same fixture and confirm OK. `CURL_CMD` is already overridable (line 139), so this needs no network. Run it against the parent commit and confirm red — a check only ever seen passing is indistinguishable from one that cannot fire.
4. Run the real script and quote its output for the three hosts above. It should be DRIFT for all three today; that is the evidence the coverage is genuinely new.

DO NOT fix the missing headers from here. The header absences are filed on their owning boards (tik-api, second-brain); this task is the detection gap only.

VERIFY (from the main checkout, never a worktree)

    cd /home/omri/projects/bass-tuner && bash scripts/audit-domains.sh

Filed by the periodic discovery sweep, 2026-09-30.

## Log
- 2026-09-30 claimed by capacity-engine
