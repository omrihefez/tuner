---
id: bt-a740
title: Audit other omrihefez.com subdomains for the same drift (DNS pointed at Vercel but domain
  never added to a project)
status: done
priority: p3
tags:
  - ops
  - vercel
created: 2026-07-22
done:
  at: 2026-07-24T00:48:43Z
  by: capacity-engine/worker
evidence:
  - type: commit
    value: "4077934"
    verified: 2026-07-24T00:48:43Z
  - type: test
    cmd: bash scripts/audit-domains.sh
    exit: 0
    at: 2026-07-24T00:48:41Z
    log: evidence/bt-a740-2026-07-24T00-48-41Z-test.txt
    sha256: a308ed91f482e4ce82f043b6ebdcba4bf3136fc612757b7a077fca71ae9f5ab6
    bytes: 472
---

## Log
- 2026-07-24 claimed by capacity-engine
- 2026-07-24 done by capacity-engine/worker — commit 4077934, test `bash scripts/audit-domains.sh` exit 0 (log: evidence/bt-a740-2026-07-24T00-48-41Z-test.txt)
