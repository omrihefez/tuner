---
id: bt-5b84
title: DOMAIN.md pete/pete-api rows still claim wildcard/404
status: open
priority: p3
tags:
  - dns
  - meni
created: 2026-11-27
filed:
  owner: capacity-engine
  at: 2026-11-27T01:54:58Z
reported: 2026-11-27
---

Named in the finding: domain.md, pete/pete-api, wildcard/404

Why this is worth doing (from the reporting worker's own FOLLOW-UP line): meni-side file (see queue file), lines ~48-49

<!-- capacity-engine: provenance, not part of the finding -->
UNVERIFIED CLAIM — auto-filed by the capacity engine from a worker's FOLLOW-UP line. The title above is that worker's own belief at the end of a session, written once, never checked by anything else: a well-formed, confident sentence can still be flatly wrong. Verify it against this repo's CURRENT state before doing anything else, then scope it before claiming (ce-916b).

Discovered while working bt-5ed9, session `flip-check-public-surfac-14e03c`, dispatched on bass-tuner.
See 'reported' in this task's frontmatter for the date this finding was originally observed — read any relative time in the title above ("this morning", "currently", "still", "right now") as dated from THAT day, not from when this task was filed.
Named file 'domain.md' actually lives in /home/omri/meni — a real repo, but deliberately excluded from boards[] and never auto-dispatched (config.json's _meni_board_excluded_note), so it cannot be routed there. Filed on bass-tuner instead for lack of anywhere else to put it; if this needs action, it has to be picked up by hand or queued via ~/inbox/meni-board-queue/ (ma-e203).
That task's report closed DONE (commit 7377e6449ee6).

DONE WHEN: the finding above is either fixed and verified, or shown not to be real — say which in the closing evidence.
