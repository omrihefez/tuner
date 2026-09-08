---
id: bt-6773
title: "pre-push gate 'hub-auto-restart: node_modules lock' fails on every real push, passes
  standalone (ma-cf06 regression)"
status: claimed
priority: p1
tags:
  - hub
  - bug (filed as ma-b35d on meniapp)
created: 2026-09-08
filed:
  owner: capacity-engine
  at: 2026-09-08T17:31:52Z
claim:
  owner: capacity-engine
  at: 2026-09-08T18:11:14Z
---

POSSIBLE CROSS-BOARD DUPLICATE — ma-b35d on meniapp (open, 90% title match) looks like the same finding. This filed anyway because that match is scored WITHOUT the repo-identity check same-board dedupe relies on (ce-916b: routing had no signal for either finding to place it confidently), so it's a pointer to check, not a confirmed dup. START HERE: read ma-b35d before doing any work — if it already covers this, close with a note saying so instead of redoing it.

<!-- capacity-engine: provenance, not part of the finding -->
UNVERIFIED CLAIM — auto-filed by the capacity engine from a worker's FOLLOW-UP line. The title above is that worker's own belief at the end of a session, written once, never checked by anything else: a well-formed, confident sentence can still be flatly wrong. Verify it against this repo's CURRENT state before doing anything else, then scope it before claiming (ce-916b).

Discovered while working bt-ea85, session `ff-sync-main-checkout-sh-f8fde6`, dispatched on bass-tuner.
Reported 2026-09-08 — read any relative time in the title above ("this morning", "currently", "still", "right now") as dated from THAT day, not from when this task was filed.
That task's report closed DONE (commit b54d8816ad19f4fc86a9a68918e7e2a1b7b1af07).

DONE WHEN: the finding above is either fixed and verified, or shown not to be real — say which in the closing evidence.

## Log
- 2026-09-08 claimed by capacity-engine
