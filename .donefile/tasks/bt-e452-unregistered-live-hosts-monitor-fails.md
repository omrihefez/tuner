---
id: bt-e452
title: unregistered-live-hosts monitor fails daily — cron PATH can't find vercel binary
status: done
priority: p3
tags:
  - from-brief
created: 2026-10-15
filed:
  owner: morning-brief
  at: 2026-10-15T06:07:02Z
done:
  at: 2026-10-15T06:18:31Z
  by: capacity-engine
evidence:
  - type: commit
    value: 48c50f13d179c6ec78e0e8efa2486fcaebff448c
    verified: 2026-10-15T06:18:31Z
  - type: test
    cmd: cd /home/omri/projects/bass-tuner && bash scripts/check-unregistered-live-hosts.test.sh
    exit: 0
    at: 2026-10-15T06:18:30Z
    log: evidence/bt-e452-2026-10-15T06-18-30Z-test.txt
    sha256: ccd4e14cf1eba5219c22e534beb66416f69a1f861dd5729d2f31cd8c9fa20090
    bytes: 1533
  - type: note
    value: "Root cause confirmed and fix verified both ways under a simulated cron-minimal shell PATH,
      with the real vercel CLI, no stub: the original script (origin/main prior commit) exits 2
      CANNOT RUN with 'vercel alias list failed ... exit 2', matching today's 06:21 cron log; the
      fixed script exits 0 and lists all 15 live hosts as registered. Fix mirrors the existing
      bt-a428 pattern already used in renew-wildcard-cert.sh: export the bun bin dir onto PATH right
      after set -uo pipefail. All 7 existing stubbed test cases still pass."
---

scripts/check-unregistered-live-hosts.sh (added 2026-10-14, bt-1af4) has exited non-zero (CANNOT RUN) on every 06:21 cron run since it shipped, both 2026-10-14 and 2026-10-15 — the second day was only suppressed from the inbox digest by the alert-latch deduping identical output, not because it passed. Root cause confirmed by hand: the script shells out to a bare `vercel`, but cron's PATH (/usr/local/sbin:...:/bin) doesn't include ~/.bun/bin or ~/.local/bin, where the binary actually lives — `vercel whoami` works fine once that's added to PATH manually. Fix the script to resolve vercel via an explicit path or export the needed PATH additions at the top of the script, so cron can run it standalone. Done when: the next 06:21 cron run exits 0 or 1 (never 2/CANNOT RUN) without any manual PATH help.

Filed by the morning brief's intake pass.

## Log
- 2026-10-15 claimed by capacity-engine
- 2026-10-15 done by capacity-engine — commit 48c50f13d179, test `cd /home/omri/projects/bass-tuner && bash scripts/check-unregistered-live-hosts.test.sh` exit 0 (log: evidence/bt-e452-2026-10-15T06-18-30Z-test.txt)
