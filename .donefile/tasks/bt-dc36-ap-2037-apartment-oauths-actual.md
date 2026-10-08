---
id: bt-dc36
title: ap-2037 (apartment, oauth's actual missing CSP/nosniff on the live host) is the companion fix
  this task's audit gap was hiding — still open per last check, worth prioritizing now that the
  auditor can see it
status: done
priority: p2
tags:
  - security
created: 2026-10-08
filed:
  owner: capacity-engine
  at: 2026-10-08T01:15:37Z
reported: 2026-10-08
done:
  at: 2026-10-08T02:57:31Z
  by: capacity-engine/worker
  waived: "security tag is a false positive for activation-gating here, same as bt-0611: this task
    touches zero bass-tuner files (nothing to deploy in this repo). The actual fix landed and was
    activated in apartment's oauth-callback service, tracked separately as ap-2037."
evidence:
  - type: test
    cmd: "curl -sI https://oauth.omrihefez.com/health | grep -qi content-security-policy && curl -sI
      https://oauth.omrihefez.com/health | grep -qi 'x-content-type-options: nosniff'"
    exit: 0
    at: 2026-10-08T02:57:31Z
    log: evidence/bt-dc36-2026-10-08T02-57-31Z-test.txt
    sha256: 6936ecd9855b0df3da2d05ec501a774c49e2d23e1c2f3d6ea58998173878320e
    bytes: 174
  - type: note
    value: "Premise was live: ap-2037's finding (oauth-callback do_HEAD + /clips/ hit path missing
      CSP/nosniff) was real and still open. Fixed and closed in apartment repo (unregistered board,
      no remote): commit de53f0f factors _html()'s header block into a shared _security_headers()
      helper called from all 3 response paths; new smarthome/oauth-callback/test_server.py exercises
      each path, confirmed to fail against the pre-fix do_HEAD and pass after. Service restarted
      2026-10-08 05:56 IDT; live curl confirms CSP/referrer-policy/nosniff now present. ap-2037
      itself closed done in apartment's own donefile (commit de53f0f, --live evidence) — see that
      task for the full evidence chain. No bass-tuner files touched; this closes the finding bt-dc36
      was filed to track."
---

Named in the finding: csp/nosniff

Why this is worth doing (from the reporting worker's own FOLLOW-UP line): this task only fixed the blind spot, not the live exposure it was failing to see

<!-- capacity-engine: provenance, not part of the finding -->
UNVERIFIED CLAIM — auto-filed by the capacity engine from a worker's FOLLOW-UP line. The title above is that worker's own belief at the end of a session, written once, never checked by anything else: a well-formed, confident sentence can still be flatly wrong. Verify it against this repo's CURRENT state before doing anything else, then scope it before claiming (ce-916b).

Discovered while working bt-0611, session `audit-domains-sh-exempts-2286c2`, dispatched on bass-tuner.
See 'reported' in this task's frontmatter for the date this finding was originally observed — read any relative time in the title above ("this morning", "currently", "still", "right now") as dated from THAT day, not from when this task was filed.
Board choice is a GUESS: this follow-up names a file but the engine could not match it to exactly one board's repo, so it stayed on the dispatching board rather than being routed. Verify it belongs here before working it — it may need re-filing on the board that actually owns the named file (ce-3b8d).
That task's report closed DONE (commit f5c1942).

DONE WHEN: the finding above is either fixed and verified, or shown not to be real — say which in the closing evidence.

## Log
- 2026-10-08 claimed by capacity-engine
- 2026-10-08 done by capacity-engine/worker — test `curl -sI https://oauth.omrihefez.com/health | grep -qi content-security-policy && curl -sI https://oauth.omrihefez.com/health | grep -qi 'x-content-type-options: nosniff'` exit 0 (log: evidence/bt-dc36-2026-10-08T02-57-31Z-test.txt) (evidence waived: security tag is a false positive for activation-gating here, same as bt-0611: this task touches zero bass-tuner files (nothing to deploy in this repo). The actual fix landed and was activated in apartment's oauth-callback service, tracked separately as ap-2037.)
