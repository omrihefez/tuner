---
id: bt-8e75
title: Mic stream leaks (stays recording) if AudioContext/analyser setup throws after getUserMedia
status: done
priority: p2
tags:
  - correctness
created: 2026-07-14
done:
  at: 2026-07-21T21:45:27Z
  by: capacity-engine/worker
evidence:
  - type: commit
    value: bfc2056
    verified: 2026-07-21T21:45:27Z
  - type: test
    cmd: npm test
    exit: 0
    at: 2026-07-21T21:45:26Z
    log: evidence/bt-8e75-2026-07-21T21-45-26Z-test.txt
    sha256: 44993ece534494df78a8e963e45d0ed7948fa5832eabee2889a0083e570942db
    bytes: 7468
---

tuner.js:436-452: inside the getUserMedia .then, state.micStream=stream is set BEFORE new AudioContext()/createMediaStreamSource()/createAnalyser(). If any of those throws (autoplay policy, unsupported constraint, ctx limit), the chained .catch (tuner.js:453) shows a generic 'Mic error' but the live MediaStreamTrack is never stop()ped -> the OS mic/recording indicator stays ON (privacy), and state.audioCtx stays null so the next Start click calls start() again and acquires a SECOND stream (leak compounds). Fix: in the failure path stop all stream tracks and null state.micStream before surfacing the error; consider try/finally around setup.

## Log
- 2026-07-21 claimed by capacity-engine
- 2026-07-21 done by capacity-engine/worker — commit bfc2056, test `npm test` exit 0 (log: evidence/bt-8e75-2026-07-21T21-45-26Z-test.txt)
