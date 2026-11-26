---
id: bt-999e
title: "tunnel-liveness monitor: tik.omrihefez.com is UNPINNED, check exits 1"
status: claimed
priority: p3
tags:
  - from-brief
created: 2026-11-26
filed:
  owner: morning-brief
  at: 2026-11-26T07:07:03Z
claim:
  owner: capacity-engine
  at: 2026-11-26T07:10:12Z
---

scripts/check-tunnel-liveness.sh exits 1 because tik.omrihefez.com has no EXPECT_PATH/EXPECT_STATUS entry (see ~/inbox/bass-tuner-tunnel-liveness-2026-11-26.md). Add pins from a real probe of the live host. Done: `bash scripts/check-tunnel-liveness.sh` exits 0; removing the pin makes it exit 1 again.

Filed by the morning brief's intake pass.

## Log
- 2026-11-26 claimed by capacity-engine
