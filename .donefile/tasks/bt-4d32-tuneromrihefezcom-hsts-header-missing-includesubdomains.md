---
id: bt-4d32
title: tuner.omrihefez.com HSTS header missing includeSubDomains (not covered by cp-8845)
status: done
priority: p3
tags:
  - from-brief
created: 2026-10-04
filed:
  owner: morning-brief
  at: 2026-10-04T06:07:02Z
done:
  at: 2026-10-04T06:45:49Z
  by: capacity-engine/worker
evidence:
  - type: commit
    value: 594d5527687b79683b6fb0fe8674b6fa8b5f1ee8
    verified: 2026-10-04T06:45:49Z
  - type: test
    cmd: cd /home/omri/projects/bass-tuner && npm test
    exit: 0
    at: 2026-10-04T06:45:14Z
    log: evidence/bt-4d32-2026-10-04T06-45-14Z-test.txt
    sha256: 4a4cc2fe4b5df87c4cd665d55713135e61f019de9d61835fe616ee95bf131723
    bytes: 44617
  - type: live
    cmd: "curl -sI https://tuner.omrihefez.com/ | grep -i '^strict-transport-security: max-age=31536000;
      includeSubDomains'"
    exit: 0
    at: 2026-10-04T06:45:14Z
    log: evidence/bt-4d32-2026-10-04T06-45-14Z-live.txt
    sha256: 63f081f48441168e4b23da5bccf184cc645dc9f92e7457ac01ea345de5931e61
    bytes: 181
---

The 2026-10-04 bass-tuner domain audit (~/inbox/bass-tuner-domain-audit-2026-10-04.md) flags tuner.omrihefez.com's Strict-Transport-Security header as missing the includeSubDomains directive. A sibling finding on compose.omrihefez.com is already tracked as cp-8845 (open, p3) — but that task's title claims compose is 'the only one in the estate' with this gap, which is now false since tuner has it too. Add includeSubDomains to tuner's HSTS header (wherever the other domains in the estate set it — check how compose/other sibling apps configure STS for the pattern to match). Done when audit-domains.sh shows no DRIFT line for tuner's STS header, and cp-8845's title/body no longer implies compose is unique (update or close out that claim if cp-8845 covers both now).

Filed by the morning brief's intake pass.

## Log
- 2026-10-04 claimed by capacity-engine
- 2026-10-04 done by capacity-engine/worker — commit 594d5527687b, test `cd /home/omri/projects/bass-tuner && npm test` exit 0 (log: evidence/bt-4d32-2026-10-04T06-45-14Z-test.txt), live `curl -sI https://tuner.omrihefez.com/ | grep -i '^strict-transport-security: max-age=31536000; includeSubDomains'` exit 0 (log: evidence/bt-4d32-2026-10-04T06-45-14Z-live.txt)
