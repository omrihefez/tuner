---
id: bt-1402
title: Convert bt-a892 off the legacy task-file schema so the bass-tuner board audits clean
status: done
priority: p3
tags:
  - hygiene
created: 2026-07-25
done:
  at: 2026-07-26T18:50:13Z
  by: capacity-engine/worker
  waived: evidence commit 141b6f9 legitimately declares itself bt-a892 work — it IS the commit that
    migrated bt-a892's task file to the new schema, which is exactly bt-1402's scope; not a
    copy-pasted sha
evidence:
  - type: commit
    value: 141b6f9
    verified: 2026-07-26T18:50:13Z
  - type: test
    cmd: node /home/omri/projects/donefile/dist/cli.js audit
    exit: 0
    at: 2026-07-26T18:50:12Z
    log: evidence/bt-1402-2026-07-26T18-50-12Z-test.txt
    sha256: 75ad201715d7e7134790f3647660a8ab34bb4c1a5cb01a18338a9e69f308f7a1
    bytes: 67
---

bt-a892 is the only task file across the fleet still on the pre-schema-change format: it uses a top-level closed key instead of a done block, and evidence is a prose block scalar instead of a list of evidence entries. Verified by grep for a leading closed key across the bass-tuner, vidsmith, tik-api, meniapp, trips-hub and donefile task directories -- only this one file matches. Result is that donefile audit on bass-tuner permanently reports three findings, DEGRADED, NO_EVIDENCE and BAD_TIMESTAMP, which is the entire audit output for the board. The prose evidence names a real shipped feature and a service worker cache bump v7 to v8. DONE WHEN: bt-a892 carries a done block with at and by, a commit evidence entry for the playReferenceTone change, and donefile audit in bass-tuner prints audit clean.

## Log
- 2026-07-26 claimed by capacity-engine
- 2026-07-26 done by capacity-engine/worker — commit 141b6f9, test `node /home/omri/projects/donefile/dist/cli.js audit` exit 0 (log: evidence/bt-1402-2026-07-26T18-50-12Z-test.txt)
- 2026-07-26 amended by capacity-engine/worker (evidence waived retroactively: evidence commit 141b6f9 legitimately declares itself bt-a892 work — it IS the commit that migrated bt-a892's task file to the new schema, which is exactly bt-1402's scope; not a copy-pasted sha)
