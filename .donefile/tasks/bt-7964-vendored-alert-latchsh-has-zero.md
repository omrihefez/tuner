---
id: bt-7964
title: Vendored alert-latch.sh has zero consumers here, so every monitor re-alarms daily on an
  unchanged condition instead of latching once
status: open
priority: p3
tags:
  - ops
  - monitoring
created: 2026-08-18
---

`scripts/lib/alert-latch.sh` and `scripts/lib/alert-latch.test.sh` are vendored
into this repo and NOTHING sources them. Verified 2026-08-18:

    grep -rn "alert-latch\|alert_latch" /home/omri/projects/bass-tuner \
      --include=*.sh --include=*.md --include=*.json -l
    -> scripts/lib/alert-latch.test.sh
       scripts/lib/alert-latch.sh

i.e. the only two hits are the library and its own test. No monitor, no cron
wrapper, no installer references it. For contrast, in meniapp every one of the
14 scripts that defines `LAST_ALERT_FILE` also sources `lib/alert-latch.sh`,
and trips-hub's copy is sourced by `check-vercel-git-disconnected.sh` and
`vps-bookkeeping-secret-scan.sh`. bass-tuner is the only repo carrying the
library with zero consumers.

WHAT THE MONITORS DO INSTEAD, and why it is not equivalent.
`scripts/run-monitor.sh` (bt-a942) is the shared wrapper for
`check-fallback-cert.sh`, `audit-domains.sh`, `check-monitor-heartbeats.sh` and
`check-heartbeat-liveness.sh`. Its dedupe key is the DATE:

    INBOX="$HOME/inbox/bass-tuner-${NAME}-$(date -I).md"     # run-monitor.sh:27

One inbox file per monitor per day. That correctly stops a same-day rerun from
double-alerting, and its header says so. What it does NOT do is notice that the
condition is unchanged: a failure that persists raises a fresh inbox item every
single day, indefinitely, with no acknowledgement path. `alert-latch.sh`
latches on a sha256 fingerprint of the failure SET, so a persistent condition
alerts once and only re-alerts when the set actually changes — that is the
whole difference between the two mechanisms.

This is not hypothetical for this repo. bt-5149's title is the observed
consequence, in its own words: "Domain monitor still checks sunset
albumclub.omrihefez.com, **alarms daily**." A fingerprint latch would have
raised that once instead of once a day until someone edited the list. It is the
same family as the meni board's df-c7a1 ("Audit every cron-driven notifier on
this box for notify-on-tick — ... buried Omri's thread under ~50 false
alerts overnight"), one notch less severe: per-day rather than per-tick.

Also worth noting: meniapp's `check-vendored-guard-drift.sh` maintains vendored
copies across repos, but its manifest (line 50) covers only
`scripts/check-crontab-drift.sh`, listing "tik-api trips-hub second-brain iac
bass-tuner". `alert-latch.sh` is not in that manifest, so these three copies are
neither drift-checked nor, here, used. Nothing today would tell anyone this file
is dead.

DECIDE ONE OF TWO, then do it — do not leave it as-is:

  (A) WIRE IT UP. Have `run-monitor.sh` fingerprint the monitor's output and
      latch on it via `lib/alert-latch.sh`, keeping the dated inbox path as the
      delivery mechanism. Preferred if the daily repeat is unwanted, which
      bt-5149 suggests it is. Note ma-c1b2's rule while doing this: never latch
      an alert that was not actually delivered.

  (B) DELETE IT. Remove `scripts/lib/alert-latch.sh` and its test, and record in
      the commit message that bass-tuner deliberately uses run-monitor.sh's
      per-day dedupe instead. Correct if the daily repeat is wanted here (these
      are low-frequency infra monitors and a daily nag may be the point).

Either way, ALSO add `scripts/lib/alert-latch.sh` to
`meniapp/scripts/check-vendored-guard-drift.sh`'s manifest for the repos that
DO use it (meniapp, trips-hub), so the remaining copies cannot silently fork.

DONE WHEN
1. Option A or B is implemented and the commit message says which and why.
2. The grep above no longer shows a library with only itself and its test as
   consumers: under (A) at least one monitor sources it; under (B) the files
   are gone.
3. If (A): a test asserts a persistent identical failure produces exactly one
   alert across two consecutive simulated days, and a CHANGED failure set
   produces a second one. Must fail against current HEAD.
4. Evidence command runs from `/home/omri/projects/bass-tuner`, not a worktree.

