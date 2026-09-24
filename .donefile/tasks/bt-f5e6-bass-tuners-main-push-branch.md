---
id: bt-f5e6
title: bass-tuner's main-push branch-guard isn't listed in the fleet CLAUDE.md's 4-repo table
  (trips-hub, capacity-engine, donefile, kidai)
status: done
priority: p3
tags:
  - monitoring
  - docs
created: 2026-09-24
filed:
  owner: capacity-engine
  at: 2026-09-24T17:26:28Z
reported: 2026-09-24
done:
  at: 2026-09-24T17:46:20Z
  by: capacity-engine/worker
evidence:
  - type: test
    cmd: N=$(find /home/omri/inbox/meni-board-queue -maxdepth 1 -name
      'bt-f5e6-add-bass-tuner-to-guard-table.md' -printf x | wc -c); [ "$N" = "1" ] && grep -q 'PER
      CLONE ONLY' /home/omri/inbox/meni-board-queue/bt-f5e6-add-bass-tuner-to-guard-table.md && grep
      -q 'bass-tuner' /home/omri/inbox/meni-board-queue/bt-f5e6-add-bass-tuner-to-guard-table.md
    exit: 0
    at: 2026-09-24T17:46:19Z
    log: evidence/bt-f5e6-2026-09-24T17-46-19Z-test.txt
    sha256: 643ced063ab276951529c740588cb24dbe907355be3b0edbb6e2701be3ddf4ac
    bytes: 344
  - type: note
    value: "Finding is real, verified fresh 2026-09-24: bass-tuner's .git/hooks/pre-push (core.hooksPath
      unset) has the same default_branch()/is_allowed_default_branch() guard as
      trips-hub/capacity-engine/donefile/kidai, belongs in the donefile/kidai 'PER CLONE ONLY' row,
      and is absent from child-CLAUDE.md's guard table (lines 608-615, 625). Cannot commit to ~/meni
      myself; queued the exact 3-block replacement for Main at
      ~/inbox/meni-board-queue/bt-f5e6-add-bass-tuner-to-guard-table.md per the ma-e203 convention."
---

Named in the finding: claude.md

Why this is worth doing (from the reporting worker's own FOLLOW-UP line): hit it live pushing bt-a7a3, cost one failed push+retry; the doc undercounts guarded repos

<!-- capacity-engine: provenance, not part of the finding -->
UNVERIFIED CLAIM — auto-filed by the capacity engine from a worker's FOLLOW-UP line. The title above is that worker's own belief at the end of a session, written once, never checked by anything else: a well-formed, confident sentence can still be flatly wrong. Verify it against this repo's CURRENT state before doing anything else, then scope it before claiming (ce-916b).

Discovered while working bt-a7a3, session `lib-domain-registry-sh-i-db0267`, dispatched on bass-tuner.
See 'reported' in this task's frontmatter for the date this finding was originally observed — read any relative time in the title above ("this morning", "currently", "still", "right now") as dated from THAT day, not from when this task was filed.
Named file 'claude.md' actually lives in /home/omri/meni — a real repo, but deliberately excluded from boards[] and never auto-dispatched (config.json's _meni_board_excluded_note), so it cannot be routed there. Filed on bass-tuner instead for lack of anywhere else to put it; if this needs action, it has to be picked up by hand or queued via ~/inbox/meni-board-queue/ (ma-e203).
That task's report closed DONE (commit da9d5270845e44b2482a068d0bde6ae167839907).

DONE WHEN: the finding above is either fixed and verified, or shown not to be real — say which in the closing evidence.

## Log
- 2026-09-24 claimed by capacity-engine
- 2026-09-24 done by capacity-engine/worker — test `N=$(find /home/omri/inbox/meni-board-queue -maxdepth 1 -name 'bt-f5e6-add-bass-tuner-to-guard-table.md' -printf x | wc -c); [ "$N" = "1" ] && grep -q 'PER CLONE ONLY' /home/omri/inbox/meni-board-queue/bt-f5e6-add-bass-tuner-to-guard-table.md && grep -q 'bass-tuner' /home/omri/inbox/meni-board-queue/bt-f5e6-add-bass-tuner-to-guard-table.md` exit 0 (log: evidence/bt-f5e6-2026-09-24T17-46-19Z-test.txt)
