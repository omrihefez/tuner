---
id: bt-67b8
title: "test-monitoring.sh FAILs on unmodified main: renew-wildcard-cert.sh missing from crontab"
status: open
priority: p3
tags:
  - bass-tuner
  - cron
created: 2026-10-20
filed:
  owner: capacity-engine
  at: 2026-10-20T13:57:15Z
reported: 2026-10-20
---

Named in the finding: test-monitoring.sh, renew-wildcard-cert.sh

Why this is worth doing (from the reporting worker's own FOLLOW-UP line): same FAIL reproduces at origin/main, so it predates bt-8677

<!-- capacity-engine: provenance, not part of the finding -->
UNVERIFIED CLAIM — auto-filed by the capacity engine from a worker's FOLLOW-UP line. The title above is that worker's own belief at the end of a session, written once, never checked by anything else: a well-formed, confident sentence can still be flatly wrong. Verify it against this repo's CURRENT state before doing anything else, then scope it before claiming (ce-916b).

Discovered while working bt-8677, session `cron-phase-move-this-rep-a47110`, dispatched on bass-tuner.
See 'reported' in this task's frontmatter for the date this finding was originally observed — read any relative time in the title above ("this morning", "currently", "still", "right now") as dated from THAT day, not from when this task was filed.
Board choice is a GUESS: this follow-up names a file but the engine could not match it to exactly one board's repo, so it stayed on the dispatching board rather than being routed. Verify it belongs here before working it — it may need re-filing on the board that actually owns the named file (ce-3b8d).
That task's report closed DONE (commit adfbd2379b46c375cededff35b3047069291a2bf).

DONE WHEN: the finding above is either fixed and verified, or shown not to be real — say which in the closing evidence.
