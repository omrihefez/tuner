---
id: bt-5059
title: Nothing in the fleet checks CSP directive strength on any live host — only report consumers,
  so trips serving 'unsafe-inline' in script-src went unflagged
status: claimed
priority: p2
tags:
  - monitoring
  - security
  - cross-board
created: 2026-10-12
filed:
  owner: meni-worker/board-refill-work-discov-0f0bae
  at: 2026-10-12T03:17:56Z
claim:
  owner: capacity-engine
  at: 2026-10-12T03:36:47Z
---

Every live omrihefez.com host ships a Content-Security-Policy, and nothing in
the fleet ever checks whether those policies are any good. The gap is
structural, not an oversight in one script: the existing monitors cover
liveness, TLS expiry, permissions-policy, CORS/CORP consistency and registry
sync — and CSP only via its REPORT channel, which can only ever show what a
browser decided to tell us about a policy already in force.

MEASURED, 2026-10-12:

    grep -rn "unsafe-inline" /home/omri/projects/bass-tuner/scripts \
                             /home/omri/projects/meniapp/scripts
    -> no output

The three CSP-named scripts in the fleet are all report CONSUMERS, not policy
checkers: `meniapp/scripts/csp-report-digest.sh`,
`meniapp/scripts/feed-csp-report-brief.sh`,
`meniapp/scripts/install-csp-report-reader-cron.sh`.

WHAT THAT COSTS, concretely and not hypothetically. A live-header sweep of all
ten §1 hosts this morning found `trips.omrihefez.com` serving
`script-src 'self' 'unsafe-inline' https://challenges.cloudflare.com` — the
only host in the set with `'unsafe-inline'` in script-src, and the only one
with no nonce, so the keyword is operative rather than ignored. It is a
login-gated surface holding the family's live trip and money data. Nothing
flagged it; it surfaced because a human read the header. Filed on the
trips-hub board as its own task — this one is the missing mechanism.

The same sweep showed `trips` and `tik` both carrying a bare `https:` wildcard
in `img-src` while the other eight enumerate their image origins. Also
unflagged, same reason.

WHY bass-tuner OWNS THIS. This repo already holds the fleet's live-header
monitors and the plumbing they need:

    scripts/audit-domains.sh               enumerates hosts, VERCEL_CHECK_PATHS
    scripts/check-permissions-policy.sh    the closest existing analogue --
                                           fetches a live header and asserts
                                           its content per host
    scripts/lib/domain-registry.sh         derive_registry_hosts, reads
                                           ~/meni/DOMAIN.md §1 at runtime

`check-permissions-policy.sh` is the shape to copy: same host derivation, same
live fetch, same per-host expectation table, same `.test.sh` convention
(`check-permissions-policy.test.sh` exists alongside it).

DONE WHEN

1. A new check (suggest `scripts/check-csp-strength.sh`) derives its host list
   from `~/meni/DOMAIN.md` §1 via `scripts/lib/domain-registry.sh` — NOT a
   hand-maintained list. df-78db and bt-7f07 are both the same lesson: a
   hand-kept host list in a monitor drifts from the registry, and bt-7f07's
   anchored-apex fix exists because the derivation silently dropped every
   multi-label host (`preview.meni`). Assert the derived host COUNT is
   non-zero so a derivation that returns nothing fails loudly instead of
   passing vacuously.
2. It fetches the live `content-security-policy` header per host and FAILS on,
   at minimum: `'unsafe-inline'` or `'unsafe-eval'` in `script-src`; a bare
   `https:`/`http:`/`*` wildcard in `script-src` or `img-src`; and a missing
   CSP header entirely.
3. Per-host EXPECTED-DEVIATION entries are explicit and carry a reason, same
   convention as `VERCEL_CHECK_PATHS` in audit-domains.sh. `style-src
   'unsafe-inline'` is held by six of the ten hosts and is effectively
   unavoidable with Next's inlined critical CSS — exempt it deliberately and
   say so, rather than leaving the check to fire on every host forever, which
   is how a monitor gets ignored.
4. THE GUARD MUST BE SEEN FAILING. Feed it a synthetic host whose policy
   carries `script-src 'self' 'unsafe-inline'` and confirm it goes red, in the
   `.test.sh`. A check only ever observed passing is indistinguishable from
   one that cannot fire — and today trips-hub makes this testable against a
   REAL host too: run it against the current fleet before trips-hub's own fix
   lands and it must flag trips, which is the strongest possible evidence
   this check works. Say in the note which of the two you used.
5. Wired to cron alongside the existing monitors (audit-domains at `10 6`,
   check-cert-expiry at `7 6`) with the usual alert latch, so it does not
   re-fire the same finding daily.


cross-board: names a file under 'meni' at /home/omri/meni — ~/meni is undispatched — route it via ~/inbox/meni-board-queue/ instead (see dn-334c).

## Log
- 2026-10-12 claimed by capacity-engine
