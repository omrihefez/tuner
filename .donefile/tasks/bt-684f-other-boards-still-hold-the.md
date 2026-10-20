---
id: bt-684f
title: Other boards still hold the flag in blocked-task text (bass-tuner bt-0ead/bt-3f11, iac-2c5c,
  capacity-engine ce-4cc7/ce-df7d/ce-144c/ce-c54b/ce-4abb, meniapp ma-8345/ma-86ca, iac-d6fb,
  donefile dn-c229)
status: open
priority: p3
tags:
  - security
  - secrets
created: 2026-10-20
filed:
  owner: capacity-engine
  at: 2026-10-20T06:08:10Z
reported: 2026-10-20
---

Named in the finding: bt-0ead/bt-3f11, ce-4cc7/ce-df7d/ce-144c/ce-c54b/ce-4abb, ma-8345/ma-86ca

Why this is worth doing (from the reporting worker's own FOLLOW-UP line): `grep -rl -- '--client-secret=' /home/omri/projects/*/.donefile/tasks` lists them; I did not check whether any are live probes rather than prose, and each repo's sibling sweep task owns that.

<!-- capacity-engine: provenance, not part of the finding -->
UNVERIFIED CLAIM — auto-filed by the capacity engine from a worker's FOLLOW-UP line. The title above is that worker's own belief at the end of a session, written once, never checked by anything else: a well-formed, confident sentence can still be flatly wrong. Verify it against this repo's CURRENT state before doing anything else, then scope it before claiming (ce-916b).

Discovered while working kd-d007, session `sweep-other-blocked-task-d85711`, dispatched on kidai.
See 'reported' in this task's frontmatter for the date this finding was originally observed — read any relative time in the title above ("this morning", "currently", "still", "right now") as dated from THAT day, not from when this task was filed.
This finding named multiple repos explicitly and was filed separately on each: also on donefile, meniapp, capacity-engine (ce-71de). Scope this task to the part that is actually about kidai; the siblings cover the rest.
That task's report closed DONE (commit 23c2566571d9 — does not resolve here, see below).

PROVENANCE COMMIT DOES NOT RESOLVE HERE — `23c2566571d9` does not exist in this repo. It is the evidence commit from the task/board that raised this line, not this one — don't spend time trying to `git show` it here. Treat the finding above as UNVERIFIED and check whether it is still true against this repo's CURRENT state before doing anything else (ce-5112).

DONE WHEN: the finding above is either fixed and verified, or shown not to be real — say which in the closing evidence.
