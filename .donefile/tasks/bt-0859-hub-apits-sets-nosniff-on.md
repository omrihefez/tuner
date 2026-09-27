---
id: bt-0859
title: hub api.ts sets nosniff on only one route, not globally
status: done
priority: p3
tags:
  - security
  - monitoring
created: 2026-09-27
filed:
  owner: capacity-engine
  at: 2026-09-27T19:03:58Z
reported: 2026-09-27
done:
  at: 2026-09-27T19:43:52Z
  by: capacity-engine/worker
  waived: "no deploy applies: not this repo's code, nothing changed here — finding is a routing
    duplicate of ma-7c75 on meniapp's board"
evidence:
  - type: test
    cmd: 'test ! -e /home/omri/projects/bass-tuner/api.ts && node
      /home/omri/projects/donefile/dist/cli.js show ma-7c75 | grep -q "status: open"'
    exit: 0
    at: 2026-09-27T19:43:48Z
    log: evidence/bt-0859-2026-09-27T19-43-48Z-test.txt
    sha256: 09d48fe81d7977c4ab5a10052b9515d57535b17fa4a8273735c3c4a97c41a249
    bytes: 138
  - type: note
    value: "Not real for THIS repo: hub/api.ts does not exist in bass-tuner at all (grep/find confirm),
      so the finding cannot apply here. Traced the file to meniapp/hub/src/api.ts. The original
      worker (session assert-live-security-hea-4436a2, bt-d173) already filed the correctly-scoped
      finding directly on meniapp's board as ma-7c75 (open, p3) before capacity-engine also
      auto-filed this duplicate on bass-tuner from the same FOLLOW-UP line, per ce-3b8d's
      board-mismatch note. Verified: /health (JSON, line 2241 of meniapp/hub/src/api.ts) sends no
      x-content-type-options; nosniff is only set ad hoc on 3 binary/streaming routes
      (health/payload, punchlist photos, artifacts). No global header middleware exists. Closing
      here as a routing duplicate; the real fix belongs to and is tracked on ma-7c75."
---

Named in the finding: api.ts

Why this is worth doing (from the reporting worker's own FOLLOW-UP line): filed as ma-7c75, live curl confirms /health missing x-content-type-options

<!-- capacity-engine: provenance, not part of the finding -->
UNVERIFIED CLAIM — auto-filed by the capacity engine from a worker's FOLLOW-UP line. The title above is that worker's own belief at the end of a session, written once, never checked by anything else: a well-formed, confident sentence can still be flatly wrong. Verify it against this repo's CURRENT state before doing anything else, then scope it before claiming (ce-916b).

Discovered while working bt-d173, session `assert-live-security-hea-4436a2`, dispatched on bass-tuner.
See 'reported' in this task's frontmatter for the date this finding was originally observed — read any relative time in the title above ("this morning", "currently", "still", "right now") as dated from THAT day, not from when this task was filed.
Board choice is a GUESS: this follow-up names a file but the engine could not match it to exactly one board's repo, so it stayed on the dispatching board rather than being routed. Verify it belongs here before working it — it may need re-filing on the board that actually owns the named file (ce-3b8d).
That task's report closed DONE (commit 05a2c35855f462681688c280de268c2785f4419c).

DONE WHEN: the finding above is either fixed and verified, or shown not to be real — say which in the closing evidence.

## Log
- 2026-09-27 blocker bt-d173 closed 2026-09-27T18:57:09Z — recheck whether this can proceed now.
- 2026-09-27 claimed by capacity-engine
- 2026-09-27 done by capacity-engine/worker — test `test ! -e /home/omri/projects/bass-tuner/api.ts && node /home/omri/projects/donefile/dist/cli.js show ma-7c75 | grep -q "status: open"` exit 0 (log: evidence/bt-0859-2026-09-27T19-43-48Z-test.txt) (evidence waived: no deploy applies: not this repo's code, nothing changed here — finding is a routing duplicate of ma-7c75 on meniapp's board)
