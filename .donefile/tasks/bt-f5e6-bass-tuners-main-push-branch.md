---
id: bt-f5e6
title: bass-tuner's main-push branch-guard isn't listed in the fleet CLAUDE.md's 4-repo table
  (trips-hub, capacity-engine, donefile, kidai)
status: open
priority: p3
tags:
  - monitoring
  - docs
created: 2026-09-24
filed:
  owner: capacity-engine
  at: 2026-09-24T17:26:28Z
reported: 2026-09-24
---

Named in the finding: claude.md

Why this is worth doing (from the reporting worker's own FOLLOW-UP line): hit it live pushing bt-a7a3, cost one failed push+retry; the doc undercounts guarded repos

<!-- capacity-engine: provenance, not part of the finding -->
UNVERIFIED CLAIM — auto-filed by the capacity engine from a worker's FOLLOW-UP line. The title above is that worker's own belief at the end of a session, written once, never checked by anything else: a well-formed, confident sentence can still be flatly wrong. Verify it against this repo's CURRENT state before doing anything else, then scope it before claiming (ce-916b).

Discovered while working bt-a7a3, session `lib-domain-registry-sh-i-db0267`, dispatched on bass-tuner.
See 'reported' in this task's frontmatter for the date this finding was originally observed — read any relative time in the title above ("this morning", "currently", "still", "right now") as dated from THAT day, not from when this task was filed.
Named file 'claude.md' actually lives in /home/omri/meni — a real repo, but deliberately excluded from boards[] and never auto-dispatched (config.json's _meni_board_excluded_note), so it cannot be routed there. Filed on bass-tuner instead for lack of anywhere else to put it; if this needs action, it has to be picked up by hand or queued via ~/inbox/meni-board-queue/ (ma-e203).
That task's report closed DONE (commit da9d5270845e44b2482a068d0bde6ae167839907).

DONE WHEN: the finding above is either fixed and verified, or shown not to be real — say which in the closing evidence.
