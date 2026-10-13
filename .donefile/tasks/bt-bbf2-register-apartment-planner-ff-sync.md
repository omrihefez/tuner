---
id: bt-bbf2
title: Register apartment-planner-ff-sync in meniapp's deploy/guard-inventory.tsv
status: done
priority: p3
tags:
  - meniapp
  - ci
created: 2026-10-13
filed:
  owner: capacity-engine
  at: 2026-10-13T08:14:31Z
reported: 2026-10-13
done:
  at: 2026-10-13T09:34:55Z
  by: omri@ubuntu-4gb-nbg1-1
evidence:
  - type: live
    cmd: git -C /home/omri/projects/meniapp show origin/master:deploy/guard-inventory.tsv | grep -c
      '^apartment-planner-ff-sync'
    exit: 0
    at: 2026-10-13T09:34:53Z
    expect: "1"
    log: evidence/bt-bbf2-2026-10-13T09-34-53Z-0-live.txt
    sha256: 63b2aa21a715322b61906cf0c87ef33e628b63067b3ba6586839ba47bcef2f19
    bytes: 125
  - type: live
    cmd: bash /home/omri/projects/meniapp/scripts/check-guard-inventory.sh
    exit: 0
    at: 2026-10-13T09:34:53Z
    expect: nothing unregistered
    log: evidence/bt-bbf2-2026-10-13T09-34-53Z-1-live.txt
    sha256: b5a5680e9cd9b351e41cb8e6d32490ecc4022c6562340a075b3307b1b7c481f9
    bytes: 169
  - type: note
    value: >-
      NOT REAL ON THIS BOARD — the finding is already satisfied, and the fix never belonged here.
      Verified 2026-10-13 ~12:3x IDT against current state, per this task's own DONE WHEN ("fixed
      and verified, or shown not to be real — say which").


      The finding asks for ONE row in ONE file in ONE repo: meniapp/deploy/guard-inventory.tsv. It
      is there (apartment-planner-ff-sync, with a comment block naming its sibling rows), added by
      meniapp 98a03189 "deploy: register apartment-planner-ff-sync in guard-inventory.tsv
      (ar-6eeb)", confirmed present in origin/master's committed tree — not just a working copy.
      meniapp/scripts/check-guard-inventory.sh, the consumer that would report the gap, reconciles
      clean: "all 69 declared crontab-drift guards are live, and nothing unregistered", exit 0.


      WHY THIS BOARD HAD A TASK AT ALL, worth recording because the same fan-out will recur. ce-71de
      filed this one finding separately on ELEVEN boards (meni-arch, tik-api, tik-next, trips-hub,
      bass-tuner, donefile, second-brain, house-control, apartment-planner, apartment, iac) on the
      grounds that it "named multiple repos explicitly". It did — but it named them as EVIDENCE, not
      as work: the sibling ff-sync rows that already existed were the proof that apartment-planner's
      was missing. There was never a per-repo item. meni-arch's ar-6eeb did the whole fix.


      MEASURED COST of that fan-out, from the 2026-10-13T09:19Z digest: the cross-board dedup
      correctly refused to dispatch these siblings, so EIGHT boards were serialized behind iac-f0bd
      on every tick, re-logging the same skip. Ten open tasks, all pointing at one row that was
      already committed. The dedup was right and the filing was wrong.


      Nothing to do in this repo.
---

Named in the finding: deploy/guard-inventory.tsv

Why this is worth doing (from the reporting worker's own FOLLOW-UP line): every sibling ff-sync cron (donefile/house-control/tik-api/tik-next/iac/trips-hub/second-brain/bass-tuner/meni-arch) has a row there for check-guard-inventory.sh's reconciliation; apartment-planner's new one doesn't yet, so it will likely surface as an unregistered-guard gap on the next sweep.

<!-- capacity-engine: provenance, not part of the finding -->
UNVERIFIED CLAIM — auto-filed by the capacity engine from a worker's FOLLOW-UP line. The title above is that worker's own belief at the end of a session, written once, never checked by anything else: a well-formed, confident sentence can still be flatly wrong. Verify it against this repo's CURRENT state before doing anything else, then scope it before claiming (ce-916b).

Discovered while working ma-b9fe, session `apartment-planner-has-no-b80954`, dispatched on meniapp.
See 'reported' in this task's frontmatter for the date this finding was originally observed — read any relative time in the title above ("this morning", "currently", "still", "right now") as dated from THAT day, not from when this task was filed.
This finding named multiple repos explicitly and was filed separately on each: also on meni-arch, iac, tik-api, tik-next, trips-hub, donefile, second-brain, house-control, apartment-planner, apartment (ce-71de). Scope this task to the part that is actually about meniapp; the siblings cover the rest.
That task's report closed DONE (commit 7a182fe03324e0ce5a638265dd88c1cc08d8b275 — does not resolve here, see below).

PROVENANCE COMMIT DOES NOT RESOLVE HERE — `7a182fe03324e0ce5a638265dd88c1cc08d8b275` does not exist in this repo. It is the evidence commit from the task/board that raised this line, not this one — don't spend time trying to `git show` it here. Treat the finding above as UNVERIFIED and check whether it is still true against this repo's CURRENT state before doing anything else (ce-5112).

DONE WHEN: the finding above is either fixed and verified, or shown not to be real — say which in the closing evidence.

## Log
- 2026-10-13 done by omri@ubuntu-4gb-nbg1-1 — live `git -C /home/omri/projects/meniapp show origin/master:deploy/guard-inventory.tsv | grep -c '^apartment-planner-ff-sync'` exit 0 (--live-expect "1") (log: evidence/bt-bbf2-2026-10-13T09-34-53Z-0-live.txt), live `bash /home/omri/projects/meniapp/scripts/check-guard-inventory.sh` exit 0 (--live-expect "nothing unregistered") (log: evidence/bt-bbf2-2026-10-13T09-34-53Z-1-live.txt)
