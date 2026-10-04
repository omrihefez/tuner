---
id: bt-2499
title: compose.omrihefez.com HSTS/Permissions-Policy still open
status: done
priority: p3
tags:
  - security
  - http-headers
created: 2026-10-04
filed:
  owner: capacity-engine
  at: 2026-10-04T06:54:19Z
reported: 2026-10-04
done:
  at: 2026-10-04T07:06:59Z
  by: capacity-engine/worker
  waived: "no bass-tuner-specific commit: bt-2499's bass-tuner half was already fixed by bt-4d32
    (594d5527); the remainder (compose.omrihefez.com) is tracked separately as cp-8845 on the
    compose board, not bass-tuner work"
evidence:
  - type: test
    cmd: "set -o pipefail; curl -sI https://tuner.omrihefez.com/ | grep -i '^strict-transport-security:
      max-age=31536000; includeSubDomains'"
    exit: 0
    at: 2026-10-04T07:06:58Z
    log: evidence/bt-2499-2026-10-04T07-06-58Z-test.txt
    sha256: ef283792f74731e194f200f91298f5f9357dac117979ebde414bf6aefe00d1cf
    bytes: 198
  - type: note
    value: "not real as a bass-tuner task: tuner.omrihefez.com HSTS already fixed by bt-4d32 (commit
      594d5527). Remaining finding is compose.omrihefez.com's Permissions-Policy/HSTS gap, a
      different repo/host already tracked as cp-8845 (open, p3, compose board). bt-2499 is a
      misfiled duplicate reference, not additional bass-tuner work."
---

Named in the finding: hsts/permissions-policy

Why this is worth doing (from the reporting worker's own FOLLOW-UP line): that's cp-8845 on the compose board, unrelated repo, not fixed by this task — just retitled to drop the now-false "only one" claim

<!-- capacity-engine: provenance, not part of the finding -->
UNVERIFIED CLAIM — auto-filed by the capacity engine from a worker's FOLLOW-UP line. The title above is that worker's own belief at the end of a session, written once, never checked by anything else: a well-formed, confident sentence can still be flatly wrong. Verify it against this repo's CURRENT state before doing anything else, then scope it before claiming (ce-916b).

Discovered while working bt-4d32, session `tuner-omrihefez-com-hsts-3191b7`, dispatched on bass-tuner.
See 'reported' in this task's frontmatter for the date this finding was originally observed — read any relative time in the title above ("this morning", "currently", "still", "right now") as dated from THAT day, not from when this task was filed.
Board choice is a GUESS: this follow-up names a file but the engine could not match it to exactly one board's repo, so it stayed on the dispatching board rather than being routed. Verify it belongs here before working it — it may need re-filing on the board that actually owns the named file (ce-3b8d).
That task's report closed DONE (commit 594d5527687b79683b6fb0fe8674b6fa8b5f1ee8).

DONE WHEN: the finding above is either fixed and verified, or shown not to be real — say which in the closing evidence.

## Log
- 2026-10-04 claimed by capacity-engine
- 2026-10-04 done by capacity-engine/worker — test `set -o pipefail; curl -sI https://tuner.omrihefez.com/ | grep -i '^strict-transport-security: max-age=31536000; includeSubDomains'` exit 0 (log: evidence/bt-2499-2026-10-04T07-06-58Z-test.txt) (evidence waived: no bass-tuner-specific commit: bt-2499's bass-tuner half was already fixed by bt-4d32 (594d5527); the remainder (compose.omrihefez.com) is tracked separately as cp-8845 on the compose board, not bass-tuner work)
