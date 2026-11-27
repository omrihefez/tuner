---
id: bt-5b84
title: DOMAIN.md pete/pete-api rows still claim wildcard/404
status: done
priority: p3
tags:
  - dns
  - meni
created: 2026-11-27
filed:
  owner: capacity-engine
  at: 2026-11-27T01:54:58Z
reported: 2026-11-27
done:
  at: 2026-11-27T01:57:34Z
  by: capacity-engine/worker
evidence:
  - type: commit
    value: 7377e6449ee6
    verified: 2026-11-27T01:57:34Z
  - type: test
    cmd: f=/home/omri/inbox/meni-board-queue; [ -f $f/bt-5ed9-domain-md-pete-rows-stale.md ] || [ -f
      $f/drained/bt-5ed9-domain-md-pete-rows-stale.md ] || [ -f
      $f/done/bt-5ed9-domain-md-pete-rows-stale.md ] || grep -q "NXDOMAIN" /home/omri/meni/DOMAIN.md
    exit: 0
    at: 2026-11-27T01:57:34Z
    log: evidence/bt-5b84-2026-11-27T01-57-34Z-test.txt
    sha256: fe6d3f93031e822cb5f820b25bde05a0f521dd416bc9c8d7cf397d216e1c6a31
    bytes: 248
  - type: note
    value: Finding is real (DOMAIN.md lines 48-49 still say wildcard/Vercel 404; wildcard deleted
      2026-11-26, bt-6531; pete/pete-api have no A record, curl fails) but it is a ~/meni file I may
      not commit to. Already queued by bt-5ed9 at
      ~/inbox/meni-board-queue/bt-5ed9-domain-md-pete-rows-stale.md with the exact fix; no duplicate
      filed. Evidence is a handoff check, not proof of the DOMAIN.md edit.
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

## Log
- 2026-11-27 claimed by capacity-engine
- 2026-11-27 done by capacity-engine/worker — commit 7377e6449ee6, test `f=/home/omri/inbox/meni-board-queue; [ -f $f/bt-5ed9-domain-md-pete-rows-stale.md ] || [ -f $f/drained/bt-5ed9-domain-md-pete-rows-stale.md ] || [ -f $f/done/bt-5ed9-domain-md-pete-rows-stale.md ] || grep -q "NXDOMAIN" /home/omri/meni/DOMAIN.md` exit 0 (log: evidence/bt-5b84-2026-11-27T01-57-34Z-test.txt)
