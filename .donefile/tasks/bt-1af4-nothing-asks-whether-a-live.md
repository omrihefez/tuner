---
id: bt-1af4
title: Nothing asks whether a live omrihefez.com surface is REGISTERED — every host monitor derives
  its list from DOMAIN.md, so none can see a host that was never added to it
status: claimed
priority: p3
tags:
  - monitoring
  - observability
  - cross-board
created: 2026-10-13
filed:
  owner: omri@ubuntu-4gb-nbg1-1
  at: 2026-10-13T09:28:14Z
claim:
  owner: capacity-engine
  at: 2026-10-13T09:42:27Z
---

Every host monitor in the fleet derives its host set FROM `~/meni/DOMAIN.md`, so
none of them can witness a live surface that has no DOMAIN.md row at all.

Measured 2026-10-13 ~12:3x IDT while closing df-1716 (meni board):

| consumer | host source |
|---|---|
| `scripts/audit-domains.sh:543-544` | `derive_registry_hosts "$DOMAIN_MD"` |
| `meniapp/scripts/check-cert-expiry.sh:93` | `derive_registry_hosts "$DOMAIN_MD"` |
| `scripts/check-tunnel-liveness.sh` | same derivation (non-vercel set) |
| `~/meni/bin/check-public-surfaces.sh:31-71` | hand-maintained literal, 11 of 15 (df-78db) |
| `~/meni/config/health-registry.json` | 26 entries, 2 distinct https hosts |

So the coverage question "is every registered host watched" is answered BY
CONSTRUCTION and always returns yes. The question that can actually fail —
"is every LIVE host registered" — is asked by nothing.

## Why this is not theoretical

`preview.meni.omrihefez.com` was exactly this case and went unwatched for
months (ar-0058, DOMAIN.md §1 note). It needed no DNS record, because
`*.omrihefez.com` is a wildcard and answers for any name under it, and no Vercel
project of its own, because it is an ALIAS onto `meni-arch`. That combination
made it invisible to the registry-derived monitors AND to the DNS/Vercel drift
audit, which enumerates Cloudflare records and Vercel projects — it was neither.

It is also a host that accepts Omri's PRODUCTION passkey, so the thing nothing
was watching was an internet-facing auth surface.

## Current exposure: ZERO, which is why this is p3 and not urgent

Do not read this as a live hole. Measured today:

    cd /home/omri/projects/meniapp && vercel alias ls | grep -oE '[a-z0-9.-]+\.omrihefez\.com' | sort -u
    -> preview.meni.omrihefez.com      (the only one, and it IS in DOMAIN.md §1)

All 15 🟢 §1 hosts are covered by `audit-domains.sh` (verified, exit 0), and
`check-cert-expiry.sh` is green over 17 hosts even at `CERT_MIN_DAYS=30`. The
gap is that nothing would tell us when that stops being true.

## The trap to avoid when fixing this — I walked into it

While closing df-1716 I wrote a probe that diffed DOMAIN.md's live hosts against
`audit-domains.sh`'s output, committed it, then mutation-tested it with an
injected unaudited host. It reported "all 16 covered" and exited 0. The probe
could not fail: both sides of its diff come from DOMAIN.md, so they move
together. Backed out; not in history.

A probe for this MUST enumerate reality independently of the registry:

- `vercel alias ls` + each project's domains (an alias has no project row)
- the Cloudflare zone's records
- and note that neither of those sees a pure wildcard name that is live only
  because something is serving it — if that case matters, the enumeration has
  to come from the serving side (Vercel aliases, tunnel ingress rules in
  `~/.cloudflared/*.yml`), not from DNS.

then diff THAT against DOMAIN.md §1 and fail on anything live-but-unregistered.
Fail closed and distinctly: "cannot enumerate" must not look like "nothing found"
(`check-model-ids-resolve.sh` from bt-5abe is the shape to copy — distinct exit
codes for CANNOT RUN / DRIFT / OK, and discovery by shape rather than a list).

DONE WHEN a monitor exists that discovers live surfaces from the serving side,
diffs them against DOMAIN.md §1, exits non-zero on an unregistered live host,
has a hermetic `.test.sh` companion seen both RED and GREEN, and is wired into
`run-monitor.sh` + `check-monitor-heartbeats.sh` like the other monitors here.
Prove RED by injecting a synthetic live surface that is absent from DOMAIN.md —
and prove the injection is on the ENUMERATION side, not in DOMAIN.md, or you
have rebuilt the probe that cannot fail.


cross-board: names a file under 'meniapp' at /home/omri/projects/meniapp — consider filing there instead (see dn-334c).

## Log
- 2026-10-13 claimed by capacity-engine
