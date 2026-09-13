---
id: bt-443d
title: fix compose.omrihefez.com's missing security headers (CSP, X-Frame-Options,
  X-Content-Type-Options, Referrer-Policy, wildcard CORS)
status: claimed
priority: p3
tags:
  - security
  - cross-board — compose is boardless
  - so this needs filing to ~/inbox/meni-board-queue/ or Main's own action
  - not a bass-tuner board task
created: 2026-09-11
filed:
  owner: capacity-engine
  at: 2026-09-10T21:24:04Z
claim:
  owner: capacity-engine
  at: 2026-09-13T15:56:00Z
---

LIKELY ALREADY DONE — verify before building. Work merged after this finding was raised may already cover it:
- `0532fc85` 2026-09-11 "audit-domains.sh: assert security-header baseline per host (bt-a2c2)" — scripts/audit-domains.sh, scripts/audit-domains.test.sh (87% of the finding's words)

START HERE: check whether that work satisfies this finding. If it does, close with `--commit <sha>` and say so — that is a complete, correct closure, not a shortcut. If it does not, say in one line what it missed and do the work.
Priority lowered p2 -> p3 on that match alone; raise it back if the finding turns out to be real (ce-a792).
This is a word/file-path heuristic run at filing time, NOT a proof — it exists so the claimer starts from "verify" instead of spending a whole round rediscovering that it shipped (ce-a792).

<!-- capacity-engine: provenance, not part of the finding -->
UNVERIFIED CLAIM — auto-filed by the capacity engine from a worker's FOLLOW-UP line. The title above is that worker's own belief at the end of a session, written once, never checked by anything else: a well-formed, confident sentence can still be flatly wrong. Verify it against this repo's CURRENT state before doing anything else, then scope it before claiming (ce-916b).

Discovered while working bt-a2c2, session `audit-domains-sh-discard-a0a9a5`, dispatched on bass-tuner.
Reported 2026-09-11 — read any relative time in the title above ("this morning", "currently", "still", "right now") as dated from THAT day, not from when this task was filed.
That task's report closed DONE (commit 0532fc85b906e85ef0f2bf6c8c4088a75494fe75).

DONE WHEN: the finding above is either fixed and verified, or shown not to be real — say which in the closing evidence.

## Log
- 2026-09-11 blocker bt-a2c2 closed 2026-09-10T21:20:20Z — recheck whether this can proceed now.
- 2026-09-13 claimed by capacity-engine
