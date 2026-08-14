---
id: bt-e5ea
title: test-monitoring.sh step 5 (live crontab scan) is intermittently flaky on the shared box,
  unrelated to any installer logic
status: done
priority: p3
tags:
  - ops
  - tests
created: 2026-08-02
done:
  at: 2026-08-14T05:43:54Z
  by: capacity-engine/worker
  waived: "bt-e5ea is a duplicate finding of bt-d30a (same box-shared-crontab race, same step 5):
    bt-d30a's fix (85b3ee1, poll up to 5x) already landed 2026-08-01 13:34, one day before bt-e5ea
    was even filed (2026-08-02). No new commit exists because there is no new work -- citing the
    actual resolving commit."
evidence:
  - type: commit
    value: 85b3ee1
    verified: 2026-08-14T05:43:54Z
  - type: test
    cmd: bash scripts/test-monitoring.sh
    exit: 0
    at: 2026-08-14T05:43:51Z
    log: evidence/bt-e5ea-2026-08-14T05-43-51Z-test.txt
    sha256: f28289fa0864ada7ab0c2ea156d392747b770b1e1dce9ca2e61d3e3296834b0e
    bytes: 2457
  - type: note
    value: Reproduced the underlying race live (2 of 3 fresh runs hit 'missing on first read, present
      after N retries' on check-fallback-cert.sh / check-monitor-heartbeats.sh) and confirmed
      bt-d30a's poll-5x retry absorbs it every time -- exit 0 across 3 consecutive full
      test-monitoring.sh runs just now.
---

<!-- capacity-engine: provenance, not part of the finding -->
Auto-filed by the capacity engine from a worker's FOLLOW-UP line — the title is that worker's own verbatim wording, so scope it before claiming.

Discovered while working bt-3f5a, session `install-cert-renewal-cro-bfc6a6`, dispatched on bass-tuner.

DONE WHEN: the finding above is either fixed and verified, or shown not to be real — say which in the closing evidence.

## Log
- 2026-08-14 claimed by capacity-engine
- 2026-08-14 done by capacity-engine/worker — commit 85b3ee1, test `bash scripts/test-monitoring.sh` exit 0 (log: evidence/bt-e5ea-2026-08-14T05-43-51Z-test.txt) (evidence waived: bt-e5ea is a duplicate finding of bt-d30a (same box-shared-crontab race, same step 5): bt-d30a's fix (85b3ee1, poll up to 5x) already landed 2026-08-01 13:34, one day before bt-e5ea was even filed (2026-08-02). No new commit exists because there is no new work -- citing the actual resolving commit.)
