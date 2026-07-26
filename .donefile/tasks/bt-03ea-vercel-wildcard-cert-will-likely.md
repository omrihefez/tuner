---
id: bt-03ea
title: Vercel wildcard cert will likely expire again in ~90d (~2026-10-23) — DNS lives on Cloudflare
  nameservers, not Vercel's, so Vercel can't auto-place the DNS-01 challenge on renewal, which is
  probably why it silently expired last time. Needs either a recurring reminder to redo `vercel
  certs issue "*.omrihefez.com"` before expiry, or a scripted renewal (CF token + vercel CLI, both
  non-interactive) wired into a cron/donefile task.
status: open
priority: p3
tags:
  - vercel
  - tls
  - ops
created: 2026-07-25
---

## Log
- 2026-07-26 claimed by capacity-engine
- 2026-07-26 released by capacity-engine
- 2026-07-26 claimed by capacity-engine
- 2026-07-26 released by capacity-engine
