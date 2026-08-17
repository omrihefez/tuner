---
id: bt-d5e2
title: donefile pre-push hook should scrub GIT_* before running the suite — fleet-wide defense in
  depth for the bt-f541 worktree-GIT_DIR escape
status: open
priority: p2
tags:
  - reliability
  - ci
  - safety
created: 2026-08-18
---

LIKELY ALREADY DONE — verify before building. Work merged after this finding was raised may already cover it:
- `9a27a538` 2026-08-17 "test: stop check-sw-cache-bump fixtures escaping into an ambient GIT_DIR (bt-f541)" — package.json, test/check-sw-cache-bump.test.js (names bt-f541; 53% of the finding's words)

START HERE: check whether that work satisfies this finding. If it does, close with `--commit <sha>` and say so — that is a complete, correct closure, not a shortcut. If it does not, say in one line what it missed and do the work.
Priority lowered p1 -> p2 on that match alone; raise it back if the finding turns out to be real (ce-a792).
This is a word/file-path heuristic run at filing time, NOT a proof — it exists so the claimer starts from "verify" instead of spending a whole round rediscovering that it shipped (ce-a792).

<!-- capacity-engine: provenance, not part of the finding -->
UNVERIFIED CLAIM — auto-filed by the capacity engine from a worker's FOLLOW-UP line. The title above is that worker's own belief at the end of a session, written once, never checked by anything else: a well-formed, confident sentence can still be flatly wrong. Verify it against this repo's CURRENT state before doing anything else, then scope it before claiming (ce-916b).

Discovered while working bt-f541, session `check-sw-cache-bump-test-4a73ae`, dispatched on bass-tuner.
Reported 2026-08-17 — read any relative time in the title above ("this morning", "currently", "still", "right now") as dated from THAT day, not from when this task was filed.
That task's report closed DONE (commit 9a27a53).

DONE WHEN: the finding above is either fixed and verified, or shown not to be real — say which in the closing evidence.
