---
id: bt-ae2a
title: "Full audit: bass-tuner — file each finding as its own task (security, correctness, tests,
  UX, perf, deploy, deps)"
status: claimed
priority: p0
tags:
  - audit
created: 2026-07-13
claim:
  owner: capacity-engine
  at: 2026-07-14T01:35:56Z
---

FULL AUDIT — all aspects. Read the codebase end-to-end. File EACH finding as its OWN separate task on THIS board (cd into this repo, then: node /home/omri/projects/donefile/dist/cli.js add "<short finding>" -p <p0|p1|p2|p3> -t <area> --body "<file:line + why wrong + fix direction>"). COVER: security (authz/authn, secret handling, injection/SSRF, input validation), correctness/logic bugs, silent failures & error handling, test-coverage gaps, UX/UI if user-facing (screenshot 390px, real data), performance, deploy/CI health, dependency & secret hygiene, dead/duplicated code. PRIORITY: P0=live breakage/security hole; P1=real bug or missing critical test; P2/P3=hardening/polish. Be specific + verifiable, no vague "consider improving". Do NOT fix in this task; audit + board ONLY. Read-only, NO deploys/app-commits (board writes fine). Report count of findings filed; closes on that summary.

## Log
- 2026-07-14 claimed by capacity-engine
