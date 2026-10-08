---
id: bt-1336
title: oauth's /clips/<name>.mp3 path (server.py) also bypasses security headers but has no stable
  registry-known filename this audit script can pin without guessing
status: done
priority: p3
tags:
  - monitoring
  - security
created: 2026-10-08
filed:
  owner: capacity-engine
  at: 2026-10-08T01:15:30Z
reported: 2026-10-08
done:
  at: 2026-10-08T08:04:54Z
  by: capacity-engine/worker
  waived: cross-repo citation (apartment, not bass-tuner's own Vercel surface) -- bass-tuner's
    'security' tag auto-gates activation but this task's deployed surface is
    meni-oauth-callback.service in a different repo, already restarted and live-verified under
    ap-2037 (2026-10-08 05:56 IDT, before bt-1336 was claimed); the --test above is a fresh
    independent live re-check, not a restart command for this board
evidence:
  - type: commit
    value: de53f0f07ba8f33ecdb7f527252ebe9715b9d3a9
    repo: /home/omri/apartment
    verified: 2026-10-08T08:04:54Z
  - type: test
    cmd: "curl -sI https://oauth.omrihefez.com/clips/2550bf96a0ef639b.mp3 | grep -qi
      'x-content-type-options: nosniff' && curl -sI
      https://oauth.omrihefez.com/clips/2550bf96a0ef639b.mp3 | grep -qi 'content-security-policy'"
    exit: 0
    at: 2026-10-08T08:04:54Z
    log: evidence/bt-1336-2026-10-08T08-04-54Z-test.txt
    sha256: cc93278a73b2e3f392e4125545ae5591c4eca7a3a578193d7219a0349e95b441
    bytes: 216
  - type: note
    value: "not real / already fixed: /clips/ hit-path header bypass was fixed and deployed by a
      separate worker on the apartment repo (task ap-2037, commit de53f0f, 2026-10-08 05:56 IDT --
      before bt-1336 was even claimed). _security_headers() is now shared by _html(), do_HEAD and
      the /clips/ hit path. Verified fresh here, live, against a real file (2550bf96a0ef639b.mp3):
      nosniff + CSP + referrer-policy all present on the /clips/ response. apartment's own
      test_server.py (4/4 tests incl. test_clips_hit_has_baseline) also passes fresh. bt-1336 was
      filed on bass-tuner's board only because the follow-up line that spawned it named server.py
      without a repo and the dispatcher could not resolve which repo owned it (ce-3b8d) -- the real
      file lives in ~/apartment (local, no remote -- see its own config.yml ci_waiver), not
      bass-tuner. No bass-tuner code change needed."
---

Named in the finding: server.py

Why this is worth doing (from the reporting worker's own FOLLOW-UP line): server.py's /clips/ handler skips the _html() helper entirely, same bypass class as /health used to be, but audit-domains.sh can only probe named paths and no stable one is documented

<!-- capacity-engine: provenance, not part of the finding -->
UNVERIFIED CLAIM — auto-filed by the capacity engine from a worker's FOLLOW-UP line. The title above is that worker's own belief at the end of a session, written once, never checked by anything else: a well-formed, confident sentence can still be flatly wrong. Verify it against this repo's CURRENT state before doing anything else, then scope it before claiming (ce-916b).

Discovered while working bt-0611, session `audit-domains-sh-exempts-2286c2`, dispatched on bass-tuner.
See 'reported' in this task's frontmatter for the date this finding was originally observed — read any relative time in the title above ("this morning", "currently", "still", "right now") as dated from THAT day, not from when this task was filed.
Board choice is a GUESS: this follow-up names a file but the engine could not match it to exactly one board's repo, so it stayed on the dispatching board rather than being routed. Verify it belongs here before working it — it may need re-filing on the board that actually owns the named file (ce-3b8d).
That task's report closed DONE (commit f5c1942).

DONE WHEN: the finding above is either fixed and verified, or shown not to be real — say which in the closing evidence.

## Log
- 2026-10-08 claimed by capacity-engine
- 2026-10-08 done by capacity-engine/worker — commit de53f0f07ba8 (/home/omri/apartment), test `curl -sI https://oauth.omrihefez.com/clips/2550bf96a0ef639b.mp3 | grep -qi 'x-content-type-options: nosniff' && curl -sI https://oauth.omrihefez.com/clips/2550bf96a0ef639b.mp3 | grep -qi 'content-security-policy'` exit 0 (log: evidence/bt-1336-2026-10-08T08-04-54Z-test.txt) (evidence waived: cross-repo citation (apartment, not bass-tuner's own Vercel surface) -- bass-tuner's 'security' tag auto-gates activation but this task's deployed surface is meni-oauth-callback.service in a different repo, already restarted and live-verified under ap-2037 (2026-10-08 05:56 IDT, before bt-1336 was claimed); the --test above is a fresh independent live re-check, not a restart command for this board)
