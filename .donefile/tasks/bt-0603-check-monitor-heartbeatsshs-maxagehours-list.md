---
id: bt-0603
title: check-monitor-heartbeats.sh's MAX_AGE_HOURS list is missing tunnel-liveness and heartbeat
  itself, not just model-ids (which I added)
status: claimed
priority: p3
tags:
  - observability
created: 2026-09-29
filed:
  owner: capacity-engine
  at: 2026-09-29T06:40:35Z
reported: 2026-09-29
claim:
  owner: capacity-engine
  at: 2026-09-29T07:23:02Z
---

Named in the finding: check-monitor-heartbeats.sh

Why this is worth doing (from the reporting worker's own FOLLOW-UP line): the heartbeat watchdog can't notice its own monitors going silent if they were never added to its own tracked list — found while wiring in model-ids

LIKELY ALREADY DONE — verify before building. Work merged after this finding was raised may already cover it:
- `5f379bef` 2026-09-29 "bt-5abe: monitor that a hardcoded Gemini model ID still resolves" — scripts/check-model-ids-resolve.sh, scripts/check-model-ids-resolve.test.sh, scripts/check-monitor-heartbeats.sh, scripts/install-monitoring-crons.sh (touches check-monitor-heartbeats.sh; 50% of the finding's words)

START HERE: check whether that work satisfies this finding. If it does, close with `--commit <sha>` and say so — that is a complete, correct closure, not a shortcut. If it does not, say in one line what it missed and do the work.
This is a word/file-path heuristic run at filing time, NOT a proof — it exists so the claimer starts from "verify" instead of spending a whole round rediscovering that it shipped (ce-a792).

<!-- capacity-engine: provenance, not part of the finding -->
UNVERIFIED CLAIM — auto-filed by the capacity engine from a worker's FOLLOW-UP line. The title above is that worker's own belief at the end of a session, written once, never checked by anything else: a well-formed, confident sentence can still be flatly wrong. Verify it against this repo's CURRENT state before doing anything else, then scope it before claiming (ce-916b).

Discovered while working bt-5abe, session `no-monitor-anywhere-chec-5a1a68`, dispatched on bass-tuner.
See 'reported' in this task's frontmatter for the date this finding was originally observed — read any relative time in the title above ("this morning", "currently", "still", "right now") as dated from THAT day, not from when this task was filed.
Board choice is a GUESS: this follow-up names a file but the engine could not match it to exactly one board's repo, so it stayed on the dispatching board rather than being routed. Verify it belongs here before working it — it may need re-filing on the board that actually owns the named file (ce-3b8d).
That task's report closed DONE (commit 5c4246c6f26f46d21211e936ab2716a4607f07f1).

DONE WHEN: the finding above is either fixed and verified, or shown not to be real — say which in the closing evidence.

## Log
- 2026-09-29 claimed by capacity-engine
