---
id: bt-d1bc
title: Verify renew-wildcard-cert.sh on Hobby after downgrade (cron log ~2026-11-05 or attended
  --force --i-mean-it)
status: open
priority: p3
tags:
  - vercel
  - dns
created: 2026-10-23
filed:
  owner: capacity-engine/backfill
  at: 2026-10-23T00:40:23Z
reported: 2026-10-22
---

Named in the finding: renew-wildcard-cert.sh

Why this is worth doing (from the reporting worker's own FOLLOW-UP line): team billing.plan still 'pro' on 2026-10-22; newest wildcard cert 59d left

<!-- capacity-engine: provenance, not part of the finding -->
UNVERIFIED CLAIM — auto-filed by the capacity engine from a worker's FOLLOW-UP line. The title above is that worker's own belief at the end of a session, written once, never checked by anything else: a well-formed, confident sentence can still be flatly wrong. Verify it against this repo's CURRENT state before doing anything else, then scope it before claiming (ce-916b).

Discovered while working bt-41b2, session `confirm-bass-tuner-renew-635b63`, dispatched on bass-tuner.
See 'reported' in this task's frontmatter for the date this finding was originally observed — read any relative time in the title above ("this morning", "currently", "still", "right now") as dated from THAT day, not from when this task was filed.

INHERITED RESTRICTION — the parent this was raised on, bt-41b2, was BLOCKED (gate-owner main) when this was auto-filed, so this task is parked with it rather than becoming a way around it (ce-ce4f). It unblocks when bt-41b2 does; re-scope it then, since the parent's own work may already cover it.

DONE WHEN: the finding above is either fixed and verified, or shown not to be real — say which in the closing evidence.
