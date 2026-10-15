---
id: bt-9e13
title: Decide 5 live capacity-engine tasks that are duplicates of open tasks on the correct boards —
  bass-tuner
status: done
priority: p2
tags:
  - dedupe
  - board-hygiene
created: 2026-10-15
filed:
  owner: capacity-engine
  at: 2026-10-15T20:48:44Z
reported: 2026-10-15
done:
  at: 2026-10-15T20:55:14Z
  by: omri@ubuntu-4gb-nbg1-1
evidence:
  - type: test
    cmd: 'cd /home/omri/projects/capacity-engine && n=0; for t in ce-0d9d ce-393c ce-8360 ce-9a8a
      ce-c2bc; do s=$(node /home/omri/projects/donefile/dist/cli.js show $t 2>/dev/null | grep -m1
      "^status:" | awk "{print \$2}"); [ "$s" = "done" ] && n=$((n+1)); done; echo "capacity-engine
      duplicates closed: $n of 5"; [ "$n" -eq 5 ]'
    exit: 0
    at: 2026-10-15T20:55:08Z
    log: evidence/bt-9e13-2026-10-15T20-55-08Z-test.txt
    sha256: cbd7a5229f6191c9958b2d323544983a9d3907ba56a8da5747cf29a032554d78
    bytes: 364
  - type: note
    value: >-
      Closed as ALREADY RESOLVED, 2026-10-15 23:55 IDT — the decision this task asks for was made
      and executed before this task was filed.


      This is an INHERITED PARK auto-filed from a FOLLOW-UP on ce-cadf, and its own unblock
      predicate says to re-scope on its own merits because the parent work may already cover it.
      That is exactly the situation, just not via the parent: at 23:46 I closed all five
      capacity-engine duplicates in favour of the real task on the correct board, each with evidence
      asserting the target resolves and is live, and re-verified all five targets open afterwards:

        ce-0d9d -> bt-a5ff (bass-tuner), ce-393c -> ar-0609 (meni-arch), ce-8360 -> kd-e0cc (kidai),
        ce-9a8a -> tkn-7fa3 (tik-next), ce-c2bc -> iac-c1bf (iac)

      So there is no decision left to make. Only duplicates were closed, never an original, and
      ce-0d9d had its full diagnosis carried onto bt-a5ff first so nothing was lost.


      Why this task exists on FIVE boards at once: the harvest fanned one FOLLOW-UP line out per
      board, each with a "provenance commit fc51abe5 does not resolve on this repo" caveat (ce-5112)
      — correct of it, since fc51abe5 is a capacity-engine sha. The underlying cause is the same
      parser defect ce-cadf fixes, which is a tidy demonstration of it: a cross-board follow-up
      became five board-local tasks for one piece of work. Closing all five rather than leaving them
      parked, because when ce-cadf lands their park releases and they would each become a
      dispatchable duplicate of finished work.


      ce-cadf itself stays parked for its attended merge; that is a separate, still-owed piece of
      work and this close does not touch it.
---

Why this is worth doing (from the reporting worker's own FOLLOW-UP line): ce-0d9d->bt-a5ff(bass-tuner,open), ce-393c->ar-0609(meni-arch,open), ce-8360->kd-e0cc(kidai,open), ce-9a8a->tkn-7fa3(tik-next,open), ce-c2bc->iac-c1bf(iac,open) — all five from the one ce-5e41 session, each dispatchable right now; I did not close them because ce-0d9d was just unblocked and closing another board's open p1/p2 is a judgement call

POSSIBLE SAME-REPORT DUPLICATE — another FOLLOW-UP line in the SAME worker report reads: "pete has a real donefile board on disk but is not in capacity-engine config.json boards, so it is invisible to dispatch and to dedup" (50% overlap, scored without the repo gate). Both were raised by one session's one closing report, so the odds these describe the same finding worded two ways are much higher than for an unrelated board task. Filed anyway (see followupCrossBoardNote's own reasoning for why dropping would be worse) — find where that sibling line landed BEFORE claiming this one; if it's the same fix, close this one citing that task's evidence instead of re-implementing it.

