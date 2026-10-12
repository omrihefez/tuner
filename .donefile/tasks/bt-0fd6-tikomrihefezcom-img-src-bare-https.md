---
id: bt-0fd6
title: "tik.omrihefez.com img-src bare https: wildcard"
status: claimed
priority: p3
tags:
  - security
  - monitoring
created: 2026-10-12
filed:
  owner: capacity-engine
  at: 2026-10-12T03:58:41Z
reported: 2026-10-12
claim:
  owner: capacity-engine
  at: 2026-10-12T04:06:57Z
---

Why this is worth doing (from the reporting worker's own FOLLOW-UP line): filed as tkn-4fcf on tik-next's own board, no equivalent task existed; trips' matching finding is already covered by th-36aa/th-90d8/th-db0a

LIKELY ALREADY DONE — verify before building. Work merged after this finding was raised may already cover it:
- `46c38490` 2026-10-12 "bt-5059: add check-csp-strength.sh -- fleet had no CSP directive-strength monitor" — scripts/check-csp-strength.sh, scripts/check-csp-strength.test.sh, scripts/install-monitoring-crons.sh (100% of the finding's words)

START HERE: check whether that work satisfies this finding. If it does, close with `--commit <sha>` and say so — that is a complete, correct closure, not a shortcut. If it does not, say in one line what it missed and do the work.
This is a word/file-path heuristic run at filing time, NOT a proof — it exists so the claimer starts from "verify" instead of spending a whole round rediscovering that it shipped (ce-a792).

<!-- capacity-engine: provenance, not part of the finding -->
UNVERIFIED CLAIM — auto-filed by the capacity engine from a worker's FOLLOW-UP line. The title above is that worker's own belief at the end of a session, written once, never checked by anything else: a well-formed, confident sentence can still be flatly wrong. Verify it against this repo's CURRENT state before doing anything else, then scope it before claiming (ce-916b).

Discovered while working bt-5059, session `nothing-in-the-fleet-che-74277b`, dispatched on bass-tuner.
See 'reported' in this task's frontmatter for the date this finding was originally observed — read any relative time in the title above ("this morning", "currently", "still", "right now") as dated from THAT day, not from when this task was filed.
That task's report closed DONE (commit 1c91710ca28bc8f3c7e0429722a934c3ca659141).

DONE WHEN: the finding above is either fixed and verified, or shown not to be real — say which in the closing evidence.

## Log
- 2026-10-12 claimed by capacity-engine
