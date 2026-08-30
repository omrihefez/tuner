---
id: bt-91e2
title: bass-tuner main checkout has a stale staged .donefile/config.yml + bt-3143 evidence-file diff
  sitting uncommitted since 2026-08-15 (bt-8e12/bt-3143, both already done) — commit or discard it
status: done
priority: p3
tags:
  - bass-tuner
  - bookkeeping
created: 2026-08-23
done:
  at: 2026-08-30T22:51:49Z
  by: capacity-engine/worker
evidence:
  - type: commit
    value: cec3f28
    verified: 2026-08-30T22:51:49Z
  - type: test
    cmd: git -C /home/omri/projects/bass-tuner status --porcelain
    exit: 0
    at: 2026-08-30T22:51:49Z
    log: evidence/bt-91e2-2026-08-30T22-51-49Z-test.txt
    sha256: efe2f1eea2812d5377c201df3e3b6492443f3a17a83f275b720b7412bd6f8e7f
    bytes: 60
  - type: note
    value: "not real / already fixed: the staged .donefile/config.yml + bt-3143 evidence diff was
      already committed in cec3f28 (donefile: register the meni repo alias, and bt-3143 evidence),
      well before this task was dispatched. Verified git status -sb and git diff --cached --stat
      both clean, main up to date with origin/main."
---

Named in the finding: donefile/config.yml, bt-8e12/bt-3143

<!-- capacity-engine: provenance, not part of the finding -->
UNVERIFIED CLAIM — auto-filed by the capacity engine from a worker's FOLLOW-UP line. The title above is that worker's own belief at the end of a session, written once, never checked by anything else: a well-formed, confident sentence can still be flatly wrong. Verify it against this repo's CURRENT state before doing anything else, then scope it before claiming (ce-916b).

Discovered while working bt-d5e2, session `donefile-pre-push-hook-s-c44156`, dispatched on bass-tuner.
Reported 2026-08-23 — read any relative time in the title above ("this morning", "currently", "still", "right now") as dated from THAT day, not from when this task was filed.
Board choice is a GUESS: this follow-up names a file but the engine could not match it to exactly one board's repo, so it stayed on the dispatching board rather than being routed. Verify it belongs here before working it — it may need re-filing on the board that actually owns the named file (ce-3b8d).
That task's report closed DONE (commit 8ff147a — does not resolve here, see below).

PROVENANCE COMMIT DOES NOT RESOLVE HERE — `8ff147a` does not exist in this repo. It is the evidence commit from the task/board that raised this line, not this one — don't spend time trying to `git show` it here. Treat the finding above as UNVERIFIED and check whether it is still true against this repo's CURRENT state before doing anything else (ce-5112).

DONE WHEN: the finding above is either fixed and verified, or shown not to be real — say which in the closing evidence.

