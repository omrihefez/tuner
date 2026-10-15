---
id: bt-3614
title: audit-domains.sh, check-tunnel-liveness.sh, check-permissions-policy.sh,
  check-cors-corp-consistency.sh mention vercel in comments only (no runtime call), so none of them
  share this bug — confirmed, no action needed
status: claimed
priority: p3
tags:
  - bass-tuner
created: 2026-10-15
filed:
  owner: capacity-engine
  at: 2026-10-15T06:22:02Z
reported: 2026-10-15
claim:
  owner: capacity-engine
  at: 2026-10-15T06:23:28Z
---

Named in the finding: audit-domains.sh, check-tunnel-liveness.sh, check-permissions-policy.sh, check-cors-corp-consistency.sh

Why this is worth doing (from the reporting worker's own FOLLOW-UP line): grepped for actual (non-comment) vercel invocations, found none

<!-- capacity-engine: provenance, not part of the finding -->
UNVERIFIED CLAIM — auto-filed by the capacity engine from a worker's FOLLOW-UP line. The title above is that worker's own belief at the end of a session, written once, never checked by anything else: a well-formed, confident sentence can still be flatly wrong. Verify it against this repo's CURRENT state before doing anything else, then scope it before claiming (ce-916b).

Discovered while working bt-e452, session `unregistered-live-hosts--de2930`, dispatched on bass-tuner.
See 'reported' in this task's frontmatter for the date this finding was originally observed — read any relative time in the title above ("this morning", "currently", "still", "right now") as dated from THAT day, not from when this task was filed.
Board choice is a GUESS: this follow-up names a file but the engine could not match it to exactly one board's repo, so it stayed on the dispatching board rather than being routed. Verify it belongs here before working it — it may need re-filing on the board that actually owns the named file (ce-3b8d).
That task's report closed DONE (commit 48c50f13d179c6ec78e0e8efa2486fcaebff448c).

DONE WHEN: the finding above is either fixed and verified, or shown not to be real — say which in the closing evidence.

## Log
- 2026-10-15 claimed by capacity-engine
