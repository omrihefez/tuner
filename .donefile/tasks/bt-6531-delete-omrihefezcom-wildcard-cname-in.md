---
id: bt-6531
title: Delete *.omrihefez.com wildcard CNAME in generated.tf — bass-tuner
status: open
priority: p3
tags:
  - dns
  - security
created: 2026-11-26
filed:
  owner: capacity-engine
  at: 2026-11-26T10:39:25Z
reported: 2026-11-26
---

Why this is worth doing (from the reporting worker's own FOLLOW-UP line): blocked on kidai getting an explicit record or ny-tear-down-kidai, switching check-public-surfaces.sh pete rows + bass-tuner audit-domains.sh + DOMAIN.md to expect NXDOMAIN, and checking whether the Vercel wildcard cert (bt-113a/bt-2593/bt-f900) is still needed

<!-- capacity-engine: provenance, not part of the finding -->
UNVERIFIED CLAIM — auto-filed by the capacity engine from a worker's FOLLOW-UP line. The title above is that worker's own belief at the end of a session, written once, never checked by anything else: a well-formed, confident sentence can still be flatly wrong. Verify it against this repo's CURRENT state before doing anything else, then scope it before claiming (ce-916b).

Discovered while working iac-2677, session `retire-or-re-justify-the-3e11c1`, dispatched on iac.
See 'reported' in this task's frontmatter for the date this finding was originally observed — read any relative time in the title above ("this morning", "currently", "still", "right now") as dated from THAT day, not from when this task was filed.
This finding named multiple repos explicitly and was filed separately on each: also on kidai (ce-71de). Scope this task to the part that is actually about iac; the siblings cover the rest.
That task's report closed DONE (commit 9a1c69653a0911e50ced13f8c689edd545cf9b2f — does not resolve here, see below).

PROVENANCE COMMIT DOES NOT RESOLVE HERE — `9a1c69653a0911e50ced13f8c689edd545cf9b2f` does not exist in this repo. It is the evidence commit from the task/board that raised this line, not this one — don't spend time trying to `git show` it here. Treat the finding above as UNVERIFIED and check whether it is still true against this repo's CURRENT state before doing anything else (ce-5112).

DONE WHEN: the finding above is either fixed and verified, or shown not to be real — say which in the closing evidence.

## Gate
PROBE: dig +noall +comments nxprobe-bt6531.omrihefez.com @1.1.1.1 | grep -q NXDOMAIN


## Log
- 2026-11-26 claimed by capacity-engine
- 2026-11-26 PREMISE-PROBE: ! git -C /home/omri/projects/iac grep -q 'name *= *"\*.omrihefez.com"' origin/main -- cloudflare/generated.tf
- 2026-11-26 claim by capacity-engine parked (blocked)
- 2026-11-26 blocked: Premise live but prerequisites unmet (iac-2677 decision: KEEP for now). Wildcard at iac cloudflare/generated.tf:241 still serves paused kidai, which has no explicit record; deleting it breaks kidai and the pete tombstone monitors (check-public-surfaces.sh, audit-domains.sh, DOMAIN.md must flip to expect NXDOMAIN in the same change). bt-113a closed: cert not a blocker. Needs kidai explicit record or teardown first; the delete itself is an iac change, not bass-tuner. [probe `git -C /home/omri/projects/iac grep -q 'name *= *"kidai.omrihefez.com"' origin/main -- cloudflare/generated.tf` exit 1, owner main]
- 2026-11-26 unblocked
- 2026-11-26 blocked: Main decision 2026-11-26: KEEP the wildcard until kidai is torn down (kd-dcc4) or gets an explicit record. Then delete the wildcard in iac and flip pete/pete-api expectations to NXDOMAIN in check-public-surfaces.sh, audit-domains.sh and DOMAIN.md in one change (steps in iac generated.tf:221-238). [probe `git -C /home/omri/projects/iac grep -c "name *= *\"kidai.omrihefez.com\"" origin/main -- cloudflare/generated.tf` exit 1, owner upstream]
- 2026-11-26 FOLLOW-UP restating this task (50% title overlap) was NOT filed as a child: Delete wildcard CNAME in iac and flip check-public-surfaces.sh pete rows, bass-tuner scripts/audit-domains.sh and DOMAIN.md pete/pete-api rows to expect NXDOMAIN in one change [p3] — why: only after kidai has an explicit record or is torn down; iac-2677 comment at generated.tf:221-238 lists the steps (ce-ea18; a child parked on its own parent adds no work the parent's closure does not already require)
- 2026-11-26 FOLLOW-UP restating this task (50% title overlap) was NOT filed as a child: Delete wildcard CNAME in iac and flip check-public-surfaces.sh pete rows, bass-tuner scripts/audit-domains.sh and DOMAIN.md pete/pete-api rows to expect NXDOMAIN in one change [p3] — why: only after kidai has an explicit record or is torn down; iac-2677 comment at generated.tf:221-238 lists the steps (ce-ea18; a child parked on its own parent adds no work the parent's closure does not already require)
- 2026-11-26 unblocked
- 2026-11-26 Main 2026-11-26: kd-dcc4 DONE (kidai torn down, now 404 via wildcard). Go: delete cname_wildcard in iac generated.tf (attended terraform apply = park for Main with the plan output), and in the same change set flip kidai + pete/pete-api expectations to NXDOMAIN in ~/meni/bin/check-public-surfaces.sh (report the diff to Main — workers do not write ~/meni), bass-tuner audit-domains.sh, and DOMAIN.md rows (also via Main).
- 2026-11-26 claimed by capacity-engine
- 2026-11-26 claim by capacity-engine parked (blocked)
- 2026-11-26 blocked: iac deletion ready on branch bt-6531-delete-wildcard-cname (5d1f2c8d), NOT on iac main and NOT applied: needs attended terraform apply by Main/Omri. Then Main flips ~/meni/bin/check-public-surfaces.sh kidai/pete rows to NXDOMAIN and ~/meni/DOMAIN.md. bass-tuner audit-domains.sh needs no change (derives hosts from DOMAIN.md; retired hosts already skip on NXDOMAIN). [probe `dig +noall +comments nxprobe-bt6531.omrihefez.com @1.1.1.1 | grep -q NXDOMAIN` exit 1, owner main]
- 2026-11-26 unblocked
