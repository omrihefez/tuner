---
id: bt-4d32
title: tuner.omrihefez.com HSTS header missing includeSubDomains (not covered by cp-8845)
status: open
priority: p3
tags:
  - from-brief
created: 2026-10-04
filed:
  owner: morning-brief
  at: 2026-10-04T06:07:02Z
---

The 2026-10-04 bass-tuner domain audit (~/inbox/bass-tuner-domain-audit-2026-10-04.md) flags tuner.omrihefez.com's Strict-Transport-Security header as missing the includeSubDomains directive. A sibling finding on compose.omrihefez.com is already tracked as cp-8845 (open, p3) — but that task's title claims compose is 'the only one in the estate' with this gap, which is now false since tuner has it too. Add includeSubDomains to tuner's HSTS header (wherever the other domains in the estate set it — check how compose/other sibling apps configure STS for the pattern to match). Done when audit-domains.sh shows no DRIFT line for tuner's STS header, and cp-8845's title/body no longer implies compose is unique (update or close out that claim if cp-8845 covers both now).

Filed by the morning brief's intake pass.
