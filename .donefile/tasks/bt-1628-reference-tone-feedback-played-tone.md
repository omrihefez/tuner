---
id: bt-1628
title: "Reference-tone feedback: played tone leaks into live mic and jerks the needle"
status: claimed
priority: p3
tags:
  - ux
created: 2026-07-14
claim:
  owner: capacity-engine
  at: 2026-07-23T05:25:13Z
---

tuner.js:127-137 / playReferenceTone (tuner.js:93-110): when the tuner is running (shared state.audioCtx), tapping a locked string plays a 1.2s sine at 0.4 gain through ctx.destination (speakers). The live mic then picks that tone up and the detector locks onto the reference pitch, jerking the needle to the played note instead of the string. Why wrong: confusing readout exactly when the user wants to compare by ear. Fix: pause/ignore detection (or duck) for the ~1.2s the reference tone plays, or gate detection while a tone is active.

## Log
- 2026-07-23 claimed by capacity-engine
