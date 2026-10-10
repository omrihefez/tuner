---
id: bt-eb7f
title: Wire meni-arch's new scripts/lib/domain-registry.sh into meniapp's
  check-domain-registry-sync.sh daily cron (ma-6493) so a 3-way drift between
  meniapp/bass-tuner/meni-arch's copies is caught, not just the existing 2-way check
status: claimed
priority: p3
tags:
  - ops
  - test
created: 2026-10-11
filed:
  owner: capacity-engine
  at: 2026-10-10T21:24:46Z
reported: 2026-10-11
claim:
  owner: capacity-engine
  at: 2026-10-10T21:27:42Z
---

Named in the finding: scripts/lib/domain-registry.sh, check-domain-registry-sync.sh, meniapp/bass-tuner/meni-arch

LIKELY ALREADY DONE — verify before building. Work merged after this finding was raised may already cover it:
- [meniapp] `456e2635` 2026-10-10 "domain-registry.sh: anchor the apex guard, add loud stderr warnings (bt-7f07)" — scripts/check-cert-expiry.sh, scripts/check-domain-registry-sync.test.sh, scripts/domain-registry.test.sh, scripts/lib/domain-registry.sh (touches scripts/lib/domain-registry.sh; 57% of the finding's words)
- `0608e39f` 2026-10-10 "Anchor the apex guard in derive_registry_hosts so multi-label hosts derive (bt-7f07)" — scripts/lib/domain-registry.sh (touches scripts/lib/domain-registry.sh; 57% of the finding's words)
- [meniapp] `41f2853f` 2026-10-10 "check-domain-registry-sync.sh: fixture needs a multi-label host (bt-7f07)" — scripts/check-domain-registry-sync.sh (touches check-domain-registry-sync.sh; 52% of the finding's words)

START HERE: check whether that work satisfies this finding — the candidate above is in `meniapp`, not this repo, so `git show` here won't find it. If it does, close with `--commit <sha> --repo meniapp` and say so — that is a complete, correct closure, not a shortcut. If it does not, say in one line what it missed and do the work.
This is a word/file-path heuristic run at filing time, NOT a proof — it exists so the claimer starts from "verify" instead of spending a whole round rediscovering that it shipped (ce-a792).

<!-- capacity-engine: provenance, not part of the finding -->
UNVERIFIED CLAIM — auto-filed by the capacity engine from a worker's FOLLOW-UP line. The title above is that worker's own belief at the end of a session, written once, never checked by anything else: a well-formed, confident sentence can still be flatly wrong. Verify it against this repo's CURRENT state before doing anything else, then scope it before claiming (ce-916b).

Discovered while working ar-2017, session `make-scripts-test-sh-s-a-d5d7ab`, dispatched on meni-arch.
See 'reported' in this task's frontmatter for the date this finding was originally observed — read any relative time in the title above ("this morning", "currently", "still", "right now") as dated from THAT day, not from when this task was filed.
This finding named multiple repos explicitly and was filed separately on each: also on meniapp (ce-71de). Scope this task to the part that is actually about meni-arch; the siblings cover the rest.
That task's report closed DONE (commit ea93fe019276678b32f894e574e72e6347d6317c — does not resolve here, see below).

PROVENANCE COMMIT DOES NOT RESOLVE HERE — `ea93fe019276678b32f894e574e72e6347d6317c` does not exist in this repo. It is the evidence commit from the task/board that raised this line, not this one — don't spend time trying to `git show` it here. Treat the finding above as UNVERIFIED and check whether it is still true against this repo's CURRENT state before doing anything else (ce-5112).

DONE WHEN: the finding above is either fixed and verified, or shown not to be real — say which in the closing evidence.

## Log
- 2026-10-11 claimed by capacity-engine
