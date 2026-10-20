---
id: bt-e986
title: Factor repeated crontab-drift check boilerplate (83 lines >400 chars) into one shared wrapper
  script
status: open
priority: p3
tags:
  - cron
  - bass-tuner
created: 2026-10-20
filed:
  owner: capacity-engine
  at: 2026-10-20T14:29:14Z
reported: 2026-10-20
---

Why this is worth doing (from the reporting worker's own FOLLOW-UP line): each installer inlines BEGIN_MARK/END_MARK/mkdir drift check, up to 789 chars/line; cross-repo refactor

<!-- capacity-engine: provenance, not part of the finding -->
UNVERIFIED CLAIM — auto-filed by the capacity engine from a worker's FOLLOW-UP line. The title above is that worker's own belief at the end of a session, written once, never checked by anything else: a well-formed, confident sentence can still be flatly wrong. Verify it against this repo's CURRENT state before doing anything else, then scope it before claiming (ce-916b).

Discovered while working bt-3766, session `crontab-is-151kb-mostly--909238`, dispatched on bass-tuner.
See 'reported' in this task's frontmatter for the date this finding was originally observed — read any relative time in the title above ("this morning", "currently", "still", "right now") as dated from THAT day, not from when this task was filed.
That task's report closed DONE (commit 9ad1be6).

DONE WHEN: the finding above is either fixed and verified, or shown not to be real — say which in the closing evidence.
