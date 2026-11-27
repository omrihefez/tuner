---
id: bt-5ed9
title: Flip check-public-surfaces.sh kidai/pete/pete-api/brain rows and DOMAIN.md rows to NXDOMAIN
  after wildcard apply
status: done
priority: p3
tags:
  - dns
created: 2026-11-27
filed:
  owner: capacity-engine/backfill
  at: 2026-11-27T01:44:28Z
reported: 2026-11-26
done:
  at: 2026-11-27T01:51:42Z
  by: capacity-engine/worker
evidence:
  - type: test
    cmd: for h in kidai pete pete-api; do if getent hosts $h.omrihefez.com; then exit 1; fi; done;
      N=$(grep -cE "\"https://(kidai|pete|pete-api)\." /home/omri/meni/bin/check-public-surfaces.sh
      || true); [ "$N" = "0" ] && echo ok
    exit: 0
    at: 2026-11-27T01:51:42Z
    log: evidence/bt-5ed9-2026-11-27T01-51-42Z-test.txt
    sha256: 2240c5f725fb91eb6423d978fe4167a3b371885e49a8b66101ad7b6447b0c274
    bytes: 226
  - type: note
    value: "premise mostly already done: script rows removed + kidai DOMAIN row flipped by meni 670e671e
      (bt-6531). Names NXDOMAIN verified. Remaining: DOMAIN.md pete/pete-api rows still claim
      wildcard/404 - meni-side, queued in
      ~/inbox/meni-board-queue/bt-5ed9-domain-md-pete-rows-stale.md"
---

Named in the finding: check-public-surfaces.sh, kidai/pete/pete-api/brain, domain.md

Why this is worth doing (from the reporting worker's own FOLLOW-UP line): meni-side files, workers can't write ~/meni

<!-- capacity-engine: provenance, not part of the finding -->
UNVERIFIED CLAIM — auto-filed by the capacity engine from a worker's FOLLOW-UP line. The title above is that worker's own belief at the end of a session, written once, never checked by anything else: a well-formed, confident sentence can still be flatly wrong. Verify it against this repo's CURRENT state before doing anything else, then scope it before claiming (ce-916b).

Discovered while working bt-6531, session `delete-omrihefez-com-wil-8ef2ea`, dispatched on bass-tuner.
See 'reported' in this task's frontmatter for the date this finding was originally observed — read any relative time in the title above ("this morning", "currently", "still", "right now") as dated from THAT day, not from when this task was filed.

DONE WHEN: the finding above is either fixed and verified, or shown not to be real — say which in the closing evidence.

## Log
- 2026-11-27 claimed by capacity-engine
- 2026-11-27 done by capacity-engine/worker — test `for h in kidai pete pete-api; do if getent hosts $h.omrihefez.com; then exit 1; fi; done; N=$(grep -cE "\"https://(kidai|pete|pete-api)\." /home/omri/meni/bin/check-public-surfaces.sh || true); [ "$N" = "0" ] && echo ok` exit 0 (log: evidence/bt-5ed9-2026-11-27T01-51-42Z-test.txt)
