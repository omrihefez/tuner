---
id: bt-dc36
title: ap-2037 (apartment, oauth's actual missing CSP/nosniff on the live host) is the companion fix
  this task's audit gap was hiding — still open per last check, worth prioritizing now that the
  auditor can see it
status: open
priority: p2
tags:
  - security
created: 2026-10-08
filed:
  owner: capacity-engine
  at: 2026-10-08T01:15:37Z
reported: 2026-10-08
---

Named in the finding: csp/nosniff

Why this is worth doing (from the reporting worker's own FOLLOW-UP line): this task only fixed the blind spot, not the live exposure it was failing to see

<!-- capacity-engine: provenance, not part of the finding -->
UNVERIFIED CLAIM — auto-filed by the capacity engine from a worker's FOLLOW-UP line. The title above is that worker's own belief at the end of a session, written once, never checked by anything else: a well-formed, confident sentence can still be flatly wrong. Verify it against this repo's CURRENT state before doing anything else, then scope it before claiming (ce-916b).

Discovered while working bt-0611, session `audit-domains-sh-exempts-2286c2`, dispatched on bass-tuner.
See 'reported' in this task's frontmatter for the date this finding was originally observed — read any relative time in the title above ("this morning", "currently", "still", "right now") as dated from THAT day, not from when this task was filed.
Board choice is a GUESS: this follow-up names a file but the engine could not match it to exactly one board's repo, so it stayed on the dispatching board rather than being routed. Verify it belongs here before working it — it may need re-filing on the board that actually owns the named file (ce-3b8d).
That task's report closed DONE (commit f5c1942).

DONE WHEN: the finding above is either fixed and verified, or shown not to be real — say which in the closing evidence.
