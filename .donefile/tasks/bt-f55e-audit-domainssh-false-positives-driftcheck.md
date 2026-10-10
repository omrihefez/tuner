---
id: bt-f55e
title: audit-domains.sh false-positives DRIFT/CHECK on arch-preview.omrihefez.com, retired by ar-1fde
status: claimed
priority: p3
tags:
  - from-brief
  - cross-board
created: 2026-10-10
filed:
  owner: morning-brief
  at: 2026-10-10T08:03:02Z
claim:
  owner: capacity-engine
  at: 2026-10-10T08:07:32Z
---

scripts/audit-domains.sh still treats arch-preview.omrihefez.com as a live passkey-protected host expecting 307 -> /login (SUBS map entry + an ar-3426-dated exemption). meni-arch's ar-1fde (closed 2026-10-09 04:12) intentionally retired this host via `vercel alias rm` -- it now 404s by design, and check-promotion-drift.sh's preview target moved to preview.meni.omrihefez.com. The 2026-10-10 06:10 domain-audit run is the first to show the 404 and flags it as DRIFT, which will refire daily forever. Done when: audit-domains.sh no longer emits a DRIFT/CHECK line for arch-preview.omrihefez.com -- either drop it from the SUBS list (same pattern as the albumclub/apartments teardowns in ~/meni/DOMAIN.md) or add an explicit "retired, expect 404" exemption citing ar-1fde -- and a live run of the script shows no arch-preview line in its output.

Filed by the morning brief's intake pass.

cross-board: names a file under 'meni' at /home/omri/meni — ~/meni is undispatched — route it via ~/inbox/meni-board-queue/ instead (see dn-334c).

## Log
- 2026-10-10 claimed by capacity-engine
