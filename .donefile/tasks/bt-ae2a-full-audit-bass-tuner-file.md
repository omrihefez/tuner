---
id: bt-ae2a
title: "Full audit: bass-tuner — file each finding as its own task (security, correctness, tests,
  UX, perf, deploy, deps)"
status: done
priority: p0
tags:
  - audit
created: 2026-07-13
done:
  at: 2026-07-14T01:40:53Z
  by: capacity-engine/worker
evidence:
  - type: test
    cmd: test $(ls .donefile/tasks/ | grep -Ec 'b898|a66f|b0f3|8e75|243a|3a17|cbe8|7bc5|1628|8db5') -eq
      10
    exit: 0
    at: 2026-07-14T01:40:53Z
    log: evidence/bt-ae2a-2026-07-14T01-40-53Z-test.txt
    sha256: 0527a553f209315d90bfb4586ee7f8001c2efdc30949995204ff97ec3b589eb0
    bytes: 101
---

FULL AUDIT — all aspects. Read the codebase end-to-end. File EACH finding as its OWN separate task on THIS board (cd into this repo, then: node /home/omri/projects/donefile/dist/cli.js add "<short finding>" -p <p0|p1|p2|p3> -t <area> --body "<file:line + why wrong + fix direction>"). COVER: security (authz/authn, secret handling, injection/SSRF, input validation), correctness/logic bugs, silent failures & error handling, test-coverage gaps, UX/UI if user-facing (screenshot 390px, real data), performance, deploy/CI health, dependency & secret hygiene, dead/duplicated code. PRIORITY: P0=live breakage/security hole; P1=real bug or missing critical test; P2/P3=hardening/polish. Be specific + verifiable, no vague "consider improving". Do NOT fix in this task; audit + board ONLY. Read-only, NO deploys/app-commits (board writes fine). Report count of findings filed; closes on that summary.

## Log
- 2026-07-14 claimed by capacity-engine
- 2026-07-14 done by capacity-engine/worker — test `test $(ls .donefile/tasks/ | grep -Ec 'b898|a66f|b0f3|8e75|243a|3a17|cbe8|7bc5|1628|8db5') -eq 10` exit 0 (log: evidence/bt-ae2a-2026-07-14T01-40-53Z-test.txt)
