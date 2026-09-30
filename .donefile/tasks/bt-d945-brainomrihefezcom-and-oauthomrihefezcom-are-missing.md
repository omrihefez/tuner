---
id: bt-d945
title: brain.omrihefez.com and oauth.omrihefez.com are missing Strict-Transport-Security in production
status: open
priority: p3
tags:
  - security
created: 2026-10-01
filed:
  owner: capacity-engine
  at: 2026-09-30T21:05:50Z
reported: 2026-09-30
---

Why this is worth doing (from the reporting worker's own FOLLOW-UP line): confirmed live 2026-10-01 — brain's 404 and oauth's /health 200 both carry zero HSTS; fix belongs in second-brain and apartment repos respectively, not bass-tuner (this task was detection-only)

LIKELY ALREADY DONE — verify before building. Work merged after this finding was raised may already cover it:
- `8c91290a` 2026-09-30 "audit-domains.sh: assert Strict-Transport-Security on non-Vercel hosts (bt-b75b)" — scripts/audit-domains.sh, scripts/audit-domains.test.sh (67% of the finding's words)

START HERE: check whether that work satisfies this finding. If it does, close with `--commit <sha>` and say so — that is a complete, correct closure, not a shortcut. If it does not, say in one line what it missed and do the work.
This is a word/file-path heuristic run at filing time, NOT a proof — it exists so the claimer starts from "verify" instead of spending a whole round rediscovering that it shipped (ce-a792).

<!-- capacity-engine: provenance, not part of the finding -->
UNVERIFIED CLAIM — auto-filed by the capacity engine from a worker's FOLLOW-UP line. The title above is that worker's own belief at the end of a session, written once, never checked by anything else: a well-formed, confident sentence can still be flatly wrong. Verify it against this repo's CURRENT state before doing anything else, then scope it before claiming (ce-916b).

Discovered while working bt-b75b, session `audit-domains-sh-never-a-06cfd2`, dispatched on bass-tuner.
See 'reported' in this task's frontmatter for the date this finding was originally observed — read any relative time in the title above ("this morning", "currently", "still", "right now") as dated from THAT day, not from when this task was filed.
That task's report closed DONE (commit 8c91290af49ec651a55aa623a0420c857049d736).

DONE WHEN: the finding above is either fixed and verified, or shown not to be real — say which in the closing evidence.
