---
id: bt-d428
title: install-monitoring-crons.sh's equivalent cleanup pass (grep -vF "run-monitor.sh <name> ")
  also matches outside its own managed block, just with a narrower pattern than the basename bug
  this task fixed — not a live bug today but same defect shape if anyone ever hand-adds a line
  matching that exact string.
status: claimed
priority: p3
tags:
  - ops
  - safety
created: 2026-08-02
claim:
  owner: capacity-engine
  at: 2026-08-14T05:21:26Z
---

<!-- capacity-engine: provenance, not part of the finding -->
Auto-filed by the capacity engine from a worker's FOLLOW-UP line — the title is that worker's own verbatim wording, so scope it before claiming.

Discovered while working bt-b38f, session `install-cert-renewal-cro-dccfa3`, dispatched on bass-tuner.

DONE WHEN: the finding above is either fixed and verified, or shown not to be real — say which in the closing evidence.

## Log
- 2026-08-14 claimed by capacity-engine
