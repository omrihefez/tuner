---
id: bt-7654
title: install-cert-renewal-cron.sh's own cleanup (bt-b38f's fix) has the identical residual
  substring-match defect for its "run-monitor.sh cert-renewal " pattern — same grep -vFxf fix would
  close it too
status: open
priority: p3
tags:
  - ops
  - safety
created: 2026-08-14
---

Named in the finding: install-cert-renewal-cron.sh, run-monitor.sh

LIKELY ALREADY DONE — verify before building. Work merged after this finding was raised may already cover it:
- `7c21a04d` 2026-08-14 "bt-d428: scope install-monitoring-crons.sh's cleanup to its own lines" — scripts/install-monitoring-crons.sh, scripts/test-monitoring.sh (names bt-b38f; 73% of the finding's words)

START HERE: check whether that work satisfies this finding. If it does, close with `--commit <sha>` and say so — that is a complete, correct closure, not a shortcut. If it does not, say in one line what it missed and do the work.
This is a word/file-path heuristic run at filing time, NOT a proof — it exists so the claimer starts from "verify" instead of spending a whole round rediscovering that it shipped (ce-a792).

<!-- capacity-engine: provenance, not part of the finding -->
Auto-filed by the capacity engine from a worker's FOLLOW-UP line — the title is that worker's own verbatim wording, so scope it before claiming.

Discovered while working bt-d428, session `install-monitoring-crons-cee871`, dispatched on bass-tuner.
That task's report closed DONE (commit 7c21a04d285bedc230a93019c7b193ab6edceb56).

DONE WHEN: the finding above is either fixed and verified, or shown not to be real — say which in the closing evidence.
