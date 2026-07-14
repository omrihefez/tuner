---
id: bt-b898
title: No automated tests for core pitch/note math
status: done
priority: p1
tags:
  - tests
created: 2026-07-14
done:
  at: 2026-07-14T05:53:29Z
  by: capacity-engine/worker
evidence:
  - type: commit
    value: a0234d3
    verified: 2026-07-14T05:53:29Z
  - type: test
    cmd: npm test
    exit: 0
    at: 2026-07-14T05:53:28Z
    log: evidence/bt-b898-2026-07-14T05-53-28Z-test.txt
    sha256: 44e68c1b0e7418674a45ad7a755fbe9077ee49561ef58137de05dc3dc93bdeac
    bytes: 5127
---

tuner.js:76-87 (midiToFreq/freqToMidi/noteLabel), :57-61 (medianPitch), :219-228 (closestString), :263-322 (detectPitchYIN) are pure, deterministic, and safety-critical (wrong Hz = wrong tuning) yet have ZERO tests. No package.json, no test runner, no fixtures. Why wrong: a regression in the note math silently mistunes every user with no guard. Fix: add a minimal test setup (node --test or vitest) with known-answer cases (A4=440 -> 69; E1=28 -> 41.20Hz; noteLabel(28)=E1; closestString and YIN on a synthesized sine).

## Log
- 2026-07-14 claimed by capacity-engine
- 2026-07-14 done by capacity-engine/worker — commit a0234d3, test `npm test` exit 0 (log: evidence/bt-b898-2026-07-14T05-53-28Z-test.txt)
