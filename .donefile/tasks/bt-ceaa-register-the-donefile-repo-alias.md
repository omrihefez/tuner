---
id: bt-ceaa
title: Register the 'donefile' repo alias in .donefile/config.yml — bt-d5e2's commit evidence
  resolves to a nonexistent path, so a closed task's evidence can never be verified
status: open
priority: p3
tags:
  - bookkeeping
  - donefile
created: 2026-08-24
---

Discovery sweep 2026-08-24 04:27 IDT. `donefile audit --actionable` on this board returns exactly one
finding, and it is a one-line config fix:

    UNRESOLVED_REPO [REPO_ABSENT] bt-d5e2  done but its commit evidence points at
    /home/omri/projects/bass-tuner/donefile (repo 'donefile'), which is missing —
    the evidence cannot be verified; register the alias in .donefile/config.yml repos:
    or fix the path

CAUSE. `bt-d5e2` closed with commit evidence attributed to repo `donefile`. This board's
`.donefile/config.yml` declares only two aliases:

    repos:
      capacity-engine: /home/omri/projects/capacity-engine
      meni: /home/omri/meni

With no `donefile` entry, the name falls back to a path relative to the board root, i.e.
`/home/omri/projects/bass-tuner/donefile`, which does not exist. So a closed task's evidence is
permanently unverifiable — the audit cannot replay it, and a later reader has no way to reach the
commit it names.

THE FIX HAS PRECEDENT, twice, in this fleet's own history — this is not a novel call:
- trips-hub `th-46d5`, commit `275d818` "donefile: register 'donefile' repo alias for cross-repo
  evidence"
- this board's own `bt-8e12` (2026-08-15) added the `meni` alias for exactly this class of problem,
  and the comment above it in `config.yml` spells out the reasoning.

DONE WHEN

1. `.donefile/config.yml` gains `donefile: /home/omri/projects/donefile` under `repos:`, alongside
   the existing two, with a short comment in the same style as the `meni` entry above it.
2. `bt-d5e2`'s evidence resolves. Verify the commit sha it names is actually reachable in
   `/home/omri/projects/donefile` before declaring this fixed — if it is NOT, the alias is the wrong
   fix and the evidence path itself is wrong; say which and correct that instead.
3. While you are in there: check whether any OTHER closed task on this board cites a repo name not
   in `repos:`. One missing alias usually means the convention was never applied, not that exactly
   one task got unlucky. Add what is genuinely needed, nothing speculative.

VERIFY (runnable from the main checkout, not a worktree — must outlive the session):

    cd /home/omri/projects/bass-tuner && donefile audit --actionable

Today this exits non-zero with the UNRESOLVED_REPO line above. After the fix it must no longer
report UNRESOLVED_REPO for `bt-d5e2`. That is a check which genuinely fails before the change and
passes after — run it against the parent commit and say in the note that you watched it fail.

NOTE the exit-code trap: this board's audit currently exits 1 on this one finding. If other
findings appear between now and the fix, a bare exit-code assertion would be satisfied by the wrong
thing — assert on the absence of `UNRESOLVED_REPO` specifically, keeping stderr (`2>&1`), not on
`audit` exiting 0.
