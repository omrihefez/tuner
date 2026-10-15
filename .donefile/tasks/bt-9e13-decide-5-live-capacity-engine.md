---
id: bt-9e13
title: Decide 5 live capacity-engine tasks that are duplicates of open tasks on the correct boards —
  bass-tuner
status: blocked
priority: p2
tags:
  - dedupe
  - board-hygiene
created: 2026-10-15
filed:
  owner: capacity-engine
  at: 2026-10-15T20:48:44Z
reported: 2026-10-15
blocked:
  reason: "INHERITED PARK — auto-filed by the capacity engine from a FOLLOW-UP line raised on ce-cadf,
    which was blocked (gate-owner main) at filing time. A child task must not become a copy button
    around its parent's gate: on 2026-08-09 ma-5ec5 cloned parked ma-1436 this way and re-armed an
    unattended meni-hub restart 71 minutes later (ce-ce4f). UNBLOCK PREDICATE: ce-cadf is unblocked
    — then re-scope this finding on its own merits (the parent's own work may already cover it) and
    unblock it too. Parent's reason: DONE on branch ce-cadf-followup-filed-as-tag fc51abe5 (pushed),
    NOT on main, awaiting an attended merge: landing on capacity-engine main IS a live deploy of the
    fleet dispatcher, and this change alters the auto-filer, so it wants a human landing rather than
    a self-merge. PREMISE: live but MISFILED. donefile CI is genuinely red (4 consecutive main runs;
    newest 38792741693, pushed 19:17:55Z, 3 test files / 5 tests failing), but that finding belongs
    to donefile and is already filed and IN FLIGHT as dn-ec2a (status claimed, session
    donefile-ci-red-again-20-9d14bc). ce-cadf is a cross-board DUPLICA"
  since: 2026-10-15
  probe:
    cmd: "s=$(cd /home/omri/projects/capacity-engine && node /home/omri/projects/donefile/dist/cli.js
      show ce-cadf --json) && printf '%s' \"$s\" | grep -Eq '\"status\":
      *\"(open|claimed|merged|done)\"'"
    exit: 1
    at: 2026-10-15T20:48:52Z
    log: evidence/bt-9e13-2026-10-15T20-48-52Z-probe.txt
    sha256: fb98c36fca9d2d26dd56c9c6c0e20f40a28f81ef8111723e46da462037c3f73b
    bytes: 189
  gate_owner: main
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
GATE-OWNER: main

## Log
- 2026-10-15 blocked: INHERITED PARK — auto-filed by the capacity engine from a FOLLOW-UP line raised on ce-cadf, which was blocked (gate-owner main) at filing time. A child task must not become a copy button around its parent's gate: on 2026-08-09 ma-5ec5 cloned parked ma-1436 this way and re-armed an unattended meni-hub restart 71 minutes later (ce-ce4f). UNBLOCK PREDICATE: ce-cadf is unblocked — then re-scope this finding on its own merits (the parent's own work may already cover it) and unblock it too. Parent's reason: DONE on branch ce-cadf-followup-filed-as-tag fc51abe5 (pushed), NOT on main, awaiting an attended merge: landing on capacity-engine main IS a live deploy of the fleet dispatcher, and this change alters the auto-filer, so it wants a human landing rather than a self-merge. PREMISE: live but MISFILED. donefile CI is genuinely red (4 consecutive main runs; newest 38792741693, pushed 19:17:55Z, 3 test files / 5 tests failing), but that finding belongs to donefile and is already filed and IN FLIGHT as dn-ec2a (status claimed, session donefile-ci-red-again-20-9d14bc). ce-cadf is a cross-board DUPLICA [probe `s=$(cd /home/omri/projects/capacity-engine && node /home/omri/projects/donefile/dist/cli.js show ce-cadf --json) && printf '%s' "$s" | grep -Eq '"status": *"(open|claimed|merged|done)"'` exit 1, owner main]
