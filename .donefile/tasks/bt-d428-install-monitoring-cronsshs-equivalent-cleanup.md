---
id: bt-d428
title: install-monitoring-crons.sh's equivalent cleanup pass (grep -vF "run-monitor.sh <name> ")
  also matches outside its own managed block, just with a narrower pattern than the basename bug
  this task fixed — not a live bug today but same defect shape if anyone ever hand-adds a line
  matching that exact string.
status: done
priority: p3
tags:
  - ops
  - safety
created: 2026-08-02
done:
  at: 2026-08-14T05:26:20Z
  by: capacity-engine/worker
evidence:
  - type: commit
    value: 7c21a04d285bedc230a93019c7b193ab6edceb56
    verified: 2026-08-14T05:26:20Z
  - type: test
    cmd: bash scripts/test-monitoring.sh
    exit: 0
    at: 2026-08-14T05:26:17Z
    log: evidence/bt-d428-2026-08-14T05-26-17Z-test.txt
    sha256: 3e43e6e7a59c831031d981d192f3fde5ae9946991296076e32fde296e1e18d3b
    bytes: 2347
---

<!-- capacity-engine: provenance, not part of the finding -->
Auto-filed by the capacity engine from a worker's FOLLOW-UP line — the title is that worker's own verbatim wording, so scope it before claiming.

Discovered while working bt-b38f, session `install-cert-renewal-cro-dccfa3`, dispatched on bass-tuner.

DONE WHEN: the finding above is either fixed and verified, or shown not to be real — say which in the closing evidence.

## Log
- 2026-08-14 claimed by capacity-engine
- 2026-08-14 done by capacity-engine/worker — commit 7c21a04d285b, test `bash scripts/test-monitoring.sh` exit 0 (log: evidence/bt-d428-2026-08-14T05-26-17Z-test.txt)