<!-- capacity-engine: provenance, not part of the finding -->
UNVERIFIED CLAIM — auto-filed by the capacity engine from a worker's FOLLOW-UP line. The title above is that worker's own belief at the end of a session, written once, never checked by anything else: a well-formed, confident sentence can still be flatly wrong. Verify it against this repo's CURRENT state before doing anything else, then scope it before claiming (ce-916b).

Discovered while working ce-cadf, session `donefile-ci-red-again-3--0bb1d1`, dispatched on capacity-engine.
See 'reported' in this task's frontmatter for the date this finding was originally observed — read any relative time in the title above ("this morning", "currently", "still", "right now") as dated from THAT day, not from when this task was filed.
This finding named multiple repos explicitly and was filed separately on each: also on meni-arch, iac, tik-next, kidai (ce-71de). Scope this task to the part that is actually about capacity-engine; the siblings cover the rest.
That task's report closed BLOCKED (commit fc51abe5 — does not resolve here, see below).

PROVENANCE COMMIT DOES NOT RESOLVE HERE — `fc51abe5` does not exist in this repo. It is the evidence commit from the task/board that raised this line, not this one — don't spend time trying to `git show` it here. Treat the finding above as UNVERIFIED and check whether it is still true against this repo's CURRENT state before doing anything else (ce-5112).

INHERITED RESTRICTION — the parent this was raised on, ce-cadf, was BLOCKED (gate-owner main) when this was auto-filed, so this task is parked with it rather than becoming a way around it (ce-ce4f). It unblocks when ce-cadf does; re-scope it then, since the parent's own work may already cover it.

DONE WHEN: the finding above is either fixed and verified, or shown not to be real — say which in the closing evidence.

## Gate
PROBE: s=$(cd /home/omri/projects/capacity-engine && node /home/omri/projects/donefile/dist/cli.js show ce-cadf --json) && printf '%s' "$s" | grep -Eq '"status": *"(open|claimed|merged|done)"'

## Log
- 2026-10-15 blocked: INHERITED PARK — auto-filed by the capacity engine from a FOLLOW-UP line raised on ce-cadf, which was blocked (gate-owner main) at filing time. A child task must not become a copy button around its parent's gate: on 2026-08-09 ma-5ec5 cloned parked ma-1436 this way and re-armed an unattended meni-hub restart 71 minutes later (ce-ce4f). UNBLOCK PREDICATE: ce-cadf is unblocked — then re-scope this finding on its own merits (the parent's own work may already cover it) and unblock it too. Parent's reason: DONE on branch ce-cadf-followup-filed-as-tag fc51abe5 (pushed), NOT on main, awaiting an attended merge: landing on capacity-engine main IS a live deploy of the fleet dispatcher, and this change alters the auto-filer, so it wants a human landing rather than a self-merge. PREMISE: live but MISFILED. donefile CI is genuinely red (4 consecutive main runs; newest 38792741693, pushed 19:17:55Z, 3 test files / 5 tests failing), but that finding belongs to donefile and is already filed and IN FLIGHT as dn-ec2a (status claimed, session donefile-ci-red-again-20-9d14bc). ce-cadf is a cross-board DUPLICA [probe `s=$(cd /home/omri/projects/capacity-engine && node /home/omri/projects/donefile/dist/cli.js show ce-cadf --json) && printf '%s' "$s" | grep -Eq '"status": *"(open|claimed|merged|done)"'` exit 1, owner main]
- 2026-10-15 unblocked
- 2026-10-15 done by omri@ubuntu-4gb-nbg1-1 — test `cd /home/omri/projects/capacity-engine && n=0; for t in ce-0d9d ce-393c ce-8360 ce-9a8a ce-c2bc; do s=$(node /home/omri/projects/donefile/dist/cli.js show $t 2>/dev/null | grep -m1 "^status:" | awk "{print \$2}"); [ "$s" = "done" ] && n=$((n+1)); done; echo "capacity-engine duplicates closed: $n of 5"; [ "$n" -eq 5 ]` exit 0 (log: evidence/bt-9e13-2026-10-15T20-55-08Z-test.txt)
