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
