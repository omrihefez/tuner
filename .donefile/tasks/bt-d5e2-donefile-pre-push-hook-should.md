---
id: bt-d5e2
title: donefile pre-push hook should scrub GIT_* before running the suite — fleet-wide defense in
  depth for the bt-f541 worktree-GIT_DIR escape
status: done
priority: p2
tags:
  - reliability
  - ci
  - safety
created: 2026-08-18
done:
  at: 2026-08-22T21:50:13Z
  by: capacity-engine/worker
evidence:
  - type: commit
    value: 8ff147a
    repo: donefile
    verified: 2026-08-22T21:50:13Z
  - type: test
    cmd: cd /home/omri/projects/donefile && npx vitest run test/pre-push-hook.test.ts
    exit: 0
    at: 2026-08-22T21:50:04Z
    log: evidence/bt-d5e2-2026-08-22T21-50-04Z-test.txt
    sha256: 6c92df15aa735b7bbb7d0b84b2fef8c65be39f823a273870a64ba95a19f2e822
    bytes: 378
  - type: note
    value: "Fixed in donefile itself (hooks/pre-push.sh is the shared pre-push template every registered
      board installs), not in bass-tuner's own code. dn-1305 already scrubbed GIT_* inside
      donefile's own vitest suite (test/setup.ts), but that protected only donefile's tests; every
      other board running this hook, and any test file that doesn't scrub for itself, was still
      exposed to bt-f541's mechanism. Added a GIT_* prefix-sweep to hooks/pre-push.sh right after
      the toplevel cd, before eval \"$CMD\" runs. New regression test (pre-push-hook.test.ts) pushes
      a real branch from a real linked worktree whose 'test' script dumps every ambient GIT_* var it
      sees; confirmed red before the fix (GIT_DIR, GIT_PREFIX, GIT_EXEC_PATH etc leaking through)
      and green after. Full donefile suite: 1434/1434 passing. Same finding was also filed on
      donefile's own board as dn-cb48 (duplicate of this) -- closed done there too, same commit
      8ff147a, to avoid re-dispatching the identical work."
---

LIKELY ALREADY DONE — verify before building. Work merged after this finding was raised may already cover it:
- `9a27a538` 2026-08-17 "test: stop check-sw-cache-bump fixtures escaping into an ambient GIT_DIR (bt-f541)" — package.json, test/check-sw-cache-bump.test.js (names bt-f541; 53% of the finding's words)

START HERE: check whether that work satisfies this finding. If it does, close with `--commit <sha>` and say so — that is a complete, correct closure, not a shortcut. If it does not, say in one line what it missed and do the work.
Priority lowered p1 -> p2 on that match alone; raise it back if the finding turns out to be real (ce-a792).
This is a word/file-path heuristic run at filing time, NOT a proof — it exists so the claimer starts from "verify" instead of spending a whole round rediscovering that it shipped (ce-a792).

<!-- capacity-engine: provenance, not part of the finding -->
UNVERIFIED CLAIM — auto-filed by the capacity engine from a worker's FOLLOW-UP line. The title above is that worker's own belief at the end of a session, written once, never checked by anything else: a well-formed, confident sentence can still be flatly wrong. Verify it against this repo's CURRENT state before doing anything else, then scope it before claiming (ce-916b).

Discovered while working bt-f541, session `check-sw-cache-bump-test-4a73ae`, dispatched on bass-tuner.
Reported 2026-08-17 — read any relative time in the title above ("this morning", "currently", "still", "right now") as dated from THAT day, not from when this task was filed.
That task's report closed DONE (commit 9a27a53).

DONE WHEN: the finding above is either fixed and verified, or shown not to be real — say which in the closing evidence.

## Log
- 2026-08-23 claimed by capacity-engine
- 2026-08-23 done by capacity-engine/worker — commit 8ff147a (donefile), test `cd /home/omri/projects/donefile && npx vitest run test/pre-push-hook.test.ts` exit 0 (log: evidence/bt-d5e2-2026-08-22T21-50-04Z-test.txt)
