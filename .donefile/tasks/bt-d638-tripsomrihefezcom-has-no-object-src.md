---
id: bt-d638
title: trips.omrihefez.com has no object-src directive, falls back to default-src 'self', flagged by
  check-csp-strength.sh as missing explicit 'none'
status: open
priority: p3
tags:
  - security
  - csp
  - trips-hub
created: 2026-10-13
filed:
  owner: capacity-engine
  at: 2026-10-13T04:58:06Z
reported: 2026-10-13
---

Named in the finding: check-csp-strength.sh

Why this is worth doing (from the reporting worker's own FOLLOW-UP line): live header 2026-10-13 shows "object-src missing 'none' (effective value: 'self')" alongside the img-src finding; not covered by th-07a5's title, no existing task found for it

LIKELY ALREADY DONE — verify before building. Work merged after this finding was raised may already cover it:
- `6844de75` 2026-10-13 "bt-2c67: check-csp-strength.sh now asserts object-src/base-uri/frame-ancestors" — scripts/check-csp-strength.sh, scripts/check-csp-strength.test.sh, test/vercel-headers.test.js, vercel.json (touches check-csp-strength.sh; 72% of the finding's words)

START HERE: check whether that work satisfies this finding. If it does, close with `--commit <sha>` and say so — that is a complete, correct closure, not a shortcut. If it does not, say in one line what it missed and do the work.
This is a word/file-path heuristic run at filing time, NOT a proof — it exists so the claimer starts from "verify" instead of spending a whole round rediscovering that it shipped (ce-a792).

<!-- capacity-engine: provenance, not part of the finding -->
UNVERIFIED CLAIM — auto-filed by the capacity engine from a worker's FOLLOW-UP line. The title above is that worker's own belief at the end of a session, written once, never checked by anything else: a well-formed, confident sentence can still be flatly wrong. Verify it against this repo's CURRENT state before doing anything else, then scope it before claiming (ce-916b).

Discovered while working th-07a5, session `trips-omrihefez-com-s-im-75061a`, dispatched on trips-hub.
See 'reported' in this task's frontmatter for the date this finding was originally observed — read any relative time in the title above ("this morning", "currently", "still", "right now") as dated from THAT day, not from when this task was filed.
That task's report closed DONE (commit 5b0c6337e81afafb3bd7231c31b7de815c302256 — does not resolve here, see below).

PROVENANCE COMMIT DOES NOT RESOLVE HERE — `5b0c6337e81afafb3bd7231c31b7de815c302256` does not exist in this repo. It is the evidence commit from the task/board that raised this line, not this one — don't spend time trying to `git show` it here. Treat the finding above as UNVERIFIED and check whether it is still true against this repo's CURRENT state before doing anything else (ce-5112).

DONE WHEN: the finding above is either fixed and verified, or shown not to be real — say which in the closing evidence.
