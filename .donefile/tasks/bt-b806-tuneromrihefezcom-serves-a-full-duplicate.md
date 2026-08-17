---
id: bt-b806
title: tuner.omrihefez.com serves a full duplicate of bass.omrihefez.com instead of a 308 redirect,
  violating DOMAIN.md §2 rule 3 (vanity alias must redirect to canonical)
status: done
priority: p3
tags:
  - vercel
  - docs
created: 2026-07-25
done:
  at: 2026-07-26T19:02:46Z
  by: capacity-engine/worker
evidence:
  - type: commit
    value: 99045d7
    verified: 2026-07-26T19:02:46Z
  - type: test
    cmd: code=$(curl -s -o /dev/null -w "%{http_code}" https://tuner.omrihefez.com/); [ "$code" = "308"
      ]
    exit: 0
    at: 2026-07-26T19:02:46Z
    log: evidence/bt-b806-2026-07-26T19-02-46Z-test.txt
    sha256: ca40092723f1c7f425a9e234e70bd4e6af6a68a0a8c25dee9e4403e43abaa097
    bytes: 100
---

## Log
- 2026-07-26 claimed by capacity-engine
- 2026-07-26 done by capacity-engine/worker — commit 99045d7, test `code=$(curl -s -o /dev/null -w "%{http_code}" https://tuner.omrihefez.com/); [ "$code" = "308" ]` exit 0 (log: evidence/bt-b806-2026-07-26T19-02-46Z-test.txt)
