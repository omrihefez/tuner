---
id: bt-5149
title: Domain monitor still checks sunset albumclub.omrihefez.com, alarms daily
status: open
priority: p3
tags:
  - from-brief
created: 2026-08-09
---

scripts/audit-domains.sh's SUBS array still includes `albumclub`, so the daily cron (logged to /home/omri/.cache/bass-tuner-domain-audit.log) has produced a `CHECK albumclub.omrihefez.com -> 404` line every day since 2026-08-07. This is a false positive, not a live incident: /home/omri/projects/album-club/README.md (commit 5a777b2/ee2f2ab, 2026-08-07) confirms Album Club was deliberately sunset — Vercel project, DNS records, and the Neon prod DB were all intentionally deleted, code kept archived only. /home/omri/meni/DOMAIN.md (Meni-repo, main-only) still lists albumclub as '🟢 live public -> album-club' on line 24, same stale-registry pattern already fixed once for `tuner` (bt-78e6/bt-66d4) and flagged for meniapp (ma-f497). Done when: audit-domains.sh either drops `albumclub` from SUBS or treats 404 there as expected (same pattern as the already-sunset `apartments` row), DOMAIN.md's albumclub row is updated to reflect the sunset (same shape as the `apartments` row at line 25), and the next cron run produces zero CHECK lines for albumclub.

Filed by the morning brief's intake pass.

## Log
- 2026-08-13 DO NOT REMOVE THE CHECK YET — ordering hazard, added by Main 2026-08-13 05:00.

The obvious way to close this task is to delete the albumclub.omrihefez.com entry from
the domain monitor, since album-club was sunset on 2026-08-07 and the daily alarm looks
like pure noise. Do not do that first. Right now that alarm is the ONLY thing in the
estate watching that hostname, and the hostname is exposed.

Measured tonight:
    dig +short albumclub.omrihefez.com  -> cname.vercel-dns-017.com -> 216.198.79.65
    curl -sI https://albumclub.omrihefez.com -> HTTP 404, server: Vercel,
                                                x-vercel-error: DEPLOYMENT_NOT_FOUND

A live CNAME on his own domain pointing at Vercel with no project claiming it — subdomain
takeover shape. Tracked as iac-f8fe (iac board, raised to p1 tonight once measurement
resolved the fork): the record is still declared in terraform as
cloudflare_dns_record.cname_albumclub, so it also regenerates on apply if someone only
deletes it in the dashboard.

SEQUENCE:
  1. iac-f8fe removes the DNS record (and the terraform declaration, or it comes back).
  2. Confirm albumclub.omrihefez.com no longer resolves.
  3. THEN close this — at that point the check is genuinely watching nothing and deleting
     it is correct.

Reversing that order removes the monitoring before the hole is closed and turns a noisy
exposure into a silent one. The daily alarm is annoying precisely because it is doing its
job.

Cross-referenced deliberately: iac-f8fe's body now carries the reciprocal note, because
neither task could see this from its own side — the discovery worker that filed iac-f8fe
spotted the interaction and flagged it rather than letting two correct-looking closures
collide.
