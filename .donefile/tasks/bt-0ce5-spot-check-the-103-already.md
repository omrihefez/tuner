---
id: bt-0ce5
title: Spot-check the ~103 already-waived EVIDENCE_TASK_MISMATCH records on
  capacity-engine/trips-hub/iac/meni-arch/bass-tuner/tik-next/house-control/kidai/meni-music/apartment*
status: open
priority: p3
tags:
  - donefile
  - audit
created: 2026-10-13
filed:
  owner: capacity-engine
  at: 2026-10-13T17:57:36Z
reported: 2026-10-13
---

Named in the finding: capacity-engine/trips-hub/iac/meni-arch/bass-tuner/tik-next/house-control/kidai/meni-music/apartment

Why this is worth doing (from the reporting worker's own FOLLOW-UP line): I only sampled donefile/second-brain/tik-api/vidsmith (all legitimate); the rest were never individually re-verified, just assumed-fine by pattern

POSSIBLE SAME-REPORT DUPLICATE — another FOLLOW-UP line in the SAME worker report reads: "Investigate and fix df-31c0's wrong evidence sha on ~/meni" (50% overlap, scored without the repo gate). Both were raised by one session's one closing report, so the odds these describe the same finding worded two ways are much higher than for an unrelated board task. Filed anyway (see followupCrossBoardNote's own reasoning for why dropping would be worse) — find where that sibling line landed BEFORE claiming this one; if it's the same fix, close this one citing that task's evidence instead of re-implementing it.

<!-- capacity-engine: provenance, not part of the finding -->
UNVERIFIED CLAIM — auto-filed by the capacity engine from a worker's FOLLOW-UP line. The title above is that worker's own belief at the end of a session, written once, never checked by anything else: a well-formed, confident sentence can still be flatly wrong. Verify it against this repo's CURRENT state before doing anything else, then scope it before claiming (ce-916b).

Discovered while working dn-92e7, session `evidence-task-mismatch-r-1cf160`, dispatched on donefile.
See 'reported' in this task's frontmatter for the date this finding was originally observed — read any relative time in the title above ("this morning", "currently", "still", "right now") as dated from THAT day, not from when this task was filed.
This finding named multiple repos explicitly and was filed separately on each: also on meni-arch, iac, tik-api, vidsmith, tik-next, trips-hub, second-brain, capacity-engine, kidai, house-control, meni-music, apartment (ce-71de). Scope this task to the part that is actually about donefile; the siblings cover the rest.
That task's report closed DONE (commit ebfb3502fd1e — does not resolve here, see below).

PROVENANCE COMMIT DOES NOT RESOLVE HERE — `ebfb3502fd1e` does not exist in this repo. It is the evidence commit from the task/board that raised this line, not this one — don't spend time trying to `git show` it here. Treat the finding above as UNVERIFIED and check whether it is still true against this repo's CURRENT state before doing anything else (ce-5112).

DONE WHEN: the finding above is either fixed and verified, or shown not to be real — say which in the closing evidence.
