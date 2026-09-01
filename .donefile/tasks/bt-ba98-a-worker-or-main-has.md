---
id: bt-ba98
title: A worker or Main has an in-progress stash "bt-8e75 mic leak fix" (tuner.js) sitting unapplied
  in bass-tuner's shared .git — surfaced only because my worktree's stash pop hit it by accident.
  Worth checking whether that work is still wanted / should be applied properly.
status: done
priority: p3
tags:
  - ops
created: 2026-08-29
done:
  at: 2026-09-01T13:13:16Z
  by: capacity-engine/worker
evidence:
  - type: commit
    value: bfc2056
    verified: 2026-09-01T13:13:16Z
  - type: test
    cmd: grep -n setupErr /home/omri/projects/bass-tuner/tuner.js
    exit: 0
    at: 2026-09-01T13:13:16Z
    log: evidence/bt-ba98-2026-09-01T13-13-16Z-test.txt
    sha256: 7c8bdd2ee97675bd63a97e347ffa8d714fa131a8f7e6dde88d99d31788dd0961
    bytes: 119
  - type: note
    value: "not real / already fixed: the stash 'bt-8e75 mic leak fix' (created 2026-07-22 00:42:49,
      3min before commit) is byte-identical to bfc2056's diff, which is on origin/main and closed
      bt-8e75 done on 2026-07-21. Confirmed via diff bfc2056^..bfc2056 -- tuner.js == git stash show
      -p, identical. The worker who fixed bt-8e75 apparently stashed a WIP copy of the same edit and
      separately committed it, then never dropped the stash. Nothing was unapplied or lost --
      dropped the redundant stash (was b9b3884)."
---

Named in the finding: tuner.js

<!-- capacity-engine: provenance, not part of the finding -->
UNVERIFIED CLAIM — auto-filed by the capacity engine from a worker's FOLLOW-UP line. The title above is that worker's own belief at the end of a session, written once, never checked by anything else: a well-formed, confident sentence can still be flatly wrong. Verify it against this repo's CURRENT state before doing anything else, then scope it before claiming (ce-916b).

Discovered while working bt-7964, session `vendored-alert-latch-sh--f1755c`, dispatched on bass-tuner.
Reported 2026-08-29 — read any relative time in the title above ("this morning", "currently", "still", "right now") as dated from THAT day, not from when this task was filed.
Board choice is a GUESS: this follow-up names a file but the engine could not match it to exactly one board's repo, so it stayed on the dispatching board rather than being routed. Verify it belongs here before working it — it may need re-filing on the board that actually owns the named file (ce-3b8d).
That task's report closed DONE (commit 3a67407).

DONE WHEN: the finding above is either fixed and verified, or shown not to be real — say which in the closing evidence.

## Log
- 2026-09-01 claimed by capacity-engine
- 2026-09-01 done by capacity-engine/worker — commit bfc2056, test `grep -n setupErr /home/omri/projects/bass-tuner/tuner.js` exit 0 (log: evidence/bt-ba98-2026-09-01T13-13-16Z-test.txt)
