---
id: bt-b38f
title: install-cert-renewal-cron.sh's cleanup strips ANY crontab line naming renew-wildcard-cert.sh,
  not just its own block
status: open
priority: p2
tags:
  - ops
  - safety
created: 2026-08-01
---

Flagged by the bt-3f5a worker and deliberately left unfixed as out of scope. Recording it as real work so it does not live only inside a closed task's body.

install-cert-renewal-cron.sh removes stray lines with a grep -vF on the renew-wildcard-cert.sh BASENAME, so it deletes any crontab entry mentioning that script anywhere — including entries outside its own managed block, and including a hand-written or differently-scheduled renewal someone added deliberately. install-monitoring-crons.sh does this correctly by name-scoping its cleanup to its own block; this installer should match that.

Why p2 rather than p3: the thing it can silently delete is the wildcard certificate renewal. bt-03ea already tracks that the Vercel wildcard cert will expire, and a cert that stops renewing fails silently until the sites go down. An installer whose cleanup can remove the renewal line is the same silent-control shape that cost a week of second-brain backups.

FIX: scope the cleanup to the managed block, the way install-monitoring-crons.sh does. Verify with a negative control — a crontab containing an UNMANAGED renew-wildcard-cert.sh line must survive a run of the installer, and the test must be shown to fail against the current code first.
