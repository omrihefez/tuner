---
id: bt-10dd
title: Flip DOMAIN.md §1 arch-preview row from 🟢 live to retired, citing ar-1fde
status: open
priority: p3
tags:
  - from-brief
created: 2026-10-10
filed:
  owner: capacity-engine
  at: 2026-10-10T08:21:25Z
reported: 2026-10-10
---

Named in the finding: domain.md

Why this is worth doing (from the reporting worker's own FOLLOW-UP line): queued at ~/inbox/meni-board-queue/2026-10-10-domain-md-arch-preview-still-live.md since this repo can't commit to meni; once landed, the SKIP-exemption added here becomes redundant and can be removed.

LIKELY ALREADY DONE — verify before building. Work merged after this finding was raised may already cover it:
- `81dc7e1e` 2026-10-10 "audit-domains.sh: exempt retired arch-preview host from DRIFT/CHECK (bt-f55e)" — scripts/audit-domains.sh (names ar-1fde; 89% of the finding's words)

START HERE: check whether that work satisfies this finding. If it does, close with `--commit <sha>` and say so — that is a complete, correct closure, not a shortcut. If it does not, say in one line what it missed and do the work.
This is a word/file-path heuristic run at filing time, NOT a proof — it exists so the claimer starts from "verify" instead of spending a whole round rediscovering that it shipped (ce-a792).

<!-- capacity-engine: provenance, not part of the finding -->
UNVERIFIED CLAIM — auto-filed by the capacity engine from a worker's FOLLOW-UP line. The title above is that worker's own belief at the end of a session, written once, never checked by anything else: a well-formed, confident sentence can still be flatly wrong. Verify it against this repo's CURRENT state before doing anything else, then scope it before claiming (ce-916b).

Discovered while working bt-f55e, session `audit-domains-sh-false-p-058048`, dispatched on bass-tuner.
See 'reported' in this task's frontmatter for the date this finding was originally observed — read any relative time in the title above ("this morning", "currently", "still", "right now") as dated from THAT day, not from when this task was filed.
Named file 'domain.md' actually lives in /home/omri/meni — a real repo, but deliberately excluded from boards[] and never auto-dispatched (config.json's _meni_board_excluded_note), so it cannot be routed there. Filed on bass-tuner instead for lack of anywhere else to put it; if this needs action, it has to be picked up by hand or queued via ~/inbox/meni-board-queue/ (ma-e203).
That task's report closed DONE (commit 81dc7e1e118511521ee92297bbd25bf6d5f98348).

DONE WHEN: the finding above is either fixed and verified, or shown not to be real — say which in the closing evidence.
