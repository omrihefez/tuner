---
id: bt-0c09
title: "check-permissions-policy.sh red 20 days running: meniapp-api, tik-api, tik-api-vps never
  pinned in EXPECTED_PP"
status: done
priority: p2
tags:
  - monitoring
created: 2026-10-31
filed:
  owner: meni-worker/board-refill-work-discov-d93724
  at: 2026-10-31T18:59:45Z
done:
  at: 2026-10-31T19:24:09Z
  by: capacity-engine
evidence:
  - type: commit
    value: e97a63f
    verified: 2026-10-31T19:24:09Z
  - type: test
    cmd: cd /home/omri/projects/bass-tuner && scripts/check-permissions-policy.sh
    exit: 0
    at: 2026-10-31T19:24:00Z
    log: evidence/bt-0c09-2026-10-31T19-24-00Z-test.txt
    sha256: c77bb6fa0764310367eed96812e9ce9c9728448751df6077d8d5eb55ec0f7966
    bytes: 1722
  - type: note
    value: Pinned meniapp-api, tik-api, tik-api-vps in EXPECTED_PP. Script exited 1 before (3 UNPINNED),
      0 after.
---

`scripts/check-permissions-policy.sh` (cron `16 6 * * *` via `run-monitor.sh permissions-policy`) has exited 1 on EVERY daily run since 2026-10-12 06:16 — 20 consecutive red runs, per `~/.cache/bass-tuner-permissions-policy.log`. The alert latch `~/.cache/bass-tuner-permissions-policy.alert-latch` is dated 2026-10-12, so it alerted once and has been silent since.

Cause: not drift. Three hosts now send the estate-baseline header but have no `EXPECTED_PP` entry, so they report UNPINNED:

    UNPINNED meniapp-api.omrihefez.com -> sends Permissions-Policy: camera=(), microphone=(), geolocation=()
    UNPINNED tik-api.omrihefez.com     -> same value
    UNPINNED tik-api-vps.omrihefez.com -> same value

Those headers were added on purpose by tk-8c48 (tik-api, done) and ma-00bf (meniapp, done). Nobody pinned them afterwards. Same shape as bt-c33d (brain went UNPINNED after sb-6f36 added its header, fixed by 5757a93).

Why it matters: a monitor that is red every day for a known-benign reason stops being read. A real drift on another host would change the failure fingerprint and alert, but anyone looking at the log or the heartbeat sees "red for 3 weeks" and learns to ignore it.

DONE WHEN:
1. `EXPECTED_PP` in `scripts/check-permissions-policy.sh` has entries for `meniapp-api`, `tik-api` and `tik-api-vps`, each with the trailing reason comment the block requires (estate baseline, added by tk-8c48 / ma-00bf).
2. `scripts/check-permissions-policy.sh` exits 0 against the live registry.
3. Consider (optional, worth a sentence in the close note): the sibling repos that add a header should pin it in the same change, or the check should name the task that would own the pin. This is the second time the same handoff gap has turned this monitor red.

Evidence shape: `cd /home/omri/projects/bass-tuner && scripts/check-permissions-policy.sh` exits 0; it exited 1 before the change (the log above is the before-state).

## Log
- 2026-10-31 claimed by capacity-engine
- 2026-10-31 done by capacity-engine — commit e97a63f, test `cd /home/omri/projects/bass-tuner && scripts/check-permissions-policy.sh` exit 0 (log: evidence/bt-0c09-2026-10-31T19-24-00Z-test.txt)