## Log
- 2026-08-26 blocker bt-a942 closed 2026-07-30T05:35:07Z — recheck whether this can proceed now.
- 2026-08-26 blocker bt-5149 closed 2026-08-15T03:23:40Z — recheck whether this can proceed now.
- 2026-08-26 blocker bt-a942 closed 2026-07-30T05:35:07Z — recheck whether this can proceed now.
- 2026-08-26 blocker bt-5149 closed 2026-08-15T03:23:40Z — recheck whether this can proceed now.
- 2026-08-26 blocker bt-a942 closed 2026-07-30T05:35:07Z — recheck whether this can proceed now.
- 2026-08-26 blocker bt-5149 closed 2026-08-15T03:23:40Z — recheck whether this can proceed now.
- 2026-08-26 blocker bt-a942 closed 2026-07-30T05:35:07Z — recheck whether this can proceed now.
- 2026-08-26 blocker bt-5149 closed 2026-08-15T03:23:40Z — recheck whether this can proceed now.
- 2026-08-26 blocker bt-a942 closed 2026-07-30T05:35:07Z — recheck whether this can proceed now.
- 2026-08-26 blocker bt-5149 closed 2026-08-15T03:23:40Z — recheck whether this can proceed now.
- 2026-08-26 blocker bt-a942 closed 2026-07-30T05:35:07Z — recheck whether this can proceed now.
- 2026-08-26 blocker bt-5149 closed 2026-08-15T03:23:40Z — recheck whether this can proceed now.
- 2026-08-26 blocker bt-a942 closed 2026-07-30T05:35:07Z — recheck whether this can proceed now.
- 2026-08-26 blocker bt-5149 closed 2026-08-15T03:23:40Z — recheck whether this can proceed now.
- 2026-08-26 blocker bt-a942 closed 2026-07-30T05:35:07Z — recheck whether this can proceed now.
- 2026-08-26 blocker bt-5149 closed 2026-08-15T03:23:40Z — recheck whether this can proceed now.
- 2026-08-26 blocker bt-a942 closed 2026-07-30T05:35:07Z — recheck whether this can proceed now.
- 2026-08-26 blocker bt-5149 closed 2026-08-15T03:23:40Z — recheck whether this can proceed now.
- 2026-08-26 blocker bt-a942 closed 2026-07-30T05:35:07Z — recheck whether this can proceed now.
- 2026-08-26 blocker bt-5149 closed 2026-08-15T03:23:40Z — recheck whether this can proceed now.
- 2026-08-26 blocker bt-a942 closed 2026-07-30T05:35:07Z — recheck whether this can proceed now.
- 2026-08-26 blocker bt-5149 closed 2026-08-15T03:23:40Z — recheck whether this can proceed now.
- 2026-08-26 blocker bt-a942 closed 2026-07-30T05:35:07Z — recheck whether this can proceed now.
- 2026-08-26 blocker bt-5149 closed 2026-08-15T03:23:40Z — recheck whether this can proceed now.
- 2026-08-26 blocker bt-a942 closed 2026-07-30T05:35:07Z — recheck whether this can proceed now.
- 2026-08-26 blocker bt-5149 closed 2026-08-15T03:23:40Z — recheck whether this can proceed now.
- 2026-08-26 blocker bt-a942 closed 2026-07-30T05:35:07Z — recheck whether this can proceed now.
- 2026-08-26 blocker bt-5149 closed 2026-08-15T03:23:40Z — recheck whether this can proceed now.
- 2026-08-26 blocker bt-a942 closed 2026-07-30T05:35:07Z — recheck whether this can proceed now.
- 2026-08-26 blocker bt-5149 closed 2026-08-15T03:23:40Z — recheck whether this can proceed now.
- 2026-08-26 blocker bt-a942 closed 2026-07-30T05:35:07Z — recheck whether this can proceed now.
- 2026-08-26 blocker bt-5149 closed 2026-08-15T03:23:40Z — recheck whether this can proceed now.
- 2026-08-26 blocker bt-a942 closed 2026-07-30T05:35:07Z — recheck whether this can proceed now.
- 2026-08-26 blocker bt-5149 closed 2026-08-15T03:23:40Z — recheck whether this can proceed now.
- 2026-08-26 blocker bt-a942 closed 2026-07-30T05:35:07Z — recheck whether this can proceed now.
- 2026-08-26 blocker bt-5149 closed 2026-08-15T03:23:40Z — recheck whether this can proceed now.
- 2026-08-26 blocker bt-a942 closed 2026-07-30T05:35:07Z — recheck whether this can proceed now.
- 2026-08-26 blocker bt-5149 closed 2026-08-15T03:23:40Z — recheck whether this can proceed now.
- 2026-08-26 blocker bt-a942 closed 2026-07-30T05:35:07Z — recheck whether this can proceed now.
- 2026-08-26 blocker bt-5149 closed 2026-08-15T03:23:40Z — recheck whether this can proceed now.
- 2026-08-26 blocker bt-a942 closed 2026-07-30T05:35:07Z — recheck whether this can proceed now.
- 2026-08-26 blocker bt-5149 closed 2026-08-15T03:23:40Z — recheck whether this can proceed now.
- 2026-08-26 blocker bt-a942 closed 2026-07-30T05:35:07Z — recheck whether this can proceed now.
- 2026-08-26 blocker bt-5149 closed 2026-08-15T03:23:40Z — recheck whether this can proceed now.
- 2026-08-26 blocker bt-a942 closed 2026-07-30T05:35:07Z — recheck whether this can proceed now.
- 2026-08-26 blocker bt-5149 closed 2026-08-15T03:23:40Z — recheck whether this can proceed now.
- 2026-08-26 blocker bt-a942 closed 2026-07-30T05:35:07Z — recheck whether this can proceed now.
- 2026-08-26 blocker bt-5149 closed 2026-08-15T03:23:40Z — recheck whether this can proceed now.
- 2026-08-27 blocker bt-a942 closed 2026-07-30T05:35:07Z — recheck whether this can proceed now.
- 2026-08-27 blocker bt-5149 closed 2026-08-15T03:23:40Z — recheck whether this can proceed now.
- 2026-08-27 blocker bt-a942 closed 2026-07-30T05:35:07Z — recheck whether this can proceed now.
