---
id: bt-eb7f
title: Wire meni-arch's new scripts/lib/domain-registry.sh into meniapp's
  check-domain-registry-sync.sh daily cron (ma-6493) so a 3-way drift between
  meniapp/bass-tuner/meni-arch's copies is caught, not just the existing 2-way check
status: done
priority: p3
tags:
  - ops
  - test
created: 2026-10-11
filed:
  owner: capacity-engine
  at: 2026-10-10T21:24:46Z
reported: 2026-10-11
done:
  at: 2026-10-10T21:44:54Z
  by: capacity-engine/worker
evidence:
  - type: commit
    value: 7b899700
    repo: meniapp
    verified: 2026-10-10T21:44:54Z
  - type: test
    cmd: cd /home/omri/projects/meniapp && bash scripts/check-domain-registry-sync.test.sh
    exit: 0
    at: 2026-10-10T21:44:53Z
    log: evidence/bt-eb7f-2026-10-10T21-44-53Z-test.txt
    sha256: 56a0a2c5d205374bf8a0efcca487f49a864623dddbbb4a8adf915b8014b66097
    bytes: 131
  - type: note
    value: "Not a bass-tuner change: the fix is meniapp's scripts/check-domain-registry-sync.sh
      (ma-6493's daily cron), which checked only meniapp vs bass-tuner. Added a THIRD_LIB for
      meni-arch's own copy (added in ar-2017) and compare all three pairwise; extended the
      regression test with a case planting a divergence in meni-arch's copy ALONE (bass-tuner
      untouched) and proved: (a) it is caught by the new 3-way check, exit 1, DRIFT naming
      meni-arch=, and (b) the OLD 2-way script, run against the identical planted divergence via a
      control run on origin/master's pre-fix script, reported 'clean' exit 0 -- a real false
      negative, now closed. Companion header-comment fix landed in meni-arch itself: commit 6367502b
      (meni-arch main) removes the 'not yet wired into that sync check' note, now stale. meni-arch
      has no donefile repo alias on this board so that commit isn't cited as structured evidence
      here, but it is real and pushed. bass-tuner's own copy of domain-registry.sh needed no change
      -- it already matched. This task was filed on bass-tuner's board by the auto-filer's heuristic
      even though the deliverable lives in meniapp/meni-arch; closing here per the task's own
      guidance ('close with --commit <sha> --repo meniapp and say so -- that is a complete, correct
      closure')."
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
- 2026-10-11 done by capacity-engine/worker — commit 7b899700 (meniapp), test `cd /home/omri/projects/meniapp && bash scripts/check-domain-registry-sync.test.sh` exit 0 (log: evidence/bt-eb7f-2026-10-10T21-44-53Z-test.txt)
