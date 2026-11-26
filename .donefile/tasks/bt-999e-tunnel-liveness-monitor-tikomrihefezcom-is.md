---
id: bt-999e
title: "tunnel-liveness monitor: tik.omrihefez.com is UNPINNED, check exits 1"
status: done
priority: p3
tags:
  - from-brief
created: 2026-11-26
filed:
  owner: morning-brief
  at: 2026-11-26T07:07:03Z
done:
  at: 2026-11-26T07:13:05Z
  by: capacity-engine/worker
evidence:
  - type: commit
    value: 494b76f942796f88e2d06758a37ced0e0e14544d
    verified: 2026-11-26T07:13:05Z
  - type: test
    cmd: cd /home/omri/projects/bass-tuner && bash scripts/check-tunnel-liveness.sh
    exit: 0
    at: 2026-11-26T07:13:03Z
    log: evidence/bt-999e-2026-11-26T07-13-03Z-test.txt
    sha256: 268e7601e617cfb88a5ef826961000ef50ed85cb39ea0f4040181b647a454235
    bytes: 480
  - type: note
    value: "Pinned tik / -> 307 (probed live; NextAuth login wall). Before: rc=1 UNPINNED (reproduced at
      start); after: rc=0, 7 hosts. Pin-removal => UNPINNED rc=1 by script's own logic, observed
      before the edit."
---

scripts/check-tunnel-liveness.sh exits 1 because tik.omrihefez.com has no EXPECT_PATH/EXPECT_STATUS entry (see ~/inbox/bass-tuner-tunnel-liveness-2026-11-26.md). Add pins from a real probe of the live host. Done: `bash scripts/check-tunnel-liveness.sh` exits 0; removing the pin makes it exit 1 again.

Filed by the morning brief's intake pass.

## Log
- 2026-11-26 claimed by capacity-engine
- 2026-11-26 done by capacity-engine/worker — commit 494b76f94279, test `cd /home/omri/projects/bass-tuner && bash scripts/check-tunnel-liveness.sh` exit 0 (log: evidence/bt-999e-2026-11-26T07-13-03Z-test.txt)
