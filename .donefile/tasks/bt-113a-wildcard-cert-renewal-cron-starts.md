---
id: bt-113a
title: "Wildcard cert renewal cron starts renewing 2026-12-07 through the soft-blocked Vercel team,
  for a cert that now fronts no live site: verify or retire before then"
status: claimed
priority: p2
tags:
  - tls
  - vercel
  - monitoring
  - cross-board
created: 2026-11-26
filed:
  owner: meni-worker/board-refill-work-discov-727a75
  at: 2026-11-25T22:11:46Z
claim:
  owner: capacity-engine
  at: 2026-11-25T22:25:09Z
---

Found by the 2026-11-26 00:xx IST discovery sweep.

The weekly `renew-wildcard-cert.sh` cron (crontab: `17 6 * * 1 ... run-monitor.sh cert-renewal .../renew-wildcard-cert.sh`) renews the Vercel-hosted `*.omrihefez.com` cert through `vercel certs ls` / `vercel certs issue` once it is within 45 days of expiry. Its last run (2026-11-23 06:17, ~/.cache/bass-tuner-cert-renewal.log) read "59d left", which puts expiry around 2027-01-21 and the first renewal attempt on **Monday 2026-12-07** (the first Monday at or under 45 days).

Two things changed since that cron was designed:

1. The Vercel hobby team has been soft-blocked since 2026-11-24 23:29 (402 on every deployment; tkn-ecc6 recorded the softBlock). UNVERIFIED: whether `vercel certs issue` still works under a soft-block. This sweep cannot run the vercel CLI, so nobody has checked it. If it fails, the 2026-12-07 run goes red, and so does every run after it until expiry.
2. Every live site moved off Vercel onto the meni-hub tunnel (iac-dc38, ma-73fc, th-2957, iac-3089). Those hosts are proxied, so Cloudflare's edge cert serves them, not this one. What still terminates TLS on the Vercel wildcard cert is only: the apex (404 DEPLOYMENT_NOT_FOUND), paused kidai (402 DEPLOYMENT_DISABLED, measured 2026-11-26), and the wildcard tombstones (pete, arch-preview, composer...). Measured 2026-11-26: `curl -sI https://pete.omrihefez.com/` returns `server: Vercel`, 404.

So the job may be about to fail, renewing a cert that now protects no live surface. If the cert does lapse, the tombstone 404 assertions in ~/meni/bin/check-public-surfaces.sh and `check-fallback-cert.sh` (which watches composer.omrihefez.com as the wildcard witness) turn into TLS failures.

Decide before 2026-12-07, one of:
(a) Confirm `vercel certs ls` + `--challenge-only` still work under the soft-block (read-only checks, no issuance), and keep the cron.
(b) Retire the dependency: repoint `*.omrihefez.com` (and the apex) off `cname.vercel-dns-017.com` (iac owns the record) so tombstones answer from a non-Vercel origin, then retire renew-wildcard-cert.sh and re-scope check-fallback-cert.sh / the tombstone assertions to match.

DONE WHEN: (a) a dated note with real output of the read-only vercel checks under the soft-block, or (b) the wildcard no longer resolves to Vercel, the renewal cron line is removed through its installer, and the fallback-cert monitor plus tombstone assertions pass against the new origin. Either way, the 2026-12-07 run must not be the first time anyone finds out.


cross-board: names a file under 'meni' at /home/omri/meni — ~/meni is undispatched — route it via ~/inbox/meni-board-queue/ instead (see dn-334c).

## Log
- 2026-11-26 claimed by capacity-engine
- 2026-11-26 2026-11-26 00:3x IST (a) verified under soft-block: 'vercel certs ls' rc=0, lists *.omrihefez.com cert_JTyU8Xf5... exp in 57d renew=yes (+ older wildcard 24d, apex 87d/26d). 'vercel certs issue *.omrihefez.com --challenge-only --non-interactive' rc=0, 'issuance started', returned _acme-challenge TXT. So both calls the cron makes before DNS/issue work; the final non-challenge 'issue' step is untested (writes). Cron kept. Residual: wildcard still serves only tombstones; (b) retirement not needed.
