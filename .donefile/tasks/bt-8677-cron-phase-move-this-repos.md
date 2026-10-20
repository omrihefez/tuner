---
id: bt-8677
title: "Cron phase: move this repo's */N and minute-0 cron jobs off minute 0 (df-6573 stampede)"
status: open
priority: p2
tags:
  - from-omri
  - reliability
  - cron
created: 2026-10-20
filed:
  owner: omri@ubuntu-4gb-nbg1-1
  at: 2026-10-20T09:58:51Z
---

Child of ~/meni df-6573 (from-omri, p1). Measured 2026-10-20 12:55 IDT against the live crontab: 43 cron entries fire at exactly minute 0 of 04:00, 00:00, 06:00, 10:00, 12:00 and 18:00 (247 entries total). Minute 0 is where every */N lines up (*/3, */5, */10, */15, */30 all share phase 0), so the box stampedes and capacity-engine pauses dispatch on load. Today alone it paused twice, and the pre-push gate flaked on load (ce-7264).

THIS BOARD's installers that contribute (crontab block labels):
  bass-tuner-ff-sync bass-tuner-monitoring

FIX, per installer: give each minute field a stable non-zero phase.
- `*/N` minute -> `K-59/N`, where K = a fixed value in 1..N-1 chosen per job, e.g. `$(( $(printf %s "<block-label>" | cksum | cut -d' ' -f1) % (N-1) + 1 ))`, computed ONCE and written as a literal into the installer. Do NOT compute it at install time, or the drift checker's expected line and the installed line can disagree.
- A literal `0` minute on an hourly or daily job -> any fixed minute 1..59 that is not 0, 30 or a multiple of 15.
- Keep the cadence identical. Only the phase moves.

Then re-run the installer so the live crontab block matches, and confirm that block's crontab-drift checker exits clean (each block has one at minute 37: check-crontab-drift.sh with that BLOCK_LABEL).

DONE WHEN: `crontab -l` shows none of this board's blocks firing at minute 0, i.e. no minute field equal to `0` or bare `*/N`; the drift checker for each changed block exits 0; and the change is pushed.
Verify: crontab -l | awk '/^# BEGIN <label>/,/^# END <label>/' | awk '!/^#/ && NF>5 && ($1=="0" || $1 ~ /^\*\/[0-9]+$/)' | wc -l  ->  0
