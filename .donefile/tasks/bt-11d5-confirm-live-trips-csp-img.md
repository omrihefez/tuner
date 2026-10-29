---
id: bt-11d5
title: "Confirm live trips CSP img-src has no bare https: after dev->main promotion, then run
  bass-tuner check-csp-strength.sh"
status: claimed
priority: p3
tags:
  - csp
  - verify
created: 2026-10-29
filed:
  owner: capacity-engine
  at: 2026-10-29T07:47:13Z
reported: 2026-10-29
claim:
  owner: capacity-engine
  at: 2026-10-29T07:48:51Z
---

Named in the finding: check-csp-strength.sh

Why this is worth doing (from the reporting worker's own FOLLOW-UP line): live header still shows 'https:' at 09:45 IST, dd9c4f0e not on origin/main yet

<!-- capacity-engine: provenance, not part of the finding -->
UNVERIFIED CLAIM — auto-filed by the capacity engine from a worker's FOLLOW-UP line. The title above is that worker's own belief at the end of a session, written once, never checked by anything else: a well-formed, confident sentence can still be flatly wrong. Verify it against this repo's CURRENT state before doing anything else, then scope it before claiming (ce-916b).

Discovered while working th-c4c1, session `trips-omrihefez-com-csp--c11bf7`, dispatched on trips-hub.
See 'reported' in this task's frontmatter for the date this finding was originally observed — read any relative time in the title above ("this morning", "currently", "still", "right now") as dated from THAT day, not from when this task was filed.
That task's report closed DONE (commit dd9c4f0e — does not resolve here, see below).

PROVENANCE COMMIT DOES NOT RESOLVE HERE — `dd9c4f0e` does not exist in this repo. It is the evidence commit from the task/board that raised this line, not this one — don't spend time trying to `git show` it here. Treat the finding above as UNVERIFIED and check whether it is still true against this repo's CURRENT state before doing anything else (ce-5112).

DONE WHEN: the finding above is either fixed and verified, or shown not to be real — say which in the closing evidence.

## Log
- 2026-10-29 claimed by capacity-engine
