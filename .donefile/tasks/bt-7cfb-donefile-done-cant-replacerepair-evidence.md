---
id: bt-7cfb
title: donefile `done` can't replace/repair evidence on an already-closed task when a --test command
  fails for reasons unrelated to the underlying claim (e.g. shell quoting) — worth an `evidence
  add`/`done --amend` escape hatch
status: done
priority: p3
tags:
  - tooling
  - donefile
created: 2026-07-25
done:
  at: 2026-07-31T00:43:17Z
  by: capacity-engine/worker
evidence:
  - type: commit
    value: 3ebcd1ceda2fabfeab35b4dc16d9dc17813851f3
    repo: /home/omri/projects/donefile
    verified: 2026-07-31T00:43:17Z
  - type: test
    cmd: npx vitest --run -t "done --amend \(bt-7cfb\)" test/collect-evidence.test.ts
    exit: 0
    at: 2026-07-31T00:43:14Z
    log: evidence/bt-7cfb-2026-07-31T00-43-14Z-test.txt
    sha256: ab99a138ba29b8df00855d03793dd12766f8302e85947673bba8f8e8ffa57a10
    bytes: 388
---

## Log
- 2026-07-26 claimed by capacity-engine
- 2026-07-26 claim by capacity-engine parked (blocked)
- 2026-07-26 blocked: DONE on branch bt-7cfb-done-amend 3ebcd1ceda2fabfeab35b4dc16d9dc17813851f3 (donefile repo), pushed but donefile main is heavily contended (2 concurrent non-fast-forward pushes while landing) — awaiting Main merge to origin/main before closing done
- 2026-07-31 unblocked
- 2026-07-31 done by capacity-engine/worker — commit 3ebcd1ceda2f (/home/omri/projects/donefile), test `npx vitest --run -t "done --amend \(bt-7cfb\)" test/collect-evidence.test.ts` exit 0 (log: evidence/bt-7cfb-2026-07-31T00-43-14Z-test.txt)
