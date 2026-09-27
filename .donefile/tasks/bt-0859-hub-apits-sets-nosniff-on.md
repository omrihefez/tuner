---
id: bt-0859
title: hub api.ts sets nosniff on only one route, not globally
status: open
priority: p3
tags:
  - security
  - monitoring
created: 2026-09-27
filed:
  owner: capacity-engine
  at: 2026-09-27T19:03:58Z
reported: 2026-09-27
---

Named in the finding: api.ts

Why this is worth doing (from the reporting worker's own FOLLOW-UP line): filed as ma-7c75, live curl confirms /health missing x-content-type-options

<!-- capacity-engine: provenance, not part of the finding -->
UNVERIFIED CLAIM — auto-filed by the capacity engine from a worker's FOLLOW-UP line. The title above is that worker's own belief at the end of a session, written once, never checked by anything else: a well-formed, confident sentence can still be flatly wrong. Verify it against this repo's CURRENT state before doing anything else, then scope it before claiming (ce-916b).

Discovered while working bt-d173, session `assert-live-security-hea-4436a2`, dispatched on bass-tuner.
See 'reported' in this task's frontmatter for the date this finding was originally observed — read any relative time in the title above ("this morning", "currently", "still", "right now") as dated from THAT day, not from when this task was filed.
Board choice is a GUESS: this follow-up names a file but the engine could not match it to exactly one board's repo, so it stayed on the dispatching board rather than being routed. Verify it belongs here before working it — it may need re-filing on the board that actually owns the named file (ce-3b8d).
That task's report closed DONE (commit 05a2c35855f462681688c280de268c2785f4419c).

DONE WHEN: the finding above is either fixed and verified, or shown not to be real — say which in the closing evidence.
