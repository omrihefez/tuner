---
id: bt-d638
title: trips.omrihefez.com has no object-src directive, falls back to default-src 'self', flagged by
  check-csp-strength.sh as missing explicit 'none'
status: done
priority: p3
tags:
  - security
  - csp
  - trips-hub
created: 2026-10-13
filed:
  owner: capacity-engine
  at: 2026-10-13T04:58:06Z
reported: 2026-10-13
done:
  at: 2026-10-13T07:06:39Z
  by: capacity-engine
evidence:
  - type: commit
    value: f9c4ed11eb194ece7aecebcc95b0a426942da873
    repo: trips-hub
    verified: 2026-10-13T07:06:39Z
  - type: test
    cmd: cd /home/omri/projects/trips-hub && git show
      f9c4ed11eb194ece7aecebcc95b0a426942da873:lib/csp.ts | grep -n "object-src 'none'"
    exit: 0
    at: 2026-10-13T07:06:38Z
    log: evidence/bt-d638-2026-10-13T07-06-38Z-test.txt
    sha256: f9c28fc8a7ff1fd282eed454a8fd5b49a01ff71ec804b62798add5594000458b
    bytes: 158
  - type: live
    cmd: curl -sI https://trips.omrihefez.com/ | grep -i object-src
    exit: 0
    at: 2026-10-13T07:06:38Z
    log: evidence/bt-d638-2026-10-13T07-06-38Z-live.txt
    sha256: 7419b577127819c88f4e21420ac0ac91a310db7d5ab2813a73569e064a659789
    bytes: 628
  - type: note
    value: Misfiled on bass-tuner (check-csp-strength.sh's monitor lives here, already covers object-src
      for all hosts since 6844de75); the actual fix for trips.omrihefez.com's own header is
      trips-hub's buildCSP() in lib/csp.ts, done as th-1ddc on trips-hub's board and confirmed live.
---

Named in the finding: check-csp-strength.sh

Why this is worth doing (from the reporting worker's own FOLLOW-UP line): live header 2026-10-13 shows "object-src missing 'none' (effective value: 'self')" alongside the img-src finding; not covered by th-07a5's title, no existing task found for it

LIKELY ALREADY DONE — verify before building. Work merged after this finding was raised may already cover it:
- `6844de75` 2026-10-13 "bt-2c67: check-csp-strength.sh now asserts object-src/base-uri/frame-ancestors" — scripts/check-csp-strength.sh, scripts/check-csp-strength.test.sh, test/vercel-headers.test.js, vercel.json (touches check-csp-strength.sh; 72% of the finding's words)

START HERE: check whether that work satisfies this finding. If it does, close with `--commit <sha>` and say so — that is a complete, correct closure, not a shortcut. If it does not, say in one line what it missed and do the work.
This is a word/file-path heuristic run at filing time, NOT a proof — it exists so the claimer starts from "verify" instead of spending a whole round rediscovering that it shipped (ce-a792).

<!-- capacity-engine: provenance, not part of the finding -->
UNVERIFIED CLAIM — auto-filed by the capacity engine from a worker's FOLLOW-UP line. The title above is that worker's own belief at the end of a session, written once, never checked by anything else: a well-formed, confident sentence can still be flatly wrong. Verify it against this repo's CURRENT state before doing anything else, then scope it before claiming (ce-916b).

Discovered while working th-07a5, session `trips-omrihefez-com-s-im-75061a`, dispatched on trips-hub.
See 'reported' in this task's frontmatter for the date this finding was originally observed — read any relative time in the title above ("this morning", "currently", "still", "right now") as dated from THAT day, not from when this task was filed.
That task's report closed DONE (commit 5b0c6337e81afafb3bd7231c31b7de815c302256 — does not resolve here, see below).

PROVENANCE COMMIT DOES NOT RESOLVE HERE — `5b0c6337e81afafb3bd7231c31b7de815c302256` does not exist in this repo. It is the evidence commit from the task/board that raised this line, not this one — don't spend time trying to `git show` it here. Treat the finding above as UNVERIFIED and check whether it is still true against this repo's CURRENT state before doing anything else (ce-5112).

DONE WHEN: the finding above is either fixed and verified, or shown not to be real — say which in the closing evidence.

## Log
- 2026-10-13 claimed by capacity-engine
- 2026-10-13 done by capacity-engine — commit f9c4ed11eb19 (trips-hub), test `cd /home/omri/projects/trips-hub && git show f9c4ed11eb194ece7aecebcc95b0a426942da873:lib/csp.ts | grep -n "object-src 'none'"` exit 0 (log: evidence/bt-d638-2026-10-13T07-06-38Z-test.txt), live `curl -sI https://trips.omrihefez.com/ | grep -i object-src` exit 0 (log: evidence/bt-d638-2026-10-13T07-06-38Z-live.txt)
