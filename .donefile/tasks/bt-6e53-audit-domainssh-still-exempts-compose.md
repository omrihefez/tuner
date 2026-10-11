---
id: bt-6e53
title: audit-domains.sh still exempts compose and meni from the Permissions-Policy check a week
  after both started sending it, so two hosts are silently unchecked
status: open
priority: p2
tags:
  - monitoring
  - http-headers
created: 2026-10-11
filed:
  owner: meni-worker/board-refill-work-discov-d8813b
  at: 2026-10-11T15:15:48Z
---

`PERMISSIONS_POLICY_EXEMPT` (`scripts/audit-domains.sh:85-88`) still exempts two hosts that have
been sending the header for a week, so neither is checked for it any more — and the script's own
instructions say to remove the entries.

Found by the periodic discovery sweep, 2026-10-11, by probing the hosts the map names.

## The map, as it stands

    declare -A PERMISSIONS_POLICY_EXEMPT=(
      [compose]="cp-8845 2026-10-01"
      [meni]="ar-3426 2026-10-01"
    )

`missing_security_headers()` (line 110-112) skips the `permissions-policy` test entirely when the
caller's lookup is non-empty, and `check_nonvercel_path()` does the same lookup at line 429. So
both hosts are exempt on every path the audit probes.

## Measured live 2026-10-11 ~18:06-18:08 IDT

    curl -sI https://meni.omrihefez.com/
      permissions-policy: camera=(), microphone=(), geolocation=()

    curl -sI https://compose.omrihefez.com/
      permissions-policy: camera=(), microphone=(), geolocation=(), payment=(), usb=(), midi=()

Both sibling tasks are closed, checked with `donefile show` rather than read off a title:

    ar-3426  [meni-arch]  status: done   2026-10-08  (waiver quotes the live header)
    cp-8845  [compose]    status: done   2026-10-04  (live evidence: csp-live.test.js)

## Why this is a defect and not tidying

The map's own header comment, lines 79-84, prescribes the action and the reason:

> PERMISSIONS_POLICY_EXEMPT: the two hosts still measured absent today, each with the task that
> already tracks it and the date of this admission — a named, dated exemption, not a silent skip,
> so this baseline doesn't turn permanently red while those tasks are open. Remove the entry (not
> just flip it) once the sibling task lands and the host sends the header live; the host then
> falls through to the real check like everyone else.

The exemption was correct when written and is now load-bearing in the wrong direction: it is the
only thing standing between a Permissions-Policy regression on `meni.omrihefez.com` and the daily
`10 6` cron noticing. `meni` is a production auth surface that auto-deploys unattended every 20
minutes (meni-arch crontab `11,31,51`), which is precisely the shape where an unnoticed header
regression is likely — nobody is watching a deploy nobody triggered.

`bt-f55e` already set the precedent for the inverse case on this same file: it REMOVED
`arch-preview`'s entry rather than leaving it stale when the host's status changed, and said so in
a comment (lines 89-93). Same discipline, different map.

## DONE WHEN

1. Both entries are removed from `PERMISSIONS_POLICY_EXEMPT`, leaving the map empty rather than
   flipped or commented out.
2. `scripts/audit-domains.test.sh` gains a case asserting that a host NOT in the map and NOT
   sending the header is reported as DRIFT, and one asserting a host in the map is skipped — so
   the map's effect is pinned in both directions and a future entry cannot silently disable a
   check again.
3. A STALENESS GUARD, because removing these two by hand solves today and nothing else. The
   mechanism is already in this repo: `_auth_recovery_mechanisms_note`'s approach in
   capacity-engine (an entry whose `verified` date ages past a window fails the suite) is the
   shape. Cheapest form here: a test that, for every entry remaining in the map, curls the host
   and FAILS if it is now sending the header — so an entry that has outlived its reason turns the
   suite red instead of sitting quietly. Make it skip cleanly when the map is empty, and keep it
   out of the hermetic path if it needs network (name which suite it belongs to).
4. Run the live audit afterwards and confirm both hosts now reach the real check and pass it.

## Evidence

A check that FAILS before and passes after is available without any network at all — feed the
audit a stubbed response for `meni` with no `permissions-policy` line and require a DRIFT verdict.
On the current script that stub is skipped and reports clean; after the fix it is reported. Use
that, plus the live run:

    cd /home/omri/projects/bass-tuner && bash scripts/audit-domains.test.sh
    cd /home/omri/projects/bass-tuner && AUDIT_SUBS=meni bash scripts/audit-domains.sh

Do NOT close this on a grep showing the map is empty. That cannot fail once the commit exists, and
it says nothing about whether the hosts now reach the check.
