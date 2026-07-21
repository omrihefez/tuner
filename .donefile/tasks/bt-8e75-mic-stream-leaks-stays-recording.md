---
id: bt-8e75
title: Mic stream leaks (stays recording) if AudioContext/analyser setup throws after getUserMedia
status: claimed
priority: p2
tags:
  - correctness
created: 2026-07-14
claim:
  owner: capacity-engine
  at: 2026-07-21T21:41:50Z
---

tuner.js:436-452: inside the getUserMedia .then, state.micStream=stream is set BEFORE new AudioContext()/createMediaStreamSource()/createAnalyser(). If any of those throws (autoplay policy, unsupported constraint, ctx limit), the chained .catch (tuner.js:453) shows a generic 'Mic error' but the live MediaStreamTrack is never stop()ped -> the OS mic/recording indicator stays ON (privacy), and state.audioCtx stays null so the next Start click calls start() again and acquires a SECOND stream (leak compounds). Fix: in the failure path stop all stream tracks and null state.micStream before surfacing the error; consider try/finally around setup.

## Log
- 2026-07-21 claimed by capacity-engine
