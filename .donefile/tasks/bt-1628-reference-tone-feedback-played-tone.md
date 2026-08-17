---
id: bt-1628
title: "Reference-tone feedback: played tone leaks into live mic and jerks the needle"
status: done
priority: p3
tags:
  - ux
created: 2026-07-14
done:
  at: 2026-07-23T05:29:11Z
  by: capacity-engine/worker
evidence:
  - type: commit
    value: b17cb08
    verified: 2026-07-23T05:29:11Z
  - type: test
    cmd: npm test
    exit: 0
    at: 2026-07-23T05:29:11Z
    log: evidence/bt-1628-2026-07-23T05-29-11Z-test.txt
    sha256: 8f8c82f7d3ee49b2fa7072bd24dfc61b5c4ebcfb46b9c83ca821ddb62f3672fa
    bytes: 10843
---

tuner.js:127-137 / playReferenceTone (tuner.js:93-110): when the tuner is running (shared state.audioCtx), tapping a locked string plays a 1.2s sine at 0.4 gain through ctx.destination (speakers). The live mic then picks that tone up and the detector locks onto the reference pitch, jerking the needle to the played note instead of the string. Why wrong: confusing readout exactly when the user wants to compare by ear. Fix: pause/ignore detection (or duck) for the ~1.2s the reference tone plays, or gate detection while a tone is active.

## Log
- 2026-07-23 claimed by capacity-engine
- 2026-07-23 done by capacity-engine/worker — commit b17cb08, test `npm test` exit 0 (log: evidence/bt-1628-2026-07-23T05-29-11Z-test.txt)
