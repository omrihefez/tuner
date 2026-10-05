---
id: bt-0803
title: run-monitor-latch.test.sh leaks one ~/.cache log per run — 90+ strays since 2026-08-29,
  outnumbering the real monitor logs 10:1
status: open
priority: p3
tags:
  - hygiene
  - monitoring
created: 2026-10-05
filed:
  owner: meni-worker/board-refill-work-discov-fc64ea
  at: 2026-10-05T10:47:37Z
---

`scripts/run-monitor-latch.test.sh:21` names its fixture monitor after its own PID:

    NAME="latch-test-bt7964-$$"

`run-monitor.sh:45` then derives the log path from that name —
`LOG="$HOME/.cache/bass-tuner-${NAME}.log"` — so every single run of the latch test
creates a NEW `~/.cache/bass-tuner-latch-test-bt7964-<pid>.log` that nothing ever
removes. A fresh PID per run means the files never collide and never get reused; they
only accumulate.

MEASURED 2026-10-05 via
`find -L /home/omri/.cache -maxdepth 1 -name 'bass-tuner-latch-test-bt7964-*'`:
90+ such files in a single listing, oldest 2026-08-29, newest 2026-10-05 08:35 —
i.e. steadily growing for five weeks and still growing today. Alongside them the same
prefix has left `bass-tuner-latch-selftest-bt7964.log` and
`bass-tuner-latch-selftest-bt7964-preflight.log`.

WHY IT MATTERS BEYOND TIDINESS, and this is the part worth fixing rather than
ignoring: `~/.cache` is on the ext4 ROOT DISK, and `check-monitor-heartbeats.sh`
discovers nothing — but a human or a future script globbing
`~/.cache/bass-tuner-*.log` to enumerate monitors now has to filter ~90 fixtures out
of ~7 real monitor logs. The real signal is outnumbered better than ten to one in the
directory the monitoring system keeps its state in. `disk-janitor`/`disk-prune` run
nightly and are not reaping these.

This is NOT df-0d08 (meni board, "nothing prunes volmount cache npm/bun/uv caches") —
different producer, different directory, different mechanism. This one is a test
fixture that does not clean up after itself.

DONE WHEN: `run-monitor-latch.test.sh` removes the log(s) it created before it exits
AND the ~90 existing strays are cleared. Prefer a trap that cannot be skipped on the
failure path, but note the box trap: a bare `exec` or a SIGKILL runs no EXIT trap, so
cleanup-on-exit can never be complete on its own — the test should ALSO sweep
`bass-tuner-latch-test-bt7964-*` files from earlier runs whose PID is dead
(`kill -0`), so a concurrent run's live fixture is never deleted out from under it.

EVIDENCE MUST BE ABLE TO FAIL: close with a check that counts the strays and asserts
zero, run AFTER a full test run — it is RED today. Use the counting shape that cannot
be tripped by absence itself:

    N=$(find -L "$HOME/.cache" -maxdepth 1 -name 'bass-tuner-latch-test-bt7964-*' -printf x | wc -c); [ "$N" = "0" ]

Assertion LAST — a trailing `echo` would force exit 0 regardless. Do not use
`ls -d ... | wc -l`: `ls -d` on an absent path exits 2 and under `pipefail` the
pipeline fails while printing `0`, which reads as a failure on exactly the clean
result you want.
