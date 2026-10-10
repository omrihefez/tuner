---
id: bt-1176
title: audit-domains.sh's security-header baseline doesn't check COOP/CORP — 6 of 9 live Vercel
  hosts now send both
status: open
priority: p3
tags:
  - security
  - http-headers
created: 2026-10-10
filed:
  owner: meni-worker/revisit-kidai-tik-trips--a12a68
  at: 2026-10-10T17:08:11Z
---

ma-24e3's census (2026-10-10 14:33-14:41Z, 9 live Vercel hosts) found 4/9 sending Cross-Origin-Opener-Policy + Cross-Origin-Resource-Policy, deliberately NOT added to REQUIRED_HEADERS at that count per bt-a2c2's own admission test ('what the siblings actually send, not an aspirational list') -- 4/9 doesn't meet it.

Re-measured live 2026-10-10 17:05 UTC after meniapp (ma-24e3) and kidai (kd-a4db) both shipped the fix: bass, compose, meni, preview.meni, meniapp, kidai now send both -- 6/9. kd-a4db's own filing note said the right move at 6-7/9 is one baseline change here instead of N more per-repo tasks. That threshold is now met.

Remaining gap hosts: planner (apl-2094, open), tik (tkn-c2a6, open), trips (th-f5bc, open) -- filing this does not fix those, it only makes their absence show as DRIFT instead of passing silently, same as every other REQUIRED_HEADERS entry.

DONE WHEN: COOP and CORP are added to missing_security_headers()'s checks (same shape as the existing content-security-policy/REQUIRED_HEADERS checks), the three still-missing hosts report DRIFT, and the six already-compliant hosts stay OK -- verified by running audit-domains.sh live.

## Log
- 2026-10-10 claimed by capacity-engine
- 2026-10-10 released by capacity-engine
