---
id: bt-1402
title: Convert bt-a892 off the legacy task-file schema so the bass-tuner board audits clean
status: open
priority: p3
tags:
  - hygiene
created: 2026-07-25
---

bt-a892 is the only task file across the fleet still on the pre-schema-change format: it uses a top-level closed key instead of a done block, and evidence is a prose block scalar instead of a list of evidence entries. Verified by grep for a leading closed key across the bass-tuner, vidsmith, tik-api, meniapp, trips-hub and donefile task directories -- only this one file matches. Result is that donefile audit on bass-tuner permanently reports three findings, DEGRADED, NO_EVIDENCE and BAD_TIMESTAMP, which is the entire audit output for the board. The prose evidence names a real shipped feature and a service worker cache bump v7 to v8. DONE WHEN: bt-a892 carries a done block with at and by, a commit evidence entry for the playReferenceTone change, and donefile audit in bass-tuner prints audit clean.
