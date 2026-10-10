---
id: bt-6146
title: "audit-domains.sh: oauth.omrihefez.com/health missing x-frame-options and permissions-policy
  (live DRIFT)"
status: open
priority: p3
tags:
  - security
  - http-headers
  - monitoring
created: 2026-10-10
filed:
  owner: capacity-engine/worker
  at: 2026-10-10T16:22:08Z
---

Discovered while closing bt-820a. Confirmed live and on unmodified origin/main (pre-existing, unrelated to bt-820a's apex-HSTS fix): `DRIFT  oauth.omrihefez.com/health -> 200 missing security headers: x-frame-options,permissions-policy`. Measured 2026-10-10 via scripts/audit-domains.sh run on both the fix branch and a control worktree at origin/main (same commit, 59a954e) — identical finding on both, so it predates and is independent of bt-820a's change.
