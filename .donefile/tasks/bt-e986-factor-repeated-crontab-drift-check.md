---
id: bt-e986
title: Factor repeated crontab-drift check boilerplate (83 lines >400 chars) into one shared wrapper
  script
status: done
priority: p3
tags:
  - cron
  - bass-tuner
created: 2026-10-20
filed:
  owner: capacity-engine
  at: 2026-10-20T14:29:14Z
reported: 2026-10-20
done:
  at: 2026-10-20T14:58:15Z
  by: capacity-engine/worker
evidence:
  - type: commit
    value: 54e69cf1c6c06202daaa6a487af1a2b7aaf76a7b
    verified: 2026-10-20T14:58:15Z
  - type: test
    cmd: cd /home/omri/projects/bass-tuner && bash scripts/run-crontab-drift.test.sh && bash
      scripts/crontab-empty-read-guard.test.sh
    exit: 0
    at: 2026-10-20T14:58:13Z
    log: evidence/bt-e986-2026-10-20T14-58-13Z-test.txt
    sha256: 4b87862f46bcb34d923c04918881706c91b37d85c78548e77ec63a44c7e09de4
    bytes: 1450
  - type: note
    value: "Scope: the 83 long crontab lines span ~30 repos' installers; only 3 are bass-tuner's
      (cert-renewal, ff-sync, monitoring). Their DRIFT_LINEs now call scripts/run-crontab-drift.sh
      <label> <installer> <state-dir> (~180-210 chars vs ~790 expanded). Other repos need the same
      on their own boards. Test fails if a line re-inlines BEGIN_MARK or exceeds 250 chars. Live
      crontab unchanged until installers are rerun. Feature commit 52df79c."
---

Why this is worth doing (from the reporting worker's own FOLLOW-UP line): each installer inlines BEGIN_MARK/END_MARK/mkdir drift check, up to 789 chars/line; cross-repo refactor

<!-- capacity-engine: provenance, not part of the finding -->
UNVERIFIED CLAIM — auto-filed by the capacity engine from a worker's FOLLOW-UP line. The title above is that worker's own belief at the end of a session, written once, never checked by anything else: a well-formed, confident sentence can still be flatly wrong. Verify it against this repo's CURRENT state before doing anything else, then scope it before claiming (ce-916b).

Discovered while working bt-3766, session `crontab-is-151kb-mostly--909238`, dispatched on bass-tuner.
See 'reported' in this task's frontmatter for the date this finding was originally observed — read any relative time in the title above ("this morning", "currently", "still", "right now") as dated from THAT day, not from when this task was filed.
That task's report closed DONE (commit 9ad1be6).

DONE WHEN: the finding above is either fixed and verified, or shown not to be real — say which in the closing evidence.

## Log
- 2026-10-20 claimed by capacity-engine
- 2026-10-20 done by capacity-engine/worker — commit 54e69cf1c6c0, test `cd /home/omri/projects/bass-tuner && bash scripts/run-crontab-drift.test.sh && bash scripts/crontab-empty-read-guard.test.sh` exit 0 (log: evidence/bt-e986-2026-10-20T14-58-13Z-test.txt)
