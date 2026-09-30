---
id: bt-d945
title: brain.omrihefez.com and oauth.omrihefez.com are missing Strict-Transport-Security in production
status: done
priority: p3
tags:
  - security
created: 2026-10-01
filed:
  owner: capacity-engine
  at: 2026-09-30T21:05:50Z
reported: 2026-09-30
done:
  at: 2026-09-30T23:39:07Z
  by: capacity-engine/worker
  waived: actual fix landed outside bass-tuner (second-brain commit 10ac884 / sb-1795, and apartment
    commit 6f302a5 / ap-d148, both live-verified separately); bass-tuner's own deliverable here was
    detection only (bt-b75b/8c91290a), already deployed, nothing on bass-tuner's own served surface
    changed
evidence:
  - type: commit
    value: 8c91290af49ec651a55aa623a0420c857049d736
    verified: 2026-09-30T23:39:07Z
  - type: test
    cmd: bash scripts/audit-domains.sh 2>&1 | grep -E
      'brain\.omrihefez\.com/|oauth\.omrihefez\.com/health' | grep -c 'Strict-Transport-Security
      present' | grep -qx 2
    exit: 0
    at: 2026-09-30T23:39:04Z
    log: evidence/bt-d945-2026-09-30T23-39-04Z-test.txt
    sha256: 2d8647c19a9cdc71b1daf97cd62670ef54df1b95dc85c585a49447e5bc36474b
    bytes: 161
  - type: note
    value: "Finding was real: brain.omrihefez.com had HSTS already fixed (second-brain sb-1795, commit
      10ac884, ~30min before this task was dispatched). oauth.omrihefez.com genuinely had none --
      fixed live in apartment repo (ap-d148, commit 6f302a5, systemctl restart meni-oauth-callback,
      verified on oauth.omrihefez.com/health). bass-tuner's own part (detection tooling,
      bt-b75b/8c91290a) was already correct -- it's what surfaced this finding; no bass-tuner code
      change was needed."
---

Why this is worth doing (from the reporting worker's own FOLLOW-UP line): confirmed live 2026-10-01 — brain's 404 and oauth's /health 200 both carry zero HSTS; fix belongs in second-brain and apartment repos respectively, not bass-tuner (this task was detection-only)

LIKELY ALREADY DONE — verify before building. Work merged after this finding was raised may already cover it:
- `8c91290a` 2026-09-30 "audit-domains.sh: assert Strict-Transport-Security on non-Vercel hosts (bt-b75b)" — scripts/audit-domains.sh, scripts/audit-domains.test.sh (67% of the finding's words)

START HERE: check whether that work satisfies this finding. If it does, close with `--commit <sha>` and say so — that is a complete, correct closure, not a shortcut. If it does not, say in one line what it missed and do the work.
This is a word/file-path heuristic run at filing time, NOT a proof — it exists so the claimer starts from "verify" instead of spending a whole round rediscovering that it shipped (ce-a792).

<!-- capacity-engine: provenance, not part of the finding -->
UNVERIFIED CLAIM — auto-filed by the capacity engine from a worker's FOLLOW-UP line. The title above is that worker's own belief at the end of a session, written once, never checked by anything else: a well-formed, confident sentence can still be flatly wrong. Verify it against this repo's CURRENT state before doing anything else, then scope it before claiming (ce-916b).

Discovered while working bt-b75b, session `audit-domains-sh-never-a-06cfd2`, dispatched on bass-tuner.
See 'reported' in this task's frontmatter for the date this finding was originally observed — read any relative time in the title above ("this morning", "currently", "still", "right now") as dated from THAT day, not from when this task was filed.
That task's report closed DONE (commit 8c91290af49ec651a55aa623a0420c857049d736).

DONE WHEN: the finding above is either fixed and verified, or shown not to be real — say which in the closing evidence.

## Log
- 2026-10-01 blocker bt-b75b closed 2026-09-30T21:01:49Z — recheck whether this can proceed now.
- 2026-10-01 claimed by capacity-engine
- 2026-10-01 done by capacity-engine/worker — commit 8c91290af49e, test `bash scripts/audit-domains.sh 2>&1 | grep -E 'brain\.omrihefez\.com/|oauth\.omrihefez\.com/health' | grep -c 'Strict-Transport-Security present' | grep -qx 2` exit 0 (log: evidence/bt-d945-2026-09-30T23-39-04Z-test.txt) (evidence waived: actual fix landed outside bass-tuner (second-brain commit 10ac884 / sb-1795, and apartment commit 6f302a5 / ap-d148, both live-verified separately); bass-tuner's own deliverable here was detection only (bt-b75b/8c91290a), already deployed, nothing on bass-tuner's own served surface changed)
