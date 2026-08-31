---
id: bt-c050
title: Install iac's ff-sync cron (scripts/install-ff-sync-cron.sh, already on origin/main at
  841dcb1) once /home/omri/projects/iac's live checkout is back on main
status: done
priority: p3
tags:
  - infra
  - cron
created: 2026-08-28
done:
  at: 2026-08-31T23:51:26Z
  by: capacity-engine/worker
evidence:
  - type: test
    cmd: crontab -l | grep -A1 'BEGIN iac-ff-sync (scripts/install-ff-sync-cron.sh)' | grep -q
      'ff-sync-main-checkout.sh'
    exit: 0
    at: 2026-08-31T23:51:25Z
    log: evidence/bt-c050-2026-08-31T23-51-25Z-test.txt
    sha256: f5f95a5cd990e22b6d4f5ed9fac6ef7835050f9290d1a7b6580664687cf0eae2
    bytes: 116
  - type: note
    value: iac's ff-sync cron script (scripts/install-ff-sync-cron.sh, iac origin/main@841dcb1) already
      existed but the crontab only had an EMPTY iac-ff-sync marker block (never actually installed).
      iac's live checkout is confirmed on main (HEAD 757c416, 841dcb1 is an ancestor). Ran 'bash
      scripts/install-ff-sync-cron.sh' in /home/omri/projects/iac; the */3min cron line is now
      present, and ff-sync-main-checkout.sh ran manually with exit 0 ('in sync at 757c416'). No code
      change/commit — this was a one-time crontab install (idempotent, --remove available).
---

Named in the finding: scripts/install-ff-sync-cron.sh, origin/main, home/omri/projects/iac

LIKELY ALREADY DONE — verify before building. Work merged after this finding was raised may already cover it:
- `4e17ae8f` 2026-08-28 "Add ff-sync cron for the main checkout (bt-31a9)" — scripts/ff-sync-main-checkout.sh, scripts/install-ff-sync-cron.sh (touches scripts/install-ff-sync-cron.sh; 63% of the finding's words)

START HERE: check whether that work satisfies this finding. If it does, close with `--commit <sha>` and say so — that is a complete, correct closure, not a shortcut. If it does not, say in one line what it missed and do the work.
This is a word/file-path heuristic run at filing time, NOT a proof — it exists so the claimer starts from "verify" instead of spending a whole round rediscovering that it shipped (ce-a792).

<!-- capacity-engine: provenance, not part of the finding -->
UNVERIFIED CLAIM — auto-filed by the capacity engine from a worker's FOLLOW-UP line. The title above is that worker's own belief at the end of a session, written once, never checked by anything else: a well-formed, confident sentence can still be flatly wrong. Verify it against this repo's CURRENT state before doing anything else, then scope it before claiming (ce-916b).

Discovered while working bt-31a9, session `bass-tuner-s-10-cron-job-d24ddc`, dispatched on bass-tuner.
Reported 2026-08-28 — read any relative time in the title above ("this morning", "currently", "still", "right now") as dated from THAT day, not from when this task was filed.
Board choice is a GUESS: this follow-up names a file but the engine could not match it to exactly one board's repo, so it stayed on the dispatching board rather than being routed. Verify it belongs here before working it — it may need re-filing on the board that actually owns the named file (ce-3b8d).
That task's report closed DONE (commit 4e17ae8).

DONE WHEN: the finding above is either fixed and verified, or shown not to be real — say which in the closing evidence.

## Log
- 2026-09-01 claimed by capacity-engine
- 2026-09-01 released by capacity-engine
- 2026-09-01 claimed by capacity-engine
- 2026-09-01 done by capacity-engine/worker — test `crontab -l | grep -A1 'BEGIN iac-ff-sync (scripts/install-ff-sync-cron.sh)' | grep -q 'ff-sync-main-checkout.sh'` exit 0 (log: evidence/bt-c050-2026-08-31T23-51-25Z-test.txt)
