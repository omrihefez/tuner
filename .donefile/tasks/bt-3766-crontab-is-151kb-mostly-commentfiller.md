---
id: bt-3766
title: crontab is 151KB (mostly comment/filler?) and grows the SIGPIPE surface; audit for bloat | p3
  | bass-tuner,cron | wc -c = 151074 on 2026-10-20
status: open
priority: p2
created: 2026-10-20
filed:
  owner: capacity-engine
  at: 2026-10-20T14:22:29Z
reported: 2026-10-20
---

Named in the finding: comment/filler

Why this is worth doing (from the reporting worker's own FOLLOW-UP line): crontab -l

<!-- capacity-engine: provenance, not part of the finding -->
UNVERIFIED CLAIM — auto-filed by the capacity engine from a worker's FOLLOW-UP line. The title above is that worker's own belief at the end of a session, written once, never checked by anything else: a well-formed, confident sentence can still be flatly wrong. Verify it against this repo's CURRENT state before doing anything else, then scope it before claiming (ce-916b).

Discovered while working bt-67b8, session `test-monitoring-sh-fails-60d547`, dispatched on bass-tuner.
See 'reported' in this task's frontmatter for the date this finding was originally observed — read any relative time in the title above ("this morning", "currently", "still", "right now") as dated from THAT day, not from when this task was filed.
Board choice is a GUESS: this follow-up names a file but the engine could not match it to exactly one board's repo, so it stayed on the dispatching board rather than being routed. Verify it belongs here before working it — it may need re-filing on the board that actually owns the named file (ce-3b8d).
That task's report closed DONE (commit 646eac57e60b6c3139cbebee4a4daee8eb6fb3e4).

DONE WHEN: the finding above is either fixed and verified, or shown not to be real — say which in the closing evidence.
