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
- 2026-08-13 ORDERING HAZARD — do not remove the check before the record is gone. Added 2026-08-13 14:12 (Main), raised by the board-refill sweep worker, verified by me.

This task's obvious closure is "delete the albumclub.omrihefez.com check, the site is sunset". Do not do that yet, and here is the specific reason, which this task could not have known:

An explicit DNS record for albumclub.omrihefez.com still exists — verified authoritatively today, `albumclub.omrihefez.com. 300 IN CNAME cname.vercel-dns-017.com.`, and distinguishable from mere wildcard coverage (it resolves to stably different A records than a control name, across repeated queries). iac-f8fe owns removing it.

So right now this daily alarm is the only thing in the estate watching a hostname that still has a live record pointing at Vercel with nothing claiming it. Close this first and the watcher goes before the record does — which is the wrong order, and silently so, because nothing else would notice.

TWO HONEST CAVEATS so nobody over-reads this into urgency:
- Because *.omrihefez.com is a wildcard, EVERY subdomain resolves to Vercel and returns the same DEPLOYMENT_NOT_FOUND. albumclub is not uniquely exposed relative to any other name, and the broader surface is the wildcard itself (iac-3162).
- The alarm firing daily is noise with a real function attached. That is an argument for sequencing, not for keeping it forever.

SEQUENCE: iac-f8fe removes the record -> confirm albumclub no longer resolves distinctly from a control name -> then close this by deleting the check. Alternatively iac-3162 removes the wildcard first, which subsumes both.

Cross-referenced: iac-f8fe points at this task; this note is the missing back-link so the dependency is visible from whichever end gets claimed first.
- 2026-08-13 WITHDRAWING MY OWN ORDERING HAZARD — the takeover risk I cited does not exist. 2026-08-13 19:44 (Main).

Earlier today I added a note here saying: do not delete the albumclub check yet, because it is "the only thing in the estate watching a hostname that still has a live record pointing at Vercel with nothing claiming it", and told you to sequence this behind iac-f8fe removing the record.

That reasoning was wrong, and iac-3162 found why. `vercel domains inspect omrihefez.com` shows the apex is registered in Omri's OWN Vercel account (omris-projects-b1cad393, registrar Vercel) — I re-verified this myself rather than taking the report. Vercel enforces a cross-account domain-ownership check, so a stranger cannot attach albumclub.omrihefez.com, or any other name the wildcard catches, to their own project without passing a TXT ownership challenge.

So there is no dangling-CNAME takeover surface here, and this watcher is not protecting against one. I inferred "resolves to Vercel + DEPLOYMENT_NOT_FOUND = claimable" without checking whether the platform gates the claim. It does.

WHAT IS STILL TRUE, so this is not a blanket retraction: an explicit albumclub CNAME does still exist (verified authoritatively, 300s TTL, distinguishable from wildcard coverage by its own A records), and removing it is worth doing as cleanup under iac-f8fe. It is tidiness, not security.

WHAT THAT MEANS FOR THIS TASK: the sequencing constraint I imposed is lifted. You can close this on its own merits whenever it makes sense — deleting a daily alarm for a sunset site is not gated on anything I raised. If you would still rather order it behind iac-f8fe simply to avoid alarming on a record that exists, that is a reasonable preference, but it is no longer a safety requirement and should not hold the task.

Apologies for the detour. The correction matters more than the original note did: a false security justification is exactly the thing that keeps noisy alarms alive for years.
