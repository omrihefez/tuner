---
id: bt-2f29
title: Drop bass-tuner's 5 now-fixed rows from meniapp's argv-secret-exposure-baseline.tsv
status: claimed
priority: p3
tags:
  - security
  - fleet
created: 2026-10-05
filed:
  owner: capacity-engine
  at: 2026-10-05T05:44:28Z
reported: 2026-10-05
claim:
  owner: capacity-engine
  at: 2026-10-05T05:58:04Z
---

Why this is worth doing (from the reporting worker's own FOLLOW-UP line): filed as ma-d8d3, meniapp owns that file; rows 91-95 are now stale

POSSIBLE CROSS-BOARD DUPLICATE — ma-d8d3 on meniapp (open, 86% title match) looks like the same finding. This filed anyway because that match is scored WITHOUT the repo-identity check same-board dedupe relies on (ce-916b: routing had no signal for either finding to place it confidently), so it's a pointer to check, not a confirmed dup. START HERE: read ma-d8d3 before doing any work — if it already covers this, close with a note saying so instead of redoing it.

LIKELY ALREADY DONE — verify before building. Work merged after this finding was raised may already cover it:
- [meniapp] `36ccbe88` 2026-10-05 "security: migrate meniapp's 79 argv-secret offenders off process argv (ma-529d)" — deploy/activation-probes/probe-0697.sh, deploy/activation-probes/probe-2617.sh, deploy/activation-probes/probe-2c58.sh, deploy/activation-probes/probe-2e72.sh, deploy/activation-probes/probe-30b4.sh, deploy/activation-probes/probe-3c8d.sh (82% of the finding's words)
- [meniapp] `3e0d1807` 2026-10-05 "security: drop vidsmith's fixed row from argv-secret-exposure baseline (ma-e934)" — deploy/argv-secret-exposure-baseline.tsv (64% of the finding's words)
- [meniapp] `0b3d8144` 2026-10-05 "security: drop second-brain's 3 fixed argv-secret rows from the baseline (sb-757e/ma-529d)" — deploy/argv-secret-exposure-baseline.tsv (64% of the finding's words)

START HERE: check whether that work satisfies this finding — the candidate above is in `meniapp`, not this repo, so `git show` here won't find it. If it does, close with `--commit <sha> --repo meniapp` and say so — that is a complete, correct closure, not a shortcut. If it does not, say in one line what it missed and do the work.
This is a word/file-path heuristic run at filing time, NOT a proof — it exists so the claimer starts from "verify" instead of spending a whole round rediscovering that it shipped (ce-a792).

<!-- capacity-engine: provenance, not part of the finding -->
UNVERIFIED CLAIM — auto-filed by the capacity engine from a worker's FOLLOW-UP line. The title above is that worker's own belief at the end of a session, written once, never checked by anything else: a well-formed, confident sentence can still be flatly wrong. Verify it against this repo's CURRENT state before doing anything else, then scope it before claiming (ce-916b).

Discovered while working bt-0ead, session `migrate-bass-tuner-s-5-a-0cec29`, dispatched on bass-tuner.
See 'reported' in this task's frontmatter for the date this finding was originally observed — read any relative time in the title above ("this morning", "currently", "still", "right now") as dated from THAT day, not from when this task was filed.
That task's report closed DONE (commit 14bf41bb907fb9cf5d739a4420aa811b3c2f12cb).

DONE WHEN: the finding above is either fixed and verified, or shown not to be real — say which in the closing evidence.

## Log
- 2026-10-05 claimed by capacity-engine
