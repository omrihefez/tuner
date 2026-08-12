---
id: bt-ed7f
title: renew-wildcard-cert.sh (weekly cron) mutates real Cloudflare DNS + issues prod TLS cert from
  a live, dirty-able checkout — same execute-from-checkout hole as ce-0bda
status: claimed
priority: p2
tags:
  - reliability
  - infra
created: 2026-08-09
claim:
  owner: capacity-engine
  at: 2026-08-12T14:21:37Z
---

Audited from ce-e338 (capacity-engine board).

scripts/renew-wildcard-cert.sh runs weekly (Mon 06:17, via run-monitor.sh) directly from the live /home/omri/projects/bass-tuner checkout. On the NORMAL, unconfirmed cron path (no --force needed) — when the wildcard cert is within 45 days of expiry — it automatically: fetches CLOUDFLARE_API_TOKEN from Infisical, deletes and recreates _acme-challenge TXT records on the real Cloudflare zone, and calls vercel certs issue to complete real ACME issuance for the production *.omrihefez.com wildcard cert (fronts every *.omrihefez.com service). No decoupling from the live working tree — an uncommitted edit sitting in this checkout would run for real on the next weekly tick. The --force path is separately gated behind --i-mean-it, but that gate is irrelevant to the normal cron trigger, which needs no confirmation at all.

This is the same architecture ce-0bda fixed for capacity-engine's dispatcher tick, applied to DNS/TLS for the domain that fronts the whole meni fleet.

SUGGESTED FIX: pin/verify against a git-archive export of HEAD before running the mutating (DNS + cert-issue) branch, or at minimum add a 'refuse to run if the bass-tuner checkout has uncommitted non-bookkeeping changes' guard — cheap, additive, same shape as the fix this worker landed in second-brain (see second-brain@a299a79 prune-fleet-worktrees.sh for a worked example).

DONE WHEN: the DNS+cert-issue mutation path either runs from a pinned/verified export of HEAD, or refuses to run when the bass-tuner checkout is dirty in a non-bookkeeping way.

## Log
- 2026-08-11 claimed by capacity-engine
- 2026-08-11 released by capacity-engine
- 2026-08-12 claimed by capacity-engine
