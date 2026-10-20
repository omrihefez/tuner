---
id: bt-b71d
title: Make the stale-checkout guard skippable per-test so render-changing commits don't need an
  ALLOW_STALE_CRONTAB_WRITE workaround
status: done
priority: p3
tags:
  - cron
  - tests
created: 2026-10-20
filed:
  owner: capacity-engine
  at: 2026-10-20T15:04:23Z
reported: 2026-10-20
done:
  at: 2026-10-20T15:28:44Z
  by: capacity-engine
evidence:
  - type: test
    cmd: cd /home/omri/projects/bass-tuner && bash scripts/crontab-empty-read-guard.test.sh && grep -q
      "ALLOW_STALE_CRONTAB_WRITE=1" scripts/crontab-empty-read-guard.test.sh
    exit: 0
    at: 2026-10-20T15:28:42Z
    log: evidence/bt-b71d-2026-10-20T15-28-42Z-test.txt
    sha256: e96beb17fd8f85f98baabf5acb92ea150f5f7893603876193744302ddb03ac1d
    bytes: 1264
  - type: note
    value: "already fixed by bt-e986 (54e69cf): test sets ALLOW_STALE_CRONTAB_WRITE=1 on its own
      installer runs, so render-changing commits push without a manual workaround. Premise dead;
      test passes fresh (12 checks)."
---

Why this is worth doing (from the reporting worker's own FOLLOW-UP line): crontab-empty-read-guard.test.sh failed pre-push on this change because the guard compares against origin/main's render

<!-- capacity-engine: provenance, not part of the finding -->
UNVERIFIED CLAIM — auto-filed by the capacity engine from a worker's FOLLOW-UP line. The title above is that worker's own belief at the end of a session, written once, never checked by anything else: a well-formed, confident sentence can still be flatly wrong. Verify it against this repo's CURRENT state before doing anything else, then scope it before claiming (ce-916b).

Discovered while working bt-e986, session `factor-repeated-crontab--f53ff5`, dispatched on bass-tuner.
See 'reported' in this task's frontmatter for the date this finding was originally observed — read any relative time in the title above ("this morning", "currently", "still", "right now") as dated from THAT day, not from when this task was filed.
That task's report closed DONE (commit 54e69cf1c6c06202daaa6a487af1a2b7aaf76a7b).

DONE WHEN: the finding above is either fixed and verified, or shown not to be real — say which in the closing evidence.

## Log
- 2026-10-20 claimed by capacity-engine
- 2026-10-20 done by capacity-engine — test `cd /home/omri/projects/bass-tuner && bash scripts/crontab-empty-read-guard.test.sh && grep -q "ALLOW_STALE_CRONTAB_WRITE=1" scripts/crontab-empty-read-guard.test.sh` exit 0 (log: evidence/bt-b71d-2026-10-20T15-28-42Z-test.txt)
