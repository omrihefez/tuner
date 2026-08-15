---
id: bt-8e12
title: Update ~/meni/DOMAIN.md albumclub row to sunset/removed (same shape as apartments row, line 25)
status: done
priority: p3
tags:
  - docs
  - from-brief
  - cross-board
created: 2026-08-15
done:
  at: 2026-08-15T03:31:05Z
  by: omri@ubuntu-4gb-nbg1-1
evidence:
  - type: commit
    value: db4fc3e
    repo: meni
    verified: 2026-08-15T03:31:05Z
---

Named in the finding: meni/domain.md, sunset/removed

LIKELY ALREADY DONE — verify before building. Work merged after this finding was raised may already cover it:
- `d66c96ec` 2026-08-15 "bt-5149: drop albumclub from domain drift audit" — scripts/audit-domains.sh (70% of the finding's words)

START HERE: check whether that work satisfies this finding. If it does, close with `--commit <sha>` and say so — that is a complete, correct closure, not a shortcut. If it does not, say in one line what it missed and do the work.
This is a word/file-path heuristic run at filing time, NOT a proof — it exists so the claimer starts from "verify" instead of spending a whole round rediscovering that it shipped (ce-a792).

<!-- capacity-engine: provenance, not part of the finding -->
Auto-filed by the capacity engine from a worker's FOLLOW-UP line — the title is that worker's own verbatim wording, so scope it before claiming.

Discovered while working bt-5149, session `domain-monitor-still-che-c92e22`, dispatched on bass-tuner.
Board choice is a GUESS: this follow-up names a file but the engine could not match it to exactly one board's repo, so it stayed on the dispatching board rather than being routed. Verify it belongs here before working it — it may need re-filing on the board that actually owns the named file (ce-3b8d).
That task's report closed DONE (commit d66c96e).

DONE WHEN: the finding above is either fixed and verified, or shown not to be real — say which in the closing evidence.

cross-board: names a file under 'meni' at /home/omri/meni — consider filing there instead (see dn-334c).

## Log
- 2026-08-15 done by omri@ubuntu-4gb-nbg1-1 — commit db4fc3e (meni)
