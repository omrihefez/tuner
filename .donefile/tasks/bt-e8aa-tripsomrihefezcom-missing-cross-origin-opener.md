---
id: bt-e8aa
title: trips.omrihefez.com missing Cross-Origin-Opener-Policy/Cross-Origin-Resource-Policy
status: done
priority: p3
tags:
  - security
  - http-headers
created: 2026-10-10
filed:
  owner: capacity-engine
  at: 2026-10-10T17:58:14Z
reported: 2026-10-10
done:
  at: 2026-10-10T18:22:47Z
  by: capacity-engine/worker
evidence:
  - type: live
    cmd: "curl -sI https://trips.omrihefez.com/ | grep -qi 'cross-origin-opener-policy: same-origin' &&
      curl -sI https://trips.omrihefez.com/ | grep -qi 'cross-origin-resource-policy: same-origin'"
    exit: 0
    at: 2026-10-10T18:22:47Z
    log: evidence/bt-e8aa-2026-10-10T18-22-47Z-live.txt
    sha256: f5dabd14ea183e1863f84033dfd08805172ec1dc81f627e6d207a1ec4a443de7
    bytes: 190
  - type: note
    value: "Not a real bass-tuner task: duplicate finding auto-filed on the wrong board. The actual fix
      (COOP/CORP headers on trips.omrihefez.com's next.config) landed on trips-hub's own board as
      th-f5bc, commit 4d575d8e1641 promoted to main as fb65972d, deployed, done 2026-10-10T18:07Z --
      minutes before this task (bt-e8aa) was even filed. trips-hub has no repo alias on this board
      so the commit cannot be cited here; closing on fresh live verification instead, re-run just
      now and matching th-f5bc's own recorded live evidence."
---

Named in the finding: cross-origin-opener-policy/cross-origin-resource-policy

Why this is worth doing (from the reporting worker's own FOLLOW-UP line): already tracked as th-f5bc (open) on trips-hub's own board — not re-filed here, just surfaced by this baseline change.

LIKELY ALREADY DONE — verify before building. Work merged after this finding was raised may already cover it:
- `e88178bd` 2026-10-10 "audit-domains.sh: add COOP/CORP to the security-header baseline (bt-1176)" — scripts/audit-domains.sh, scripts/audit-domains.test.sh (67% of the finding's words)

START HERE: check whether that work satisfies this finding. If it does, close with `--commit <sha>` and say so — that is a complete, correct closure, not a shortcut. If it does not, say in one line what it missed and do the work.
This is a word/file-path heuristic run at filing time, NOT a proof — it exists so the claimer starts from "verify" instead of spending a whole round rediscovering that it shipped (ce-a792).

<!-- capacity-engine: provenance, not part of the finding -->
UNVERIFIED CLAIM — auto-filed by the capacity engine from a worker's FOLLOW-UP line. The title above is that worker's own belief at the end of a session, written once, never checked by anything else: a well-formed, confident sentence can still be flatly wrong. Verify it against this repo's CURRENT state before doing anything else, then scope it before claiming (ce-916b).

Discovered while working bt-1176, session `audit-domains-sh-s-secur-b15d66`, dispatched on bass-tuner.
See 'reported' in this task's frontmatter for the date this finding was originally observed — read any relative time in the title above ("this morning", "currently", "still", "right now") as dated from THAT day, not from when this task was filed.
Board choice is a GUESS: this follow-up names a file but the engine could not match it to exactly one board's repo, so it stayed on the dispatching board rather than being routed. Verify it belongs here before working it — it may need re-filing on the board that actually owns the named file (ce-3b8d).
That task's report closed DONE (commit e88178b).

DONE WHEN: the finding above is either fixed and verified, or shown not to be real — say which in the closing evidence.

## Log
- 2026-10-10 claimed by capacity-engine
- 2026-10-10 done by capacity-engine/worker — live `curl -sI https://trips.omrihefez.com/ | grep -qi 'cross-origin-opener-policy: same-origin' && curl -sI https://trips.omrihefez.com/ | grep -qi 'cross-origin-resource-policy: same-origin'` exit 0 (log: evidence/bt-e8aa-2026-10-10T18-22-47Z-live.txt)
