---
id: bt-67b8
title: "test-monitoring.sh FAILs on unmodified main: renew-wildcard-cert.sh missing from crontab"
status: done
priority: p3
tags:
  - bass-tuner
  - cron
created: 2026-10-20
filed:
  owner: capacity-engine
  at: 2026-10-20T13:57:15Z
reported: 2026-10-20
done:
  at: 2026-10-20T14:15:15Z
  by: capacity-engine/worker
evidence:
  - type: commit
    value: 646eac57e60b6c3139cbebee4a4daee8eb6fb3e4
    verified: 2026-10-20T14:15:15Z
  - type: test
    cmd: cd /home/omri/projects/bass-tuner && bash scripts/test-monitoring.sh >/dev/null
    exit: 0
    at: 2026-10-20T14:15:08Z
    log: evidence/bt-67b8-2026-10-20T14-15-08Z-test.txt
    sha256: 2b2ef4d6055d3fe011b50e467b7bfbba1eaf7336317bf56ae56eba8ca9e75625
    bytes: 83
  - type: note
    value: "Premise live: 151KB crontab made 'echo $CRON | grep -q' SIGPIPE under pipefail (bt-87c5
      class) so step 5 falsely reported renew-wildcard-cert.sh missing though present. Fixed with
      here-string grep; failed before, 3/3 green after."
---

Named in the finding: test-monitoring.sh, renew-wildcard-cert.sh

Why this is worth doing (from the reporting worker's own FOLLOW-UP line): same FAIL reproduces at origin/main, so it predates bt-8677

<!-- capacity-engine: provenance, not part of the finding -->
UNVERIFIED CLAIM — auto-filed by the capacity engine from a worker's FOLLOW-UP line. The title above is that worker's own belief at the end of a session, written once, never checked by anything else: a well-formed, confident sentence can still be flatly wrong. Verify it against this repo's CURRENT state before doing anything else, then scope it before claiming (ce-916b).

Discovered while working bt-8677, session `cron-phase-move-this-rep-a47110`, dispatched on bass-tuner.
See 'reported' in this task's frontmatter for the date this finding was originally observed — read any relative time in the title above ("this morning", "currently", "still", "right now") as dated from THAT day, not from when this task was filed.
Board choice is a GUESS: this follow-up names a file but the engine could not match it to exactly one board's repo, so it stayed on the dispatching board rather than being routed. Verify it belongs here before working it — it may need re-filing on the board that actually owns the named file (ce-3b8d).
That task's report closed DONE (commit adfbd2379b46c375cededff35b3047069291a2bf).

DONE WHEN: the finding above is either fixed and verified, or shown not to be real — say which in the closing evidence.

## Log
- 2026-10-20 claimed by capacity-engine
- 2026-10-20 done by capacity-engine/worker — commit 646eac57e60b, test `cd /home/omri/projects/bass-tuner && bash scripts/test-monitoring.sh >/dev/null` exit 0 (log: evidence/bt-67b8-2026-10-20T14-15-08Z-test.txt)
