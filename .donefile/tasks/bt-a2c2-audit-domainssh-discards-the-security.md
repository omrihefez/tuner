---
id: bt-a2c2
title: audit-domains.sh discards the security headers it already fetches — compose.omrihefez.com
  serves no CSP or X-Frame-Options while all seven sibling hosts do
status: claimed
priority: p2
tags:
  - monitoring
  - security
  - cross-board
created: 2026-09-10
filed:
  owner: meni-worker/board-refill-work-discov-ecd8db
  at: 2026-09-10T20:23:38Z
claim:
  owner: capacity-engine
  at: 2026-09-10T21:12:47Z
---

## What is wrong

`scripts/audit-domains.sh` already captures the FULL response headers of every
registry host — line 66 is `resp=$("${CURL_CMD:-curl}" -s -D - -o /dev/null
--max-time 10 "https://$host/")` — and then asserts only the status line. Every
security header it has already fetched is thrown away.

That is not a hypothetical gap. Measured live 2026-09-10 23:16-23:17 IDT with
`curl -I`, one host at a time:

| host | CSP | X-Frame-Options | X-Content-Type-Options | Referrer-Policy |
|---|---|---|---|---|
| `bass` | yes | DENY | nosniff | no-referrer |
| `kidai` | yes | DENY | nosniff | origin-when-cross-origin |
| `meni` | yes | DENY | nosniff | no-referrer |
| `meniapp` | yes | DENY | nosniff | no-referrer |
| `planner` | (401) | — | — | — |
| `tik` | yes | DENY | nosniff | strict-origin-when-cross-origin |
| `trips` | report-only | DENY | nosniff | strict-origin-when-cross-origin |
| `compose` | **NONE** | **NONE** | **NONE** | **NONE** |

`compose.omrihefez.com` answered `HTTP/2 200` and its complete header set was:
`accept-ranges`, `access-control-allow-origin: *`, `age`, `cache-control`,
`content-disposition`, `content-type`, `date`, `etag`, `server: Vercel`,
`strict-transport-security`, `vary`, `x-matched-path`, `x-nextjs-prerender`,
`x-nextjs-stale-time`, `x-vercel-cache`, `x-vercel-id`, `content-length`.

No Content-Security-Policy, no X-Frame-Options, no X-Content-Type-Options, no
Referrer-Policy, no Permissions-Policy, and a wildcard
`access-control-allow-origin`. It is the only public, unauthenticated surface in
the estate, and it is the one with no frame-ancestors protection of any kind — so
it is clickjackable while its seven siblings are not.

## Why it matters

DOMAIN.md's §1 row for `compose` reads `🟢 live | public` and nothing more. The
registry records that the host answers; nothing anywhere records what posture it
answers WITH. Eight hosts, seven consistent, one silently different for however
long — and the only tool that visits all eight already had the evidence in a
variable and discarded it.

This is the same shape as the two incidents DOMAIN.md's own changelog records
(2026-08-19 and 2026-08-23, live subdomains with no registry row): a check that
runs regularly, looks green, and is not asking the question that matters.

## Why bass-tuner

`scripts/audit-domains.sh` lives here and is the estate's registry-derived
domain audit — `derive_registry_hosts "$DOMAIN_MD" vercel` at line 49. It already
runs against all of these hosts and already holds their headers. `compose` itself
is a boardless, deliberately-excluded repo (`_boardless_repos_note.md`, ce-917c)
with no board to file against, and `~/meni` is not dispatched; the checker is the
dispatchable half and it is here.

Adding the assertion does NOT fix compose's headers — that is a separate change
in a repo nobody dispatches to, and it is Main's call whether to make it. What
this task delivers is that the gap stops being invisible.

## DONE WHEN

- `scripts/audit-domains.sh` asserts a security-header baseline per host, not
  just the status code, and reports a host that is missing one as DRIFT.
- The baseline is derived or documented, not a bare list of strings: say which
  headers are required and why a 401/307 host is or is not exempt.
- Evidence is a run that FAILS on the current estate (compose is missing four)
  and passes once compose is either fixed or explicitly recorded as a known
  exception. A run that only ever passes proves nothing — turn the assertion on
  against today's estate and confirm it goes red first.
- If the call is that compose's headers are Main's to fix, say so in the closing
  note and name what the audit now reports for it.

## Provenance

Periodic discovery sweep, 2026-09-10 23:16-23:17 IDT. Eight `curl -I` probes
against the §1 hosts; `grep -n` on `scripts/audit-domains.sh`. The header tables
above are copied from those responses, not inferred.

## Log
- 2026-09-11 claimed by capacity-engine
- 2026-09-11 released by capacity-engine
- 2026-09-11 claimed by capacity-engine
