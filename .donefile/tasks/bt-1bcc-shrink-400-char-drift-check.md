---
id: bt-1bcc
title: Shrink >400-char drift-check lines in other repos' installers (bass-tuner, etc.)
status: open
priority: p3
tags:
  - cron
created: 2026-10-20
filed:
  owner: capacity-engine
  at: 2026-10-20T15:52:50Z
reported: 2026-10-20
---

Why this is worth doing (from the reporting worker's own FOLLOW-UP line): 66 of 67 live long lines are non-trips-hub blocks (the 67th is trips-hub-alias-drift); trips-hub's own lines are already <400

<!-- capacity-engine: provenance, not part of the finding -->
UNVERIFIED CLAIM — auto-filed by the capacity engine from a worker's FOLLOW-UP line. The title above is that worker's own belief at the end of a session, written once, never checked by anything else: a well-formed, confident sentence can still be flatly wrong. Verify it against this repo's CURRENT state before doing anything else, then scope it before claiming (ce-916b).

Discovered while working th-08fb, session `reinstall-live-crontab-f-a00569`, dispatched on trips-hub.
See 'reported' in this task's frontmatter for the date this finding was originally observed — read any relative time in the title above ("this morning", "currently", "still", "right now") as dated from THAT day, not from when this task was filed.
This finding named multiple repos explicitly and was filed separately on each: also on meni-arch, iac (ce-71de). Scope this task to the part that is actually about trips-hub; the siblings cover the rest.
That task's report closed DONE (commit edcf1017 — does not resolve here, see below).

PROVENANCE COMMIT DOES NOT RESOLVE HERE — `edcf1017` does not exist in this repo. It is the evidence commit from the task/board that raised this line, not this one — don't spend time trying to `git show` it here. Treat the finding above as UNVERIFIED and check whether it is still true against this repo's CURRENT state before doing anything else (ce-5112).

DONE WHEN: the finding above is either fixed and verified, or shown not to be real — say which in the closing evidence.
