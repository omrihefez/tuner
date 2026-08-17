---
id: bt-03ea
title: Vercel wildcard cert will likely expire again in ~90d (~2026-10-23) — DNS lives on Cloudflare
  nameservers, not Vercel's, so Vercel can't auto-place the DNS-01 challenge on renewal, which is
  probably why it silently expired last time. Needs either a recurring reminder to redo `vercel
  certs issue "*.omrihefez.com"` before expiry, or a scripted renewal (CF token + vercel CLI, both
  non-interactive) wired into a cron/donefile task.
status: done
priority: p3
tags:
  - vercel
  - tls
  - ops
created: 2026-07-25
done:
  at: 2026-07-26T19:17:20Z
  by: capacity-engine/worker
evidence:
  - type: commit
    value: 9388db1
    verified: 2026-07-26T19:17:20Z
  - type: test
    cmd: bash scripts/renew-wildcard-cert.sh --force
    exit: 0
    at: 2026-07-26T19:16:56Z
    log: evidence/bt-03ea-2026-07-26T19-16-56Z-test.txt
    sha256: 9316e508505dc8e4c740c03c051c0bfb4a2318b5865d74b4384db5892a9272fb
    bytes: 1787
---

## Log
- 2026-07-26 claimed by capacity-engine
- 2026-07-26 released by capacity-engine
- 2026-07-26 claimed by capacity-engine
- 2026-07-26 released by capacity-engine
- 2026-07-26 claimed by capacity-engine
- 2026-07-26 released by capacity-engine
- 2026-07-26 claimed by capacity-engine
- 2026-07-26 done by capacity-engine/worker — commit 9388db1, test `bash scripts/renew-wildcard-cert.sh --force` exit 0 (log: evidence/bt-03ea-2026-07-26T19-16-56Z-test.txt)
