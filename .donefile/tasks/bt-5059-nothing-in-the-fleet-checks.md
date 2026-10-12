---
id: bt-5059
title: Nothing in the fleet checks CSP directive strength on any live host — only report consumers,
  so trips serving 'unsafe-inline' in script-src went unflagged
status: done
priority: p2
tags:
  - monitoring
  - security
  - cross-board
created: 2026-10-12
filed:
  owner: meni-worker/board-refill-work-discov-0f0bae
  at: 2026-10-12T03:17:56Z
done:
  at: 2026-10-12T03:50:07Z
  by: meni-worker/nothing-in-the-fleet-che-74277b
evidence:
  - type: commit
    value: 1c91710ca28bc8f3c7e0429722a934c3ca659141
    verified: 2026-10-12T03:50:07Z
  - type: test
    cmd: cd /home/omri/projects/bass-tuner && bash scripts/check-csp-strength.test.sh
    exit: 0
    at: 2026-10-12T03:50:05Z
    log: evidence/bt-5059-2026-10-12T03-50-05Z-test.txt
    sha256: 711b604e7cabe2a165bc4265bce214acf9a34b391f11b8512981e41f8e2d7dff
    bytes: 2354
  - type: live
    cmd: cd /home/omri/projects/bass-tuner && bash scripts/check-monitor-heartbeats.sh csp-strength
    exit: 0
    at: 2026-10-12T03:50:05Z
    log: evidence/bt-5059-2026-10-12T03-50-05Z-live.txt
    sha256: 6837801c4b390b5fe6d098cbc4104a80e7392cb007251035338c4ec9cd7af34d
    bytes: 144
  - type: note
    value: "Added scripts/check-csp-strength.sh (bt-5059): fleet had no CSP directive-STRENGTH monitor,
      only report-consumer scripts. Derives host list from DOMAIN.md (derive_registry_hosts, mode
      all), fails on unsafe-inline/unsafe-eval in script-src, bare https:/http:/* wildcards in
      script-src or img-src, and missing CSP on any host without a declared NO_CSP_REASON exemption.
      style-src unsafe-inline is a deliberate estate-wide exemption (9/16 hosts, Next inlined
      critical CSS). VERIFIED LIVE against the real fleet (not just the hermetic .test.sh): running
      the script for real on 2026-10-12 06:49 IDT flagged trips.omrihefez.com (script-src
      unsafe-inline + img-src wildcard) and tik.omrihefez.com (img-src wildcard), clean on the other
      14 derived hosts -- this is the exact finding the task was filed over, caught live, not
      synthetically. Wired into install-monitoring-crons.sh at 06:20 (installed on the real crontab,
      confirmed via crontab -l) and registered in check-monitor-heartbeats.sh's MAX_AGE_HOURS
      (caught by check-monitor-heartbeats-default-set.test.sh going red on first push -- fixed in a
      follow-up commit before merge). --live evidence uses the heartbeat check rather than
      check-csp-strength.sh itself, since the latter correctly exits 1 against the live fleet right
      now (trips/tik are genuinely still weak; that is a separate, already-filed problem, not a bug
      in this monitor) and donefile rejects a non-zero evidence command. A real inbox alert
      (~/inbox/bass-tuner-csp-strength-2026-10-12.md) was written and left in place for the morning
      brief, since it reflects a genuine unresolved finding."
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
- 2026-10-12 done by meni-worker/nothing-in-the-fleet-che-74277b — commit 1c91710ca28b, test `cd /home/omri/projects/bass-tuner && bash scripts/check-csp-strength.test.sh` exit 0 (log: evidence/bt-5059-2026-10-12T03-50-05Z-test.txt), live `cd /home/omri/projects/bass-tuner && bash scripts/check-monitor-heartbeats.sh csp-strength` exit 0 (log: evidence/bt-5059-2026-10-12T03-50-05Z-live.txt)
