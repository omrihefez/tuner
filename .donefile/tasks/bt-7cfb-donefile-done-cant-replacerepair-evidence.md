---
id: bt-7cfb
title: donefile `done` can't replace/repair evidence on an already-closed task when a --test command
  fails for reasons unrelated to the underlying claim (e.g. shell quoting) — worth an `evidence
  add`/`done --amend` escape hatch
status: blocked
priority: p3
tags:
  - tooling
  - donefile
created: 2026-07-25
blocked:
  reason: DONE on branch bt-7cfb-done-amend 3ebcd1ceda2fabfeab35b4dc16d9dc17813851f3 (donefile repo),
    pushed but donefile main is heavily contended (2 concurrent non-fast-forward pushes while
    landing) — awaiting Main merge to origin/main before closing done
  since: 2026-07-26
---

## Log
- 2026-07-26 claimed by capacity-engine
- 2026-07-26 claim by capacity-engine parked (blocked)
- 2026-07-26 blocked: DONE on branch bt-7cfb-done-amend 3ebcd1ceda2fabfeab35b4dc16d9dc17813851f3 (donefile repo), pushed but donefile main is heavily contended (2 concurrent non-fast-forward pushes while landing) — awaiting Main merge to origin/main before closing done
