---
id: bt-b542
title: The heartbeat monitor that watches the other monitors has never existed — cron calls
  check-monitor-heartbeats.sh daily, exit 127
status: open
priority: p2
tags:
  - ops
  - monitoring
created: 2026-07-31
---

`crontab -l` has run since the monitoring crons were installed:

    0 7 * * * /home/omri/projects/bass-tuner/scripts/run-monitor.sh heartbeat \
              /home/omri/projects/bass-tuner/scripts/check-monitor-heartbeats.sh

That script does not exist and, per `git log -S check-monitor-heartbeats`, never did — no commit in this repo has ever added or removed it. So the monitor whose entire job is to notice when the OTHER monitors stop running has been failing with exit 127 every morning at 07:00 since installation.

Its only symptom is a note dropped into ~/inbox (that is how Main found it, 2026-07-31 — the note was sitting untracked in ~/meni/inbox/bass-tuner-heartbeat-2026-07-31.md, now committed). Nothing alerts, nothing goes red, and the other three monitors (fallback-cert, domain-audit, cert-renewal) have had NO liveness supervision this whole time. If any of them had silently stopped firing, the designated detector for that was itself broken.

WHAT TO DO — decide between two honest options rather than splitting the difference:
A. Write check-monitor-heartbeats.sh so it does the job the cron already assumes: read each monitor's log under the same convention run-monitor.sh uses, assert each has a fresh-enough entry, and alert (`bash ~/meni/bin/meni-notify`) when one is stale. This is the option the installed cron already promises.
B. If per-monitor heartbeats are not actually wanted, REMOVE the cron entry and the promise with it. A cron line calling a nonexistent script is a standing lie about what is being watched.

Either is fine. What is not fine is leaving a scheduled job that fails daily and reports only to a file nobody reads.

IF YOU BUILD IT (A): the heartbeat checker itself must be able to fail visibly, or you have rebuilt the same problem one level up — verify by deliberately staling one monitor's log and confirming you get the alert, and by pointing it at a nonexistent monitor and confirming it says so. A watchdog that has never been observed barking is not a watchdog.

Same family as the four silent controls found across this system on 2026-07-31 (fit-check.py passing on a zero-height measurement, two app dials writing to config keys nothing reads, CI never starting a job, and meni-hub-backup-offsite reporting success while replicating nothing). Memory: feedback_silent_controls_need_liveness_probes.
