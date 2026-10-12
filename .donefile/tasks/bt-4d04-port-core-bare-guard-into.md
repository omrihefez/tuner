---
id: bt-4d04
title: Port core-bare-guard into donefile's canonical hooks/pre-push.sh template (dn-979a already
  covers this — sequence it AFTER dn-21df-identity-guard-propagation lands, since both touch the
  same shared template/propagation machinery)
status: claimed
priority: p3
tags:
  - infra
  - git
  - reliability
created: 2026-10-12
filed:
  owner: capacity-engine
  at: 2026-10-12T11:04:26Z
reported: 2026-10-12
claim:
  owner: capacity-engine
  at: 2026-10-12T13:40:47Z
---

Named in the finding: hooks/pre-push.sh, template/propagation

Why this is worth doing (from the reporting worker's own FOLLOW-UP line): live-hook-only edits on meni-arch (and presumably donefile/kidai/bass-tuner/zn-tournaments, all PER_CLONE) get resynced back to the unfixed template by a fleet hook-hygiene process even within one session — only a template-level fix in donefile is durable.

<!-- capacity-engine: provenance, not part of the finding -->
UNVERIFIED CLAIM — auto-filed by the capacity engine from a worker's FOLLOW-UP line. The title above is that worker's own belief at the end of a session, written once, never checked by anything else: a well-formed, confident sentence can still be flatly wrong. Verify it against this repo's CURRENT state before doing anything else, then scope it before claiming (ce-916b).

Discovered while working ar-d9f9, session `port-th-0dd5-ambient-git-87a059`, dispatched on meni-arch.
See 'reported' in this task's frontmatter for the date this finding was originally observed — read any relative time in the title above ("this morning", "currently", "still", "right now") as dated from THAT day, not from when this task was filed.
This finding named multiple repos explicitly and was filed separately on each: also on donefile, kidai (ce-71de). Scope this task to the part that is actually about meni-arch; the siblings cover the rest.
That task's report closed DONE (commit d6e245548b18864919949f8751208d5a99607541 — does not resolve here, see below).

PROVENANCE COMMIT DOES NOT RESOLVE HERE — `d6e245548b18864919949f8751208d5a99607541` does not exist in this repo. It is the evidence commit from the task/board that raised this line, not this one — don't spend time trying to `git show` it here. Treat the finding above as UNVERIFIED and check whether it is still true against this repo's CURRENT state before doing anything else (ce-5112).

DONE WHEN: the finding above is either fixed and verified, or shown not to be real — say which in the closing evidence.

## Log
- 2026-10-12 claimed by capacity-engine
