---
id: bt-57fc
title: check-model-ids-resolve.sh's EXTRA_ROOTS misses /home/omri/compose and ~/study/sn2526a, both
  of which have their own board - the hand-maintained-root drift bt-8ce4 fixed once
status: done
priority: p3
tags:
  - tooling
  - coverage
  - cross-board
created: 2026-10-05
filed:
  owner: meni-worker/board-refill-work-discov-5e7b4f
  at: 2026-10-04T22:36:20Z
done:
  at: 2026-10-04T23:13:58Z
  by: capacity-engine/worker
evidence:
  - type: commit
    value: dfaeab77f3eefaf1f7bd73138e536409a8b522c0
    verified: 2026-10-04T23:13:58Z
  - type: test
    cmd: cd /home/omri/projects/bass-tuner && bash scripts/check-model-ids-resolve.test.sh
    exit: 0
    at: 2026-10-04T23:13:56Z
    log: evidence/bt-57fc-2026-10-04T23-13-56Z-test.txt
    sha256: 6f58479432962bdb97ecd2332906921b6bcda12a2e9cdc4aae0f6a7b02b77111
    bytes: 2342
---

`scripts/check-model-ids-resolve.sh` builds its scan roots as one glob plus a
hand-written tail (verified by `grep -n` on the script, 2026-10-05):

    line 111  PROJECTS_GLOB_ROOT="${MODEL_PROJECTS_ROOT:-/home/omri/projects}"
    line 115  EXTRA_ROOTS=(/home/omri/meni /home/omri/tik-api /home/omri/apartment)

Two real repos with their own `.git` AND their own donefile board are reached by
neither:

  - `/home/omri/compose` — board prefix `cp` (3 tasks: cp-5338, cp-8845, cp-7fcd,
    all done), and compose.omrihefez.com is LIVE and PUBLIC (HTTP 200 verified
    2026-10-05 01:26 IDT, ~/meni/DOMAIN.md §1 row 30).
  - `/home/omri/study/sn2526a` — board prefix `sn`, reached through the `~/study`
    symlink onto /mnt, so the `/home/omri/projects` glob cannot see it either.

Both are deliberately out of capacity-engine's `boards[]` (recorded in
docs/config-notes/_excluded_boards_note.md and `sunset_repos`), but exclusion from
DISPATCH is not exclusion from a fleet SCAN — `~/meni`, `~/tik-api` and
`~/apartment` are in EXTRA_ROOTS for exactly that reason, and all three are
likewise unregistered.

LATENT TODAY, STATED PLAINLY SO NOBODY OVER-PRICES IT. Neither repo currently
contains a hardcoded Gemini model string, so this is a coverage gap rather than a
live miss. Verified:

    grep -rln --include=*.py --include=*.ts --include=*.tsx --include=*.mjs --include=*.js \
      --include=*.sh --include=*.json --exclude-dir=node_modules --exclude-dir=.git \
      --exclude-dir=.donefile -e 'gemini-2\.5' -e 'gemini-1\.5' \
      /home/omri/projects /home/omri/meni /home/omri/tik-api /home/omri/compose /home/omri/apartment

returns no hit under `/home/omri/compose`. It is filed anyway because this is the
third time a hand-maintained root list on this box has had to be widened by hand —
ce-1ff6 (one root to two), ce-bea1 (a third real board one level outside), and
bt-8ce4, which is THIS script's own EXTRA_ROOTS being added for the same reason.
The pattern is that the list is always correct until the next repo appears beside it.

WHY NOW RATHER THAN LATER: Google's cutoff for Gemini 2.5 traffic is 2026-10-20,
15 days from filing. A scanner that is the fleet's answer to "did we catch every
hardcoded model id" should not have a blind spot during the window it exists for.

DONE WHEN: the script's root set covers every repo that has a `.donefile` board,
derived rather than typed — the same census the discovery brief runs is the obvious
source:

    find -L /home/omri \( -path '*/node_modules' -o -path '*/.local/share/meni-hub' \
      -o -path '/home/omri/.cache' -o -path '/home/omri/.bun' -o -path '/home/omri/.npm' \
      -o -path '/home/omri/.meni-children' \) -prune -o -name .donefile -print

with git-worktree hits resolved away (a worktree's first `git worktree list` line
points back at the main checkout). If a derived list is judged too much machinery
for this script, adding the two paths to EXTRA_ROOTS is an acceptable smaller fix —
but then say in the evidence that the list is still hand-maintained, so the next
reader knows it will drift again.

EVIDENCE MUST BE ABLE TO FAIL: `scripts/check-model-ids-resolve.test.sh` should gain
a case that plants a Gemini model string in a fixture repo OUTSIDE
`/home/omri/projects` and asserts the scanner finds it. Run it against the parent
commit and show it red.

SIBLING, SAME CLASS, DIFFERENT REPO: meniapp's
`scripts/check-exit-trap-only-cleanup.sh` has the identical defect in its own
hardcoded tail (`ROOTS+=("$HOME/apartment" "$HOME/projects/tik-board" "$HOME/tik-api"
"$HOME/study/sn2526a")`, missing /home/omri/compose and
/home/omri/projects/weekly-deepdive). Filed separately on meniapp's board; whoever
picks up either should look at the other, because the right fix is probably the same
derivation in both.


cross-board: names a file under 'meni' at /home/omri/meni — ~/meni is undispatched — route it via ~/inbox/meni-board-queue/ instead (see dn-334c).

## Log
- 2026-10-05 claimed by capacity-engine
- 2026-10-05 done by capacity-engine/worker — commit dfaeab77f3ee, test `cd /home/omri/projects/bass-tuner && bash scripts/check-model-ids-resolve.test.sh` exit 0 (log: evidence/bt-57fc-2026-10-04T23-13-56Z-test.txt)
