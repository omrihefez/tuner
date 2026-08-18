---
id: bt-b130
title: check-fallback-cert.sh only detects a wildcard cert that has ALREADY expired — it never reads
  notAfter, so it gives zero lead time on the exact failure it exists for
status: claimed
priority: p3
tags:
  - ops
  - monitoring
  - tls
created: 2026-08-14
claim:
  owner: capacity-engine
  at: 2026-08-18T00:22:45Z
---

`scripts/check-fallback-cert.sh` asserts the Vercel fallback TLS cert for unclaimed
`*.omrihefez.com` subdomains by curling `composer.omrihefez.com` and requiring a clean
404:

    if ! resp=$(curl -sI --max-time 10 "https://$HOST/" 2>&1); then ... exit 1
    code=$(echo "$resp" | head -1 | awk '{print $2}')
    if [[ "$code" == "404" ]]; then ... exit 0

That is a liveness check, not an expiry check. It goes red only once the handshake is
ALREADY failing — i.e. at the moment the outage starts, with zero lead time. The
certificate's `notAfter` is never read.

That is exactly the shape of the incident this file exists because of. The active
reminder `rem-wildcard-cert-renew-20261010` records it: *"The Vercel-managed wildcard
fallback cert expired silently on 2026-06-17 and nobody noticed for over a month —
every unclaimed subdomain hard-failed TLS instead."* The current mitigation is a
calendar reminder pointed at the next expiry (2026-10-23) — a human remembering, which
is the thing that failed the first time. A monitor that reads days-remaining turns this
into something that detects itself, and it is a few lines in a script that is already
making the connection.

This is a different task from the reminder: the reminder is "renew this specific cert
before 2026-10-23" (Omri's, on his Vercel account). This is "make the check able to
warn before an expiry instead of only after one", which is repo work needing nobody.
It is also distinct from bt-4e2a (wire probe-bt-5fb7.sh into a periodic monitor —
stale-deploy detection) and from bt-5149 (the domain monitor still checking the sunset
albumclub host).

DONE WHEN
- `check-fallback-cert.sh` reads the served certificate's `notAfter` (e.g. via
  `openssl s_client -connect "$HOST:443" -servername "$HOST" </dev/null 2>/dev/null`
  piped to `openssl x509 -noout -enddate`) and computes days remaining.
- It exits non-zero, with the host and the days-remaining in the message, when the cert
  expires in under a configurable threshold — default 21 days, enough to act on a
  Vercel-managed renewal that has not happened. The existing clean-404 assertion stays;
  this is an added condition, not a replacement.
- The failure path is distinguishable in the output from the existing TLS/connection
  failure, so whoever reads the alert knows whether it is "expiring" or "already broken".
- A fixture-driven case (a cert with a known `notAfter`, or a stubbed date source) so
  the threshold logic is proven without waiting for a real expiry — the same reason the
  original bug went unnoticed for a month.

VERIFY (from the main checkout, not a worktree — asserts a positive, and keeps stderr)
`cd /home/omri/projects/bass-tuner && bash scripts/check-fallback-cert.sh 2>&1`

## Log
- 2026-08-18 claimed by capacity-engine
