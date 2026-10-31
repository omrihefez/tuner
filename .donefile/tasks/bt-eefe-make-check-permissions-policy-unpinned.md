---
id: bt-eefe
title: Make check-permissions-policy UNPINNED message name the task that owns the pin / require pin
  in same change as header addition
status: done
priority: p3
tags:
  - monitoring
created: 2026-10-31
filed:
  owner: capacity-engine
  at: 2026-10-31T19:27:56Z
reported: 2026-10-31
done:
  at: 2026-10-31T19:45:20Z
  by: capacity-engine/worker
evidence:
  - type: commit
    value: 6b2a85f
    verified: 2026-10-31T19:45:20Z
  - type: test
    cmd: cd /home/omri/projects/bass-tuner && bash scripts/check-permissions-policy.test.sh
    exit: 0
    at: 2026-10-31T19:45:19Z
    log: evidence/bt-eefe-2026-10-31T19-45-19Z-test.txt
    sha256: 0df4a6b0f491ed4e7f2b01d56e957090e292f77e650c60b7c53d61f1540f050e
    bytes: 1934
  - type: note
    value: UNPINNED now prints owner hint + paste-ready EXPECTED_PP line; new test assertions fail on
      the old script (verified).
---

Why this is worth doing (from the reporting worker's own FOLLOW-UP line): second time (bt-c33d, bt-0c09) a sibling repo's header change turned this monitor red unnoticed

<!-- capacity-engine: provenance, not part of the finding -->
UNVERIFIED CLAIM — auto-filed by the capacity engine from a worker's FOLLOW-UP line. The title above is that worker's own belief at the end of a session, written once, never checked by anything else: a well-formed, confident sentence can still be flatly wrong. Verify it against this repo's CURRENT state before doing anything else, then scope it before claiming (ce-916b).

Discovered while working bt-0c09, session `check-permissions-policy-35a5af`, dispatched on bass-tuner.
See 'reported' in this task's frontmatter for the date this finding was originally observed — read any relative time in the title above ("this morning", "currently", "still", "right now") as dated from THAT day, not from when this task was filed.
That task's report closed DONE (commit e97a63f).

DONE WHEN: the finding above is either fixed and verified, or shown not to be real — say which in the closing evidence.

## Log
- 2026-10-31 claimed by capacity-engine
- 2026-10-31 done by capacity-engine/worker — commit 6b2a85f, test `cd /home/omri/projects/bass-tuner && bash scripts/check-permissions-policy.test.sh` exit 0 (log: evidence/bt-eefe-2026-10-31T19-45-19Z-test.txt)