## Log
- 2026-08-26 blocker bt-3143 closed 2026-08-15T15:04:20Z — recheck whether this can proceed now.
- 2026-08-26 blocker bt-d5e2 closed 2026-08-22T21:50:13Z — recheck whether this can proceed now.
- 2026-08-26 blocker bt-8e12 closed 2026-08-15T03:31:05Z — recheck whether this can proceed now.
- 2026-08-26 blocker bt-3143 closed 2026-08-15T15:04:20Z — recheck whether this can proceed now.
- 2026-08-26 blocker bt-d5e2 closed 2026-08-22T21:50:13Z — recheck whether this can proceed now.
- 2026-08-26 blocker bt-8e12 closed 2026-08-15T03:31:05Z — recheck whether this can proceed now.
- 2026-08-26 blocker bt-3143 closed 2026-08-15T15:04:20Z — recheck whether this can proceed now.
- 2026-08-26 blocker bt-d5e2 closed 2026-08-22T21:50:13Z — recheck whether this can proceed now.
- 2026-08-26 blocker bt-8e12 closed 2026-08-15T03:31:05Z — recheck whether this can proceed now.
- 2026-08-26 blocker bt-3143 closed 2026-08-15T15:04:20Z — recheck whether this can proceed now.
- 2026-08-26 blocker bt-d5e2 closed 2026-08-22T21:50:13Z — recheck whether this can proceed now.
- 2026-08-26 blocker bt-8e12 closed 2026-08-15T03:31:05Z — recheck whether this can proceed now.
- 2026-08-26 blocker bt-3143 closed 2026-08-15T15:04:20Z — recheck whether this can proceed now.
- 2026-08-26 blocker bt-d5e2 closed 2026-08-22T21:50:13Z — recheck whether this can proceed now.
- 2026-08-26 blocker bt-8e12 closed 2026-08-15T03:31:05Z — recheck whether this can proceed now.
- 2026-08-26 blocker bt-3143 closed 2026-08-15T15:04:20Z — recheck whether this can proceed now.
- 2026-08-26 blocker bt-d5e2 closed 2026-08-22T21:50:13Z — recheck whether this can proceed now.
- 2026-08-26 blocker bt-8e12 closed 2026-08-15T03:31:05Z — recheck whether this can proceed now.
- 2026-08-26 blocker bt-3143 closed 2026-08-15T15:04:20Z — recheck whether this can proceed now.
- 2026-08-26 blocker bt-d5e2 closed 2026-08-22T21:50:13Z — recheck whether this can proceed now.
- 2026-08-26 blocker bt-8e12 closed 2026-08-15T03:31:05Z — recheck whether this can proceed now.
- 2026-08-26 blocker bt-3143 closed 2026-08-15T15:04:20Z — recheck whether this can proceed now.
- 2026-08-26 blocker bt-d5e2 closed 2026-08-22T21:50:13Z — recheck whether this can proceed now.
- 2026-08-26 blocker bt-8e12 closed 2026-08-15T03:31:05Z — recheck whether this can proceed now.
- 2026-08-26 blocker bt-3143 closed 2026-08-15T15:04:20Z — recheck whether this can proceed now.
- 2026-08-26 blocker bt-d5e2 closed 2026-08-22T21:50:13Z — recheck whether this can proceed now.
- 2026-08-26 blocker bt-8e12 closed 2026-08-15T03:31:05Z — recheck whether this can proceed now.
- 2026-08-26 blocker bt-3143 closed 2026-08-15T15:04:20Z — recheck whether this can proceed now.
- 2026-08-26 blocker bt-d5e2 closed 2026-08-22T21:50:13Z — recheck whether this can proceed now.
- 2026-08-26 blocker bt-8e12 closed 2026-08-15T03:31:05Z — recheck whether this can proceed now.
- 2026-08-26 blocker bt-3143 closed 2026-08-15T15:04:20Z — recheck whether this can proceed now.
- 2026-08-26 blocker bt-d5e2 closed 2026-08-22T21:50:13Z — recheck whether this can proceed now.
- 2026-08-26 blocker bt-8e12 closed 2026-08-15T03:31:05Z — recheck whether this can proceed now.
- 2026-08-26 blocker bt-3143 closed 2026-08-15T15:04:20Z — recheck whether this can proceed now.
- 2026-08-26 blocker bt-d5e2 closed 2026-08-22T21:50:13Z — recheck whether this can proceed now.
- 2026-08-26 blocker bt-8e12 closed 2026-08-15T03:31:05Z — recheck whether this can proceed now.
- 2026-08-26 blocker bt-3143 closed 2026-08-15T15:04:20Z — recheck whether this can proceed now.
- 2026-08-26 blocker bt-d5e2 closed 2026-08-22T21:50:13Z — recheck whether this can proceed now.
- 2026-08-26 blocker bt-8e12 closed 2026-08-15T03:31:05Z — recheck whether this can proceed now.
- 2026-08-26 blocker bt-3143 closed 2026-08-15T15:04:20Z — recheck whether this can proceed now.
- 2026-08-26 blocker bt-d5e2 closed 2026-08-22T21:50:13Z — recheck whether this can proceed now.
- 2026-08-26 blocker bt-8e12 closed 2026-08-15T03:31:05Z — recheck whether this can proceed now.
- 2026-08-26 blocker bt-3143 closed 2026-08-15T15:04:20Z — recheck whether this can proceed now.
- 2026-08-26 blocker bt-d5e2 closed 2026-08-22T21:50:13Z — recheck whether this can proceed now.
- 2026-08-26 blocker bt-8e12 closed 2026-08-15T03:31:05Z — recheck whether this can proceed now.
- 2026-08-26 blocker bt-3143 closed 2026-08-15T15:04:20Z — recheck whether this can proceed now.
- 2026-08-26 blocker bt-d5e2 closed 2026-08-22T21:50:13Z — recheck whether this can proceed now.
- 2026-08-26 blocker bt-8e12 closed 2026-08-15T03:31:05Z — recheck whether this can proceed now.
- 2026-08-26 blocker bt-3143 closed 2026-08-15T15:04:20Z — recheck whether this can proceed now.
- 2026-08-26 blocker bt-d5e2 closed 2026-08-22T21:50:13Z — recheck whether this can proceed now.
- 2026-08-26 blocker bt-8e12 closed 2026-08-15T03:31:05Z — recheck whether this can proceed now.
- 2026-08-26 blocker bt-3143 closed 2026-08-15T15:04:20Z — recheck whether this can proceed now.
- 2026-08-26 blocker bt-d5e2 closed 2026-08-22T21:50:13Z — recheck whether this can proceed now.
- 2026-08-26 blocker bt-8e12 closed 2026-08-15T03:31:05Z — recheck whether this can proceed now.
- 2026-08-26 blocker bt-3143 closed 2026-08-15T15:04:20Z — recheck whether this can proceed now.
- 2026-08-26 blocker bt-d5e2 closed 2026-08-22T21:50:13Z — recheck whether this can proceed now.
- 2026-08-26 blocker bt-8e12 closed 2026-08-15T03:31:05Z — recheck whether this can proceed now.
- 2026-08-26 blocker bt-3143 closed 2026-08-15T15:04:20Z — recheck whether this can proceed now.
- 2026-08-26 blocker bt-d5e2 closed 2026-08-22T21:50:13Z — recheck whether this can proceed now.
- 2026-08-26 blocker bt-8e12 closed 2026-08-15T03:31:05Z — recheck whether this can proceed now.
- 2026-08-26 blocker bt-3143 closed 2026-08-15T15:04:20Z — recheck whether this can proceed now.
- 2026-08-26 blocker bt-d5e2 closed 2026-08-22T21:50:13Z — recheck whether this can proceed now.
- 2026-08-26 blocker bt-8e12 closed 2026-08-15T03:31:05Z — recheck whether this can proceed now.
- 2026-08-26 blocker bt-3143 closed 2026-08-15T15:04:20Z — recheck whether this can proceed now.
- 2026-08-26 blocker bt-d5e2 closed 2026-08-22T21:50:13Z — recheck whether this can proceed now.
- 2026-08-26 blocker bt-8e12 closed 2026-08-15T03:31:05Z — recheck whether this can proceed now.
- 2026-08-26 blocker bt-3143 closed 2026-08-15T15:04:20Z — recheck whether this can proceed now.
- 2026-08-26 blocker bt-d5e2 closed 2026-08-22T21:50:13Z — recheck whether this can proceed now.
- 2026-08-26 blocker bt-8e12 closed 2026-08-15T03:31:05Z — recheck whether this can proceed now.
- 2026-08-26 blocker bt-3143 closed 2026-08-15T15:04:20Z — recheck whether this can proceed now.
- 2026-08-26 blocker bt-d5e2 closed 2026-08-22T21:50:13Z — recheck whether this can proceed now.
- 2026-08-26 blocker bt-8e12 closed 2026-08-15T03:31:05Z — recheck whether this can proceed now.
- 2026-08-27 blocker bt-3143 closed 2026-08-15T15:04:20Z — recheck whether this can proceed now.
- 2026-08-27 blocker bt-d5e2 closed 2026-08-22T21:50:13Z — recheck whether this can proceed now.
- 2026-08-27 blocker bt-8e12 closed 2026-08-15T03:31:05Z — recheck whether this can proceed now.
- 2026-08-27 blocker bt-3143 closed 2026-08-15T15:04:20Z — recheck whether this can proceed now.
- 2026-08-27 blocker bt-d5e2 closed 2026-08-22T21:50:13Z — recheck whether this can proceed now.
- 2026-08-27 blocker bt-8e12 closed 2026-08-15T03:31:05Z — recheck whether this can proceed now.
- 2026-08-27 blocker bt-3143 closed 2026-08-15T15:04:20Z — recheck whether this can proceed now.
- 2026-08-27 blocker bt-d5e2 closed 2026-08-22T21:50:13Z — recheck whether this can proceed now.
- 2026-08-27 blocker bt-8e12 closed 2026-08-15T03:31:05Z — recheck whether this can proceed now.
- 2026-08-27 blocker bt-3143 closed 2026-08-15T15:04:20Z — recheck whether this can proceed now.
- 2026-08-27 blocker bt-d5e2 closed 2026-08-22T21:50:13Z — recheck whether this can proceed now.
- 2026-08-27 blocker bt-8e12 closed 2026-08-15T03:31:05Z — recheck whether this can proceed now.
- 2026-08-27 blocker bt-3143 closed 2026-08-15T15:04:20Z — recheck whether this can proceed now.
- 2026-08-27 blocker bt-d5e2 closed 2026-08-22T21:50:13Z — recheck whether this can proceed now.
- 2026-08-27 blocker bt-8e12 closed 2026-08-15T03:31:05Z — recheck whether this can proceed now.
- 2026-08-27 blocker bt-3143 closed 2026-08-15T15:04:20Z — recheck whether this can proceed now.
- 2026-08-27 blocker bt-d5e2 closed 2026-08-22T21:50:13Z — recheck whether this can proceed now.
- 2026-08-27 blocker bt-8e12 closed 2026-08-15T03:31:05Z — recheck whether this can proceed now.
- 2026-08-27 blocker bt-3143 closed 2026-08-15T15:04:20Z — recheck whether this can proceed now.
- 2026-08-27 blocker bt-d5e2 closed 2026-08-22T21:50:13Z — recheck whether this can proceed now.
- 2026-08-27 blocker bt-8e12 closed 2026-08-15T03:31:05Z — recheck whether this can proceed now.
- 2026-08-27 blocker bt-3143 closed 2026-08-15T15:04:20Z — recheck whether this can proceed now.
- 2026-08-27 blocker bt-d5e2 closed 2026-08-22T21:50:13Z — recheck whether this can proceed now.
- 2026-08-27 blocker bt-8e12 closed 2026-08-15T03:31:05Z — recheck whether this can proceed now.
- 2026-08-27 blocker bt-3143 closed 2026-08-15T15:04:20Z — recheck whether this can proceed now.
- 2026-08-27 blocker bt-d5e2 closed 2026-08-22T21:50:13Z — recheck whether this can proceed now.
- 2026-08-27 blocker bt-8e12 closed 2026-08-15T03:31:05Z — recheck whether this can proceed now.
- 2026-08-27 blocker bt-3143 closed 2026-08-15T15:04:20Z — recheck whether this can proceed now.
- 2026-08-27 blocker bt-d5e2 closed 2026-08-22T21:50:13Z — recheck whether this can proceed now.
- 2026-08-27 blocker bt-8e12 closed 2026-08-15T03:31:05Z — recheck whether this can proceed now.
- 2026-08-27 blocker bt-3143 closed 2026-08-15T15:04:20Z — recheck whether this can proceed now.
- 2026-08-27 blocker bt-d5e2 closed 2026-08-22T21:50:13Z — recheck whether this can proceed now.
- 2026-08-27 blocker bt-8e12 closed 2026-08-15T03:31:05Z — recheck whether this can proceed now.
- 2026-08-27 blocker bt-3143 closed 2026-08-15T15:04:20Z — recheck whether this can proceed now.
- 2026-08-27 blocker bt-d5e2 closed 2026-08-22T21:50:13Z — recheck whether this can proceed now.
- 2026-08-27 blocker bt-8e12 closed 2026-08-15T03:31:05Z — recheck whether this can proceed now.
- 2026-08-27 blocker bt-3143 closed 2026-08-15T15:04:20Z — recheck whether this can proceed now.
- 2026-08-27 blocker bt-d5e2 closed 2026-08-22T21:50:13Z — recheck whether this can proceed now.
- 2026-08-27 blocker bt-8e12 closed 2026-08-15T03:31:05Z — recheck whether this can proceed now.
- 2026-08-27 blocker bt-3143 closed 2026-08-15T15:04:20Z — recheck whether this can proceed now.
- 2026-08-27 blocker bt-d5e2 closed 2026-08-22T21:50:13Z — recheck whether this can proceed now.
- 2026-08-27 blocker bt-8e12 closed 2026-08-15T03:31:05Z — recheck whether this can proceed now.
- 2026-08-27 blocker bt-3143 closed 2026-08-15T15:04:20Z — recheck whether this can proceed now.
- 2026-08-27 blocker bt-d5e2 closed 2026-08-22T21:50:13Z — recheck whether this can proceed now.
- 2026-08-27 blocker bt-8e12 closed 2026-08-15T03:31:05Z — recheck whether this can proceed now.
- 2026-08-27 blocker bt-3143 closed 2026-08-15T15:04:20Z — recheck whether this can proceed now.
- 2026-08-27 blocker bt-d5e2 closed 2026-08-22T21:50:13Z — recheck whether this can proceed now.
- 2026-08-27 blocker bt-8e12 closed 2026-08-15T03:31:05Z — recheck whether this can proceed now.
- 2026-08-27 blocker bt-3143 closed 2026-08-15T15:04:20Z — recheck whether this can proceed now.
- 2026-08-27 blocker bt-d5e2 closed 2026-08-22T21:50:13Z — recheck whether this can proceed now.
- 2026-08-27 blocker bt-8e12 closed 2026-08-15T03:31:05Z — recheck whether this can proceed now.
- 2026-08-27 blocker bt-3143 closed 2026-08-15T15:04:20Z — recheck whether this can proceed now.
- 2026-08-27 blocker bt-d5e2 closed 2026-08-22T21:50:13Z — recheck whether this can proceed now.
- 2026-08-27 blocker bt-8e12 closed 2026-08-15T03:31:05Z — recheck whether this can proceed now.
- 2026-08-27 blocker bt-3143 closed 2026-08-15T15:04:20Z — recheck whether this can proceed now.
- 2026-08-27 blocker bt-d5e2 closed 2026-08-22T21:50:13Z — recheck whether this can proceed now.
- 2026-08-27 blocker bt-8e12 closed 2026-08-15T03:31:05Z — recheck whether this can proceed now.
- 2026-08-27 blocker bt-3143 closed 2026-08-15T15:04:20Z — recheck whether this can proceed now.
- 2026-08-27 blocker bt-d5e2 closed 2026-08-22T21:50:13Z — recheck whether this can proceed now.
- 2026-08-27 blocker bt-8e12 closed 2026-08-15T03:31:05Z — recheck whether this can proceed now.
- 2026-08-27 blocker bt-3143 closed 2026-08-15T15:04:20Z — recheck whether this can proceed now.
- 2026-08-27 blocker bt-d5e2 closed 2026-08-22T21:50:13Z — recheck whether this can proceed now.
- 2026-08-27 blocker bt-8e12 closed 2026-08-15T03:31:05Z — recheck whether this can proceed now.
- 2026-08-27 blocker bt-3143 closed 2026-08-15T15:04:20Z — recheck whether this can proceed now.
- 2026-08-27 blocker bt-d5e2 closed 2026-08-22T21:50:13Z — recheck whether this can proceed now.
- 2026-08-27 blocker bt-8e12 closed 2026-08-15T03:31:05Z — recheck whether this can proceed now.
- 2026-08-27 blocker bt-3143 closed 2026-08-15T15:04:20Z — recheck whether this can proceed now.
- 2026-08-27 blocker bt-d5e2 closed 2026-08-22T21:50:13Z — recheck whether this can proceed now.
- 2026-08-27 blocker bt-8e12 closed 2026-08-15T03:31:05Z — recheck whether this can proceed now.
- 2026-08-27 blocker bt-3143 closed 2026-08-15T15:04:20Z — recheck whether this can proceed now.
- 2026-08-27 blocker bt-d5e2 closed 2026-08-22T21:50:13Z — recheck whether this can proceed now.
- 2026-08-27 blocker bt-8e12 closed 2026-08-15T03:31:05Z — recheck whether this can proceed now.
- 2026-08-31 claimed by capacity-engine
- 2026-08-31 done by capacity-engine/worker — commit cec3f28, test `git -C /home/omri/projects/bass-tuner status --porcelain` exit 0 (log: evidence/bt-91e2-2026-08-30T22-51-49Z-test.txt)
