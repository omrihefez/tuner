---
id: bt-7654
title: install-cert-renewal-cron.sh's cleanup has the same substring-match defect (bt-b38f fixed
  elsewhere) for its cert-renewal pattern — same grep -vFxf fix would close it
status: done
priority: p3
tags:
  - ops
  - safety
created: 2026-08-14
done:
  at: 2026-08-25T11:24:34Z
  by: capacity-engine/worker
  waived: bt-7654 is a duplicate finding of bt-9777 (auto-filed from a worker FOLLOW-UP that predates
    bt-9777's fix landing); bt-9777 already applied the identical grep -vFxf fix to this same
    line/pattern on 2026-08-14, verified live in the checkout and covered by test-monitoring.sh step
    6f
evidence:
  - type: commit
    value: 74f882f
    verified: 2026-08-25T11:24:34Z
  - type: test
    cmd: bash scripts/test-monitoring.sh
    exit: 0
    at: 2026-08-25T11:24:29Z
    log: evidence/bt-7654-2026-08-25T11-24-29Z-test.txt
    sha256: da003ce38b2598af8f95133fa6cc5378f4c42c2b9b23ef5eb488acee5f09f0fb
    bytes: 3078
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

## Log
- 2026-08-18 title: 'install-cert-renewal-cron.sh's own cleanup (bt-b38f's fix) has the identical residual substring-match defect for its "run-monitor.sh cert-renewal " pattern — same grep -vFxf fix would close it too' -> 'install-cert-renewal-cron.sh's cleanup has the same substring-match defect (bt-b38f fixed elsewhere) for its cert-renewal pattern — same grep -vFxf fix would close it'
- 2026-08-25 claimed by capacity-engine
- 2026-08-25 done by capacity-engine/worker — commit 74f882f, test `bash scripts/test-monitoring.sh` exit 0 (log: evidence/bt-7654-2026-08-25T11-24-29Z-test.txt) (evidence waived: bt-7654 is a duplicate finding of bt-9777 (auto-filed from a worker FOLLOW-UP that predates bt-9777's fix landing); bt-9777 already applied the identical grep -vFxf fix to this same line/pattern on 2026-08-14, verified live in the checkout and covered by test-monitoring.sh step 6f)
