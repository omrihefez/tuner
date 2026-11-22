---
id: bt-286d
title: Repoint cp headers in other repos' *.vendored.sh (bass-tuner, etc.) to a header-preserving resync
status: done
priority: p3
tags:
  - vendored-pin
  - cross-board
created: 2026-11-22
filed:
  owner: capacity-engine
  at: 2026-11-21T23:29:46Z
reported: 2026-11-22
done:
  at: 2026-11-22T00:22:54Z
  by: capacity-engine
evidence:
  - type: commit
    value: bfee242
    verified: 2026-11-22T00:22:54Z
  - type: test
    cmd: 'cd /home/omri/projects/bass-tuner && F="scripts/lib/alert-latch.vendored.sh
      scripts/lib/crontab-install-lock.vendored.sh scripts/lib/stale-checkout-guard.vendored.sh
      scripts/lint-crontab-logdirs.vendored.sh"; N=$(grep -hE "^#[[:space:]]+cp |re-sync with: .cp "
      $F | wc -c); [ "$N" = "0" ] && for f in $F; do grep -q "resync-vendored.sh" $f || exit 1; done
      && /home/omri/projects/meniapp/scripts/resync-vendored.sh
      scripts/lint-crontab-logdirs.vendored.sh >/dev/null && git diff --quiet -- $F'
    exit: 0
    at: 2026-11-22T00:22:53Z
    log: evidence/bt-286d-2026-11-22T00-22-53Z-test.txt
    sha256: f1bf9525df7b80cf93d33c8acd09c3b5bd700f29c9f1f6216dfea77917e969b4
    bytes: 495
  - type: note
    value: "premise live: 4 pins said bare cp; repointed to meniapp resync-vendored.sh (resync no-op on
      all 4)"
---

Named in the finding: vendored.sh

Why this is worth doing (from the reporting worker's own FOLLOW-UP line): only meniapp's 3 pins were fixed; the others still say bare cp

<!-- capacity-engine: provenance, not part of the finding -->
UNVERIFIED CLAIM — auto-filed by the capacity engine from a worker's FOLLOW-UP line. The title above is that worker's own belief at the end of a session, written once, never checked by anything else: a well-formed, confident sentence can still be flatly wrong. Verify it against this repo's CURRENT state before doing anything else, then scope it before claiming (ce-916b).

Discovered while working ma-b3c9, session `fix-vendored-file-header-6e9354`, dispatched on meniapp.
See 'reported' in this task's frontmatter for the date this finding was originally observed — read any relative time in the title above ("this morning", "currently", "still", "right now") as dated from THAT day, not from when this task was filed.
This finding named multiple repos explicitly and was filed separately on each: also on iac, tik-api, trips-hub, house-control (ce-71de). Scope this task to the part that is actually about meniapp; the siblings cover the rest.
That task's report closed DONE (commit 88df90903 — does not resolve here, see below).

PROVENANCE COMMIT DOES NOT RESOLVE HERE — `88df90903` does not exist in this repo. It is the evidence commit from the task/board that raised this line, not this one — don't spend time trying to `git show` it here. Treat the finding above as UNVERIFIED and check whether it is still true against this repo's CURRENT state before doing anything else (ce-5112).

DONE WHEN: the finding above is either fixed and verified, or shown not to be real — say which in the closing evidence.

## Log
- 2026-11-22 claimed by capacity-engine
- 2026-11-22 done by capacity-engine — commit bfee242, test `cd /home/omri/projects/bass-tuner && F="scripts/lib/alert-latch.vendored.sh scripts/lib/crontab-install-lock.vendored.sh scripts/lib/stale-checkout-guard.vendored.sh scripts/lint-crontab-logdirs.vendored.sh"; N=$(grep -hE "^#[[:space:]]+cp |re-sync with: .cp " $F | wc -c); [ "$N" = "0" ] && for f in $F; do grep -q "resync-vendored.sh" $f || exit 1; done && /home/omri/projects/meniapp/scripts/resync-vendored.sh scripts/lint-crontab-logdirs.vendored.sh >/dev/null && git diff --quiet -- $F` exit 0 (log: evidence/bt-286d-2026-11-22T00-22-53Z-test.txt)
